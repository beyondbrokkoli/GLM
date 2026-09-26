
use crate::ast::StaticType;
use crate::ir::{Instruction, IrProgram, RegId, Terminator};
use crate::shape::LayoutVerdict;
use glm_rt::trace;
use std::collections::HashMap;

fn llvm_type(ty: &StaticType) -> &'static str {
    match ty {
        StaticType::Integer => "i64",
        StaticType::Float => "double",
        StaticType::Boolean => "i1",
        StaticType::String | StaticType::Table(_) => "ptr",
        // Unconstrained Unknown types never have typed access, so i8 is a
        // zero-overhead dummy: the data buffer is never read or written.
        StaticType::Unknown(_) => "i8",
    }
}

fn storage_type(ty: &StaticType) -> &'static str {
    match ty {
        StaticType::Boolean => "i8",
        _ => llvm_type(ty),
    }
}

fn elem_size(ty: &StaticType) -> u32 {
    match ty {
        StaticType::Boolean => 1,
        // Unconstrained Unknown types never have typed access, so 1-byte
        // allocations are a safe zero-overhead default.
        StaticType::Unknown(_) => 1,
        _ => 8,
    }
}

fn llvm_bytes(bytes: &[u8]) -> String {
    let mut out = String::new();
    for &b in bytes {
        match b {
            b'"' => out.push_str("\\22"),
            b'\\' => out.push_str("\\5C"),
            0x20..=0x7E => out.push(b as char),
            _ => out.push_str(&format!("\\{b:02X}")),
        }
    }
    out
}

pub fn generate_llvm_ir(program: &IrProgram) -> Result<String, Vec<String>> {
    let mut globals = String::new();
    let mut str_idx = 0;
    let mut needs_floor_decl = false;
    let mut needs_tbl_new_decl = false;
    let mut needs_tbl_reserve_decl = false;
    let mut needs_tbl_free_decl = false;
    let mut needs_tbl_get_decl = false;
    let mut needs_tbl_set_decl = false;
    let mut needs_tbl_len_decl = false;
    let mut needs_sys_alloc_count_decl = false;
    let mut needs_hdr_md = false;
    let mut ts = 0usize;
    let tail: Vec<String> = {
        let mut probe = 0usize;
        let mut tails: Vec<String> = program
            .blocks
            .iter()
            .map(|b| format!("b{}", b.id))
            .collect();
        for block in &program.blocks {
            let mut last = None;
            for instr in &block.instrs {
                match instr {
                    Instruction::TableSetFast { .. } => {
                        last = Some(probe);
                        probe += 1;
                    }
                    Instruction::TableGet { .. }
                    | Instruction::TableLen { .. }
                    | Instruction::TableSet { .. } => probe += 1,
                    _ => {}
                }
            }
            if let Some(k) = last {
                tails[block.id] = format!("bts{}cont", k);
            }
        }
        tails
    };
    let mut reg_types: HashMap<RegId, StaticType> = HashMap::new();

    let mut allocas = String::new();
    let mut code = String::new();

    for block in &program.blocks {
        code.push_str(&format!("\nb{}:\n", block.id));

        for instr in &block.instrs {
            if let Some(ty) = instr.def_type()
                && let Some(target) = instr.def_reg()
                && !matches!(
                    instr,
                    Instruction::Add { .. }
                        | Instruction::Sub { .. }
                        | Instruction::Mul { .. }
                        | Instruction::Div { .. }
                        | Instruction::IntDiv { .. }
                        | Instruction::Mod { .. }
                        | Instruction::Neg { .. }
                )
            {
                reg_types.insert(target, ty);
            }

            match instr {
                Instruction::LoadInt { target, val } => {
                    code.push_str(&format!("  %v{} = add i64 0, {}\n", target, val))
                }
                Instruction::LoadFloat { target, val } => {
                    code.push_str(&format!("  %v{} = fadd double 0.0, {:?}\n", target, val))
                }
                Instruction::LoadBool { target, val } => code.push_str(&format!(
                    "  %v{} = or i1 0, {}\n",
                    target,
                    if *val { 1 } else { 0 }
                )),
                Instruction::LoadString { target, val } => {
                    let g = format!("@.str.{}", str_idx);
                    str_idx += 1;
                    globals.push_str(&format!(
                        "{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"\n",
                        g,
                        val.len() + 1,
                        llvm_bytes(val.as_bytes())
                    ));
                    code.push_str(&format!(
                        "  %v{} = getelementptr inbounds [{} x i8], ptr {}, i64 0, i64 0\n",
                        target,
                        val.len() + 1,
                        g
                    ));
                }
                Instruction::Move { target, source, ty } => match ty {
                    StaticType::Integer => {
                        code.push_str(&format!("  %v{} = add i64 %v{}, 0\n", target, source))
                    }
                    StaticType::Float => {
                        code.push_str(&format!("  %v{} = fadd double %v{}, 0.0\n", target, source))
                    }
                    StaticType::Boolean => {
                        code.push_str(&format!("  %v{} = or i1 %v{}, 0\n", target, source))
                    }
                    StaticType::String | StaticType::Table(_) => code.push_str(&format!(
                        "  %v{} = getelementptr i8, ptr %v{}, i64 0\n",
                        target, source
                    )),
                    // Unconstrained Unknown types: 1-byte dummy, move with byte-clear.
                    StaticType::Unknown(_) => code.push_str(&format!(
                        "  %v{} = or i8 %v{}, 0\n", target, source
                    )),
                },
                Instruction::LoadNull { target } => {
                    code.push_str(&format!("  %v{} = inttoptr i64 0 to ptr\n", target));
                }
                
                Instruction::TableNew { target, elem, flags } => {
                    trace::compiler_trace_set(trace::TRACE_OFFLOAD_EMIT);

                    needs_tbl_new_decl = true;
                    needs_hdr_md = true;
                    reg_types.insert(*target, StaticType::Table(Box::new(elem.clone())));

                    // flags: bit 0 = mode (0=Dense, 1=Sparse), bit 7 = contains_tables
                    code.push_str(&format!(
                        "  %v{} = call ptr @glm_tbl_new(i64 {}, i8 {})\n",
                        target,
                        elem_size(elem),
                        flags
                    ));
                }
                Instruction::TableGet { target, table, index, target_ty } => {
                    let elem = match reg_types.get(table) {
                        Some(StaticType::Table(elem)) => (**elem).clone(),
                        _ => return Err(vec!["Internal Compiler Error: backend tracks every table reg's type".to_string()]),
                    };
                    // Store the element type in reg_types so Print dispatches correctly.
                    reg_types.insert(*target, target_ty.clone());
                    needs_tbl_get_decl = true;
                    let ety = storage_type(&elem);
                    let f = ts;
                    ts += 1;

                    allocas.push_str(&format!("  %ts{f}.dst = alloca {ety}\n", f = f, ety = ety));

                    code.push_str(&format!(
                        "  call void @glm_tbl_get(ptr %v{table}, i64 %v{index}, ptr %ts{f}.dst)\n",
                        f = f, table = table, index = index
                    ));

                    if matches!(elem, StaticType::Boolean) {
                        code.push_str(&format!(
                            "  %ts{f}.c = load i8, ptr %ts{f}.dst\n\
                               %v{target} = icmp ne i8 %ts{f}.c, 0\n",
                            f = f, target = target
                        ));
                    } else {
                        // Every element loads in its native width. There is no
                        // cross-type cast here on purpose: tables are strictly
                        // monomorphic, so the element type decides the width.
                        code.push_str(&format!(
                            "  %v{target} = load {ety}, ptr %ts{f}.dst\n",
                            target = target, ety = ety, f = f
                        ));
                    }
                }
                Instruction::TableReserve { table, bound } => {
                    needs_tbl_reserve_decl = true;
                    code.push_str(&format!(
                        "  call void @glm_tbl_reserve(ptr %v{}, i64 %v{})\n",
                        table, bound
                    ));
                }

                Instruction::TableSetFast { table, index, value, layout } => {
                    let elem = match reg_types.get(table) {
                        Some(StaticType::Table(elem)) => (**elem).clone(),
                        _ => return Err(vec!["Internal Compiler Error: backend tracks every table reg's type".to_string()]),
                    };
                    needs_hdr_md = true;
                    let ety = storage_type(&elem);
                    let f = ts;
                    ts += 1;

                    // Pre-generate the counter-embedded cast variable names to avoid
                    // nested format argument issues where {f} would be literal text.
                    let cast_var = format!("%ts{}.c", f);

                    // Bool cells are byte-packed: zext the i1 before the store.
                    // Every other element stores in its native width — the old
                    // i64-slot cast family (bitcast double, zext i1, ptrtoint ptr)
                    // existed only to pack mixed types into record slots and is
                    // gone with records: strict typing rejects any value/element
                    // disagreement in the checker, so a non-integer register in
                    // an i64 cell can only mean an invariant breach — the
                    // confusion signal is the tripwire, never a silent reinterpret.
                    let val_cast = if matches!(elem, StaticType::Boolean) {
                        format!("  {cv} = zext i1 %v{value} to i8\n", cv = cast_var, value = value)
                    } else {
                        if elem == StaticType::Integer
                            && !matches!(reg_types.get(value), Some(StaticType::Integer))
                        {
                            trace::compiler_trace_set(trace::TRACE_FAIL_TYPE_CONFUSION);
                        }
                        String::new()
                    };
                    let val_use = if matches!(elem, StaticType::Boolean) {
                        cast_var
                    } else {
                        format!("%v{value}")
                    };

                    allocas.push_str(&format!("  %ts{f}.valp = alloca {ety}\n", f = f, ety = ety));

                    match layout {
                        LayoutVerdict::Dense => {
                            code.push_str(&format!(
                                "{val_cast}\
                                   %ts{f}.d = load ptr, ptr %v{table}, !alias.scope !0\n\
                                   %ts{f}.s = getelementptr inbounds {ety}, ptr %ts{f}.d, i64 %v{index}\n\
                                   store {ety} {val_use}, ptr %ts{f}.s, !noalias !0\n\
                                   br label %bts{f}cont\n\n\
                                 bts{f}cont:\n",
                                val_cast = val_cast, f = f, table = table, index = index, ety = ety, val_use = val_use
                            ));
                        },
                        LayoutVerdict::Sparse => {
                            needs_tbl_set_decl = true;
                            code.push_str(&format!(
                                "{val_cast}\
                                   store {ety} {val_use}, ptr %ts{f}.valp\n\
                                   call void @glm_tbl_set(ptr %v{table}, i64 %v{index}, ptr %ts{f}.valp)\n\
                                   br label %bts{f}cont\n\n\
                                 bts{f}cont:\n",
                                val_cast = val_cast, f = f, table = table, index = index, ety = ety, val_use = val_use
                            ));
                        },
                        _ => {
                            needs_tbl_set_decl = true;
                            code.push_str(&format!(
                                "{val_cast}\
                                   %ts{f}.modep = getelementptr inbounds i8, ptr %v{table}, i64 32\n\
                                   %ts{f}.mode = load i8, ptr %ts{f}.modep, !alias.scope !0\n\
                                   %ts{f}.is_dense = icmp eq i8 %ts{f}.mode, 0\n\
                                   br i1 %ts{f}.is_dense, label %bts{f}dense, label %bts{f}sparse\n\n\
                                 bts{f}dense:\n\
                                   %ts{f}.d = load ptr, ptr %v{table}, !alias.scope !0\n\
                                   %ts{f}.s = getelementptr inbounds {ety}, ptr %ts{f}.d, i64 %v{index}\n\
                                   store {ety} {val_use}, ptr %ts{f}.s, !noalias !0\n\
                                   br label %bts{f}cont\n\n\
                                 bts{f}sparse:\n\
                                   store {ety} {val_use}, ptr %ts{f}.valp\n\
                                   call void @glm_tbl_set(ptr %v{table}, i64 %v{index}, ptr %ts{f}.valp)\n\
                                   br label %bts{f}cont\n\n\
                                 bts{f}cont:\n",
                                val_cast = val_cast, f = f, table = table, index = index, ety = ety, val_use = val_use
                            ));
                        }
                    }
                }
                Instruction::TableSet { table, index, value } => {
                    let elem = match reg_types.get(table) {
                        Some(StaticType::Table(elem)) => (**elem).clone(),
                        _ => return Err(vec!["Internal Compiler Error: backend tracks every table reg's type".to_string()]),
                    };
                    needs_tbl_set_decl = true;
                    let ety = storage_type(&elem);
                    let f = ts;
                    ts += 1;

                    allocas.push_str(&format!("  %ts{f}.valp = alloca {ety}\n", f = f, ety = ety));

                    if matches!(elem, StaticType::Boolean) {
                        // Byte-packed bool cells: zext the i1 value to i8.
                        code.push_str(&format!(
                            "  %ts{f}.z = zext i1 %v{value} to i8\n\
                               store i8 %ts{f}.z, ptr %ts{f}.valp\n",
                            f = f, value = value
                        ));
                    } else {
                        // Native-width store, no casts: the record-era family
                        // that packed double/ptr/i1 values into i64 slots is
                        // gone — strict typing keeps every register's width
                        // equal to its cell width, and this branch pokes the
                        // confusion signal rather than reinterpreting bits if
                        // that invariant is ever breached.
                        if elem == StaticType::Integer
                            && !matches!(reg_types.get(value), Some(StaticType::Integer))
                        {
                            trace::compiler_trace_set(trace::TRACE_FAIL_TYPE_CONFUSION);
                        }
                        code.push_str(&format!(
                            "  store {ety} %v{value}, ptr %ts{f}.valp\n",
                            ety = ety, value = value, f = f
                        ));
                    }
                    code.push_str(&format!(
                        "  call void @glm_tbl_set(ptr %v{table}, i64 %v{index}, ptr %ts{f}.valp)\n",
                        table = table, index = index, f = f
                    ));
                }
                Instruction::TableLen { target, table } => {
                    needs_tbl_len_decl = true;
                    code.push_str(&format!(
                        "  %v{} = call i64 @glm_tbl_len(ptr %v{})\n",
                        target, table
                    ));
                    ts += 1;
                }
                Instruction::TableFree { table } => {
                    trace::compiler_trace_set(trace::TRACE_OFFLOAD_EMIT);

                    needs_tbl_free_decl = true;
                    code.push_str(&format!("  call void @glm_tbl_free(ptr %v{})\n", table));
                }
                Instruction::SysAllocCount { target } => {
                    needs_sys_alloc_count_decl = true;
                    code.push_str(&format!(
                        "  %v{} = call i64 @sys_alloc_count()\n",
                        target
                    ));
                }
                Instruction::Add { target, left, right } => math_op(target, left, right, "add", "fadd", &mut code, &mut reg_types),
                Instruction::Sub { target, left, right } => math_op(target, left, right, "sub", "fsub", &mut code, &mut reg_types),
                Instruction::Mul { target, left, right } => math_op(target, left, right, "mul", "fmul", &mut code, &mut reg_types),
                Instruction::Div { target, left, right } => math_op(target, left, right, "sdiv", "fdiv", &mut code, &mut reg_types),
                Instruction::IntDiv { target, left, right } => floor_div_op(target, left, right, &mut code, &mut reg_types, &mut needs_floor_decl),
                Instruction::Mod { target, left, right } => mod_op(target, left, right, &mut code, &mut reg_types),
                Instruction::Neg { target, source } => {
                    let is_f = matches!(reg_types.get(source), Some(StaticType::Float));
                    reg_types.insert(
                        *target,
                        if is_f { StaticType::Float } else { StaticType::Integer },
                    );
                    if is_f {
                        code.push_str(&format!("  %v{} = fsub double 0.0, %v{}\n", target, source));
                    } else {
                        code.push_str(&format!("  %v{} = sub i64 0, %v{}\n", target, source));
                    }
                }
                Instruction::Less { target, left, right } => cmp_op(target, left, right, "slt", "olt", &mut code, &mut reg_types),
                Instruction::Leq { target, left, right } => cmp_op(target, left, right, "sle", "ole", &mut code, &mut reg_types),
                Instruction::Geq { target, left, right } => cmp_op(target, left, right, "sge", "oge", &mut code, &mut reg_types),
                Instruction::Eq { target, left, right } => cmp_op(target, left, right, "eq", "oeq", &mut code, &mut reg_types),
                Instruction::Not { target, source } => {
                    reg_types.insert(*target, StaticType::Boolean);
                    code.push_str(&format!("  %v{} = xor i1 %v{}, 1\n", target, source));
                }
                Instruction::Phi { target, ty, args } => {
                    let pairs: Vec<String> = args
                        .iter()
                        .map(|(b, r)| format!("[ %v{}, %{} ]", r, tail[*b]))
                        .collect();
                    code.push_str(&format!(
                        "  %v{} = phi {} {}\n",
                        target, llvm_type(ty), pairs.join(", ")
                    ));
                }
                Instruction::Print { operands } => {
                    for (i, (r, ty)) in operands.iter().enumerate() {
                        if i > 0 {
                            code.push_str("  call void @glm_print_sep()\n");
                        }
                        let (r, ty) = (*r, ty);
                        match ty {
                            StaticType::Integer => code.push_str(&format!("  call void @glm_print_int(i64 %v{})\n", r)),
                            StaticType::Float => code.push_str(&format!("  call void @glm_print_float(double %v{})\n", r)),
                            StaticType::Boolean => code.push_str(&format!("  call void @glm_print_bool(i1 %v{})\n", r)),
                            StaticType::String => code.push_str(&format!("  call void @glm_print_string(ptr %v{})\n", r)),
                            StaticType::Table(_) => return Err(vec!["Type Error: tables cannot be printed".to_string()]),
                            // Unconstrained Unknown types: print 0 as a 1-byte dummy.
                            StaticType::Unknown(_) => code.push_str("  call void @glm_print_int(i64 0)\n"),
                        }
                    }
                    code.push_str("  call void @glm_print_nl()\n");
                }
            }
        }

        match &block.terminator {
            Some(Terminator::Jump(b)) => code.push_str(&format!("  br label %b{}\n", b)),
            Some(Terminator::Branch { cond, true_block, false_block }) => {
                code.push_str(&format!("  br i1 %v{}, label %b{}, label %b{}\n", cond, true_block, false_block))
            }
            Some(Terminator::Halt) | None => code.push_str("  ret i32 0\n"),
        }
    }

    let mut out = String::from(
        "declare void @glm_print_int(i64)\n\
         declare void @glm_print_float(double)\n\
         declare void @glm_print_bool(i1)\n\
         declare void @glm_print_string(ptr)\n\
         declare void @glm_print_sep()\n\
         declare void @glm_print_nl()\n\n\
         define i32 @main() {\nentry:\n",
    );
    out.push_str(&allocas);
    out.push_str("  br label %b0\n");
    out.push_str(&code);
    out.push_str("}\n");
    
    let mut head = String::new();
    if needs_floor_decl { head.push_str("declare double @llvm.floor.f64(double)\n"); }
    // === PACKED FLAGS: glm_tbl_new now takes only 2 args (i64, i8) ===
    if needs_tbl_new_decl { head.push_str("declare ptr @glm_tbl_new(i64, i8)\n"); }
    if needs_tbl_reserve_decl { head.push_str("declare void @glm_tbl_reserve(ptr, i64)\n"); }
    if needs_tbl_free_decl { head.push_str("declare void @glm_tbl_free(ptr)\n"); }
    if needs_tbl_get_decl { head.push_str("declare void @glm_tbl_get(ptr, i64, ptr)\n"); }
    if needs_tbl_set_decl { head.push_str("declare void @glm_tbl_set(ptr, i64, ptr)\n"); }
    if needs_tbl_len_decl { head.push_str("declare i64 @glm_tbl_len(ptr)\n"); }
    if needs_sys_alloc_count_decl { head.push_str("declare i64 @sys_alloc_count()\n"); }
    
    let md = if needs_hdr_md {
        "\n!0 = !{!1}\n\
         !1 = distinct !{!\"glm_table_header\", !2}\n\
         !2 = distinct !{!\"glm_table\"}\n"
            .to_string()
    } else {
        String::new()
    };
    Ok(format!("{}{}{}{}", globals, head, out, md))
}

fn math_op(target: &RegId, left: &RegId, right: &RegId, int_op: &str, flt_op: &str, code: &mut String, reg_types: &mut HashMap<RegId, StaticType>) {
    let is_f = matches!(reg_types.get(left), Some(StaticType::Float));
    reg_types.insert(*target, if is_f { StaticType::Float } else { StaticType::Integer });
    if is_f {
        code.push_str(&format!("  %v{} = {} double %v{}, %v{}\n", target, flt_op, left, right));
    } else {
        code.push_str(&format!("  %v{} = {} i64 %v{}, %v{}\n", target, int_op, left, right));
    }
}

fn floor_div_op(target: &RegId, left: &RegId, right: &RegId, code: &mut String, reg_types: &mut HashMap<RegId, StaticType>, needs_floor_decl: &mut bool) {
    let is_f = matches!(reg_types.get(left), Some(StaticType::Float));
    reg_types.insert(*target, if is_f { StaticType::Float } else { StaticType::Integer });
    if is_f {
        *needs_floor_decl = true;
        code.push_str(&format!("  %t{}.0 = fdiv double %v{}, %v{}\n", target, left, right));
        code.push_str(&format!("  %v{} = call double @llvm.floor.f64(double %t{}.0)\n", target, target));
    } else {
        code.push_str(&format!("  %t{}.0 = sdiv i64 %v{}, %v{}\n", target, left, right));
        code.push_str(&format!("  %t{}.1 = srem i64 %v{}, %v{}\n", target, left, right));
        code.push_str(&format!("  %t{}.2 = icmp ne i64 %t{}.1, 0\n", target, target));
        code.push_str(&format!("  %t{}.3 = xor i64 %v{}, %v{}\n", target, left, right));
        code.push_str(&format!("  %t{}.4 = icmp slt i64 %t{}.3, 0\n", target, target));
        code.push_str(&format!("  %t{}.5 = and i1 %t{}.2, %t{}.4\n", target, target, target));
        code.push_str(&format!("  %t{}.6 = sub i64 %t{}.0, 1\n", target, target));
        code.push_str(&format!("  %v{} = select i1 %t{}.5, i64 %t{}.6, i64 %t{}.0\n", target, target, target, target));
    }
}

fn mod_op(target: &RegId, left: &RegId, right: &RegId, code: &mut String, reg_types: &mut HashMap<RegId, StaticType>) {
    let is_f = matches!(reg_types.get(left), Some(StaticType::Float));
    reg_types.insert(*target, if is_f { StaticType::Float } else { StaticType::Integer });
    if is_f {
        code.push_str(&format!("  %t{}.0 = frem double %v{}, %v{}\n", target, left, right));
        code.push_str(&format!("  %t{}.1 = fcmp ogt double %t{}.0, 0.0\n", target, target));
        code.push_str(&format!("  %t{}.2 = fcmp olt double %v{}, 0.0\n", target, right));
        code.push_str(&format!("  %t{}.3 = and i1 %t{}.1, %t{}.2\n", target, target, target));
        code.push_str(&format!("  %t{}.4 = fcmp olt double %t{}.0, 0.0\n", target, target));
        code.push_str(&format!("  %t{}.5 = fcmp ogt double %v{}, 0.0\n", target, right));
        code.push_str(&format!("  %t{}.6 = and i1 %t{}.4, %t{}.5\n", target, target, target));
        code.push_str(&format!("  %t{}.7 = or i1 %t{}.3, %t{}.6\n", target, target, target));
        code.push_str(&format!("  %t{}.8 = fadd double %t{}.0, %v{}\n", target, target, right));
        code.push_str(&format!("  %v{} = select i1 %t{}.7, double %t{}.8, double %t{}.0\n", target, target, target, target));
    } else {
        code.push_str(&format!("  %t{}.0 = srem i64 %v{}, %v{}\n", target, left, right));
        code.push_str(&format!("  %t{}.1 = icmp ne i64 %t{}.0, 0\n", target, target));
        code.push_str(&format!("  %t{}.2 = xor i64 %t{}.0, %v{}\n", target, target, right));
        code.push_str(&format!("  %t{}.3 = icmp slt i64 %t{}.2, 0\n", target, target));
        code.push_str(&format!("  %t{}.4 = and i1 %t{}.1, %t{}.3\n", target, target, target));
        code.push_str(&format!("  %t{}.5 = add i64 %t{}.0, %v{}\n", target, target, right));
        code.push_str(&format!("  %v{} = select i1 %t{}.4, i64 %t{}.5, i64 %t{}.0\n", target, target, target, target));
    }
}

fn cmp_op(target: &RegId, left: &RegId, right: &RegId, int_cond: &str, flt_cond: &str, code: &mut String, reg_types: &mut HashMap<RegId, StaticType>) {
    reg_types.insert(*target, StaticType::Boolean);
    match reg_types.get(left) {
        Some(StaticType::Float) => code.push_str(&format!("  %v{} = fcmp {} double %v{}, %v{}\n", target, flt_cond, left, right)),
        Some(StaticType::Boolean) => code.push_str(&format!("  %v{} = icmp {} i1 %v{}, %v{}\n", target, int_cond, left, right)),
        Some(StaticType::Table(_)) | Some(StaticType::String) => code.push_str(&format!("  %v{} = icmp {} ptr %v{}, %v{}\n", target, int_cond, left, right)),
        _ => code.push_str(&format!("  %v{} = icmp {} i64 %v{}, %v{}\n", target, int_cond, left, right)),
    }
}
