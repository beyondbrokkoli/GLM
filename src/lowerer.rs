// AST -> SSA IR lowering. The fill-loop conversion (EC/HR) and its

use crate::ast::{BinOp, Expr, StaticType, Stmt, UnOp};
use crate::ir::{BasicBlock, BlockId, Instruction, IrProgram, RegId, Terminator};
use crate::shape::{LayoutVerdict, ShapeFacts};
use std::collections::{BTreeSet, HashMap};

#[derive(Clone)]
struct Local {
    reg: RegId,
    ty: StaticType,
    layout: LayoutVerdict,
}

struct LoopCtx {
    guard_reg: RegId,
    reserved: Vec<RegId>,
    nested_fills: Vec<(String, RegId)>,
}

pub struct IrLowerer<'a> {
    pub blocks: Vec<BasicBlock>,
    current_block: BlockId,
    free_reg: RegId,
    scopes: Vec<HashMap<String, Local>>,
    loop_ctxs: Vec<LoopCtx>,
    shape: &'a ShapeFacts,
}

impl<'a> IrLowerer<'a> {
    pub fn new(shape: &'a ShapeFacts) -> Self {
        Self {
            blocks: vec![BasicBlock::new(0)],
            current_block: 0,
            free_reg: 0,
            scopes: vec![HashMap::new()],
            loop_ctxs: Vec::new(),
            shape,
        }
    }

    fn new_block(&mut self) -> BlockId {
        let id = self.blocks.len();
        self.blocks.push(BasicBlock::new(id));
        id
    }

    fn next_reg(&mut self) -> RegId {
        let r = self.free_reg;
        self.free_reg += 1;
        r
    }

    fn emit(&mut self, instr: Instruction) {
        self.blocks[self.current_block].instrs.push(instr);
    }

    fn terminate(&mut self, term: Terminator) {
        self.blocks[self.current_block].terminator = Some(term);
    }

    fn declare_var(&mut self, name: String, reg: RegId, ty: StaticType, layout: LayoutVerdict) {
        self.scopes
            .last_mut()
            .unwrap()
            .insert(name, Local { reg, ty, layout });
    }

    fn update_var(&mut self, name: &str, reg: RegId, ty: StaticType, layout: LayoutVerdict) {
        for scope in self.scopes.iter_mut().rev() {
            if let Some(local) = scope.get_mut(name) {
                local.reg = reg;
                local.ty = ty;
                local.layout = layout;
                return;
            }
        }
        panic!("Lowerer: Undeclared variable");
    }

    fn read_var(&self, name: &str) -> Local {
        for scope in self.scopes.iter().rev() {
            if let Some(local) = scope.get(name) {
                return local.clone();
            }
        }
        panic!("Lowerer: Undeclared variable");
    }

    fn has_var(&self, name: &str) -> bool {
        for scope in self.scopes.iter().rev() {
            if scope.contains_key(name) {
                return true;
            }
        }
        false
    }

    pub fn lower_program(mut self, stmts: &[Stmt]) -> IrProgram {
        for stmt in stmts {
            self.lower_stmt(stmt);
        }
        if self.blocks[self.current_block].terminator.is_none() {
            self.terminate(Terminator::Halt);
        }
        IrProgram {
            blocks: self.blocks,
        }
    }

    fn lower_stmt(&mut self, stmt: &Stmt) {
        match stmt {
            Stmt::LocalDecl { names, exprs } => {
                let mut bindings = Vec::with_capacity(exprs.len());
                for expr in exprs {
                    let target_reg = self.next_reg();
                    let (_, ty) = self.lower_expr(expr, Some(target_reg));
                    let layout = self.lookup_layout_for(expr);
                    bindings.push((target_reg, ty, layout));
                }
                for (name, (reg, ty, layout)) in names.iter().zip(bindings) {
                    self.declare_var(name.clone(), reg, ty, layout);
                }
            }
            Stmt::Assignment { name, expr } => {
                if matches!(expr, Expr::Nil) {
                    let local = self.read_var(name);
                    if self.shape.is_free(stmt) {
                        self.emit(Instruction::TableFree { table: local.reg });
                    }
                    let null_reg = self.next_reg();
                    self.emit(Instruction::LoadNull { target: null_reg });
                    self.update_var(name, null_reg, local.ty.clone(), local.layout);
                    return;
                }
                let new_reg = self.next_reg();
                let (actual_reg, ty) = self.lower_expr(expr, Some(new_reg));
                let layout = self.lookup_layout_for(expr);
                self.update_var(name, actual_reg, ty, layout);
            }
            Stmt::IndexAssign { obj, key, value } => {
                let (t_reg, _) = self.lower_expr(obj, None);
                let (i_reg, _) = self.lower_expr(key, None);

                let base_name = get_base_identifier(obj);

                // [Register Identity Fix] Dynamically authorize temporary nested-table registers.
                // The old check only matched identifiers already in ctx.reserved.
                // For t[i][j] = v, `t[i]` evaluates into a temporary RegId from TableGet,
                // so we expand reserved on first match.
                let mut fast = false;
                for ctx in self.loop_ctxs.iter_mut().rev() {
                    if ctx.guard_reg == i_reg {
                        if ctx.reserved.contains(&t_reg) {
                            fast = true;
                            break;
                        } else if let Some(name) = base_name
                            && ctx.nested_fills.iter().any(|(n, _)| n == name) {
                            ctx.reserved.push(t_reg);
                            fast = true;
                            break;
                        }
                    }
                }

                let (v_reg, _) = self.lower_expr(value, None);

                if fast {
                    // Safe layout lookup — falls back recursively for Expr::Index
                    let layout = self.lookup_layout_for(obj);
                    self.emit(Instruction::TableSetFast {
                        table: t_reg,
                        index: i_reg,
                        value: v_reg,
                        layout,
                    });
                } else {
                    self.emit(Instruction::TableSet {
                        table: t_reg,
                        index: i_reg,
                        value: v_reg,
                    });
                }

                // [Nested Reserve Activation]
                // If the assigned value is an inline table and the base matrix is
                // marked for nested fills, pre-allocate the child row spine.
                if matches!(value, Expr::TableCtor(_))
                    && let Some(name) = base_name {
                    let bound_reg = self.loop_ctxs.iter().rev().find_map(|ctx| {
                        ctx.nested_fills
                            .iter()
                            .find(|(n, _)| n == name)
                            .map(|(_, b_reg)| *b_reg)
                    });

                    if let Some(b_reg) = bound_reg {
                        self.emit(Instruction::TableReserve {
                            table: v_reg, // Pre-allocate the newly minted inner row
                            bound: b_reg,
                        });
                    }
                }
            }
            Stmt::While { condition, body } => {
                let pre_header = self.current_block;

                let header_block = self.new_block();
                let body_block = self.new_block();
                let exit_block = self.new_block();

                let mutated_vars = find_mutated_vars(body);

                let mut phi_order: Vec<(String, Local)> = mutated_vars
                    .iter()
                    .filter(|name| self.has_var(name))
                    .map(|name| {
                        let local = self.read_var(name);
                        (name.clone(), local)
                    })
                    .collect();
                phi_order.sort_by(|(name_a, a), (name_b, b)| (a.reg, name_a).cmp(&(b.reg, name_b)));

                let conv: Option<(String, Vec<String>, BTreeSet<String>)> = match condition {
                    Expr::BinaryOp {
                        op: BinOp::LessThan,
                        left,
                        right: bound_expr,
                    } if as_ident(left).is_some() => {
                        let guard = as_ident(left).expect("guarded by as_ident");
                        let stable = !free_idents(bound_expr)
                            .iter()
                            .any(|v| mutated_vars.contains(v));
                        let mut fills: BTreeSet<String> = BTreeSet::new();
                        let mut nested_fills: BTreeSet<String> = BTreeSet::new();
                        if stable {
                            collect_fill_stores(body, guard, &mutated_vars, &mut fills, &mut nested_fills);
                        }
                        // Both direct fills (t[j] = v) and nested fills (t[i][j] = v) qualify.
                        // Nested fills use the register-identity fix in IndexAssign to activate
                        // the fast path for the temporary table registers.
                        if fills.is_empty() && nested_fills.is_empty() {
                            None
                        } else {
                            let depth = self.scopes.len();
                            let mut names = Vec::new();
                            for name in &fills {
                                if !self.has_var(name) {
                                    continue;
                                }
                                if self.shape.is_dense_at_depth(name, depth) {
                                    names.push(name.clone());
                                }
                            }
                            (!names.is_empty() || !nested_fills.is_empty())
                                .then_some((guard.to_string(), names, nested_fills))
                        }
                    }
                    _ => None,
                };
                let conv_bound: Option<&Expr> = match condition {
                    Expr::BinaryOp {
                        op: BinOp::LessThan,
                        right: bound_expr,
                        ..
                    } if conv.is_some() => Some(bound_expr),
                    _ => None,
                };
                let mut conv_bound_reg: Option<RegId> = None;
                if let (Some((_, names, _)), Some(bound_expr)) = (&conv, conv_bound) {
                    let saved_scopes = self.scopes.clone();
                    let (b_reg, _) = self.lower_expr(bound_expr, None);
                    self.scopes = saved_scopes;
                    conv_bound_reg = Some(b_reg);
                    for name in names {
                        let t_reg = self.read_var(name).reg;
                        self.emit(Instruction::TableReserve {
                            table: t_reg,
                            bound: b_reg,
                        });
                    }
                }

                let mut phis = Vec::new();

                self.terminate(Terminator::Jump(header_block));
                self.current_block = header_block;

                for (var, pre_loop_local) in phi_order {
                    let phi_reg = self.next_reg();
                    self.emit(Instruction::Phi {
                        target: phi_reg,
                        ty: pre_loop_local.ty.clone(),
                        args: vec![(pre_header, pre_loop_local.reg)],
                    });
                    self.update_var(&var, phi_reg, pre_loop_local.ty.clone(), pre_loop_local.layout);
                    phis.push((var, phi_reg));
                }

                let cond_reg = if let (Some((guard, _, _)), Some(b_reg)) = (&conv, conv_bound_reg) {
                    let g_reg = self.read_var(guard).reg;
                    let c_reg = self.next_reg();
                    self.emit(Instruction::Less {
                        target: c_reg,
                        left: g_reg,
                        right: b_reg,
                    });
                    c_reg
                } else {
                    self.lower_expr(condition, None).0
                };
                self.terminate(Terminator::Branch {
                    cond: cond_reg,
                    true_block: body_block,
                    false_block: exit_block,
                });

                if let Some((guard, names, nested_fills)) = &conv {
                    let guard_reg = self.read_var(guard).reg;
                    let reserved = names.iter().map(|name| self.read_var(name).reg).collect();

                    // --- Nested Table Reserve for Multidimensional Matrices ---
                    // For a 2D fill like `t[i][j] = 0`, detect tables whose
                    // element type is itself a table.  Pre-allocate the outer spine
                    // (row count) before the loop starts.
                    let mut nested_fill_regs: Vec<(String, RegId)> = Vec::new();
                    for name in names {
                        let local = self.read_var(name);
                        if let StaticType::Table(inner_ty) = &local.ty
                            && matches!(**inner_ty, StaticType::Table(_)) {
                            // Pre-allocate the outer spine of rows.
                            self.emit(Instruction::TableReserve {
                                table: local.reg,
                                bound: conv_bound_reg.unwrap(),
                            });
                            // Register as nested fill target for the IndexAssign path.
                            nested_fill_regs.push((name.clone(), conv_bound_reg.unwrap()));
                        }
                    }
                    // Also process tables detected as nested fills (e.g., t[i][j] = val).
                    // These are in nested_fills rather than names because obj was Expr::Index.
                    for name in nested_fills {
                        if self.has_var(name) {
                            let local = self.read_var(name);
                            if let StaticType::Table(inner_ty) = &local.ty
                                && matches!(**inner_ty, StaticType::Table(_)) {
                                self.emit(Instruction::TableReserve {
                                    table: local.reg,
                                    bound: conv_bound_reg.unwrap(),
                                });
                                nested_fill_regs.push((name.clone(), conv_bound_reg.unwrap()));
                            }
                        }
                    }

                    self.loop_ctxs.push(LoopCtx {
                        guard_reg,
                        reserved,
                        nested_fills: nested_fill_regs,
                    });
                }

                self.current_block = body_block;
                self.scopes.push(HashMap::new());
                for s in body {
                    self.lower_stmt(s);
                }
                self.scopes.pop();
                if conv.is_some() {
                    self.loop_ctxs.pop();
                }

                let end_of_body = self.current_block;
                self.terminate(Terminator::Jump(header_block));

                for (var, phi_reg) in &phis {
                    let back_edge_local = self.read_var(var);
                    for instr in &mut self.blocks[header_block].instrs {
                        if let Instruction::Phi { target, args, .. } = instr
                            && *target == *phi_reg
                        {
                            args.push((end_of_body, back_edge_local.reg));
                            break;
                        }
                    }
                }

                for (var, phi_reg) in &phis {
                    let local = self.read_var(var);
                    self.update_var(var, *phi_reg, local.ty.clone(), local.layout);
                }

                self.current_block = exit_block;
            }
            Stmt::Do { body } => {
                let outer_keys: BTreeSet<String> =
                    self.scopes.iter().flat_map(|s| s.keys().cloned()).collect();

                self.scopes.push(HashMap::new());

                for s in body {
                    self.lower_stmt(s);
                }

                if let Some(block_local) = self.scopes.last_mut() {
                    let locals: Vec<(String, RegId)> = block_local
                        .iter()
                        .filter(|(_, local)| matches!(local.ty, StaticType::Table(_)))
                        .filter(|(name, _)| !outer_keys.contains(*name))
                        .map(|(name, local)| (name.clone(), local.reg))
                        .collect();
                    for (_, reg) in locals.into_iter().rev() {
                        self.emit(Instruction::TableFree { table: reg });
                    }
                }

                self.scopes.pop();
            }
            Stmt::Print { exprs } => {
                let mut operands = Vec::new();
                for e in exprs {
                    let (r, ty) = self.lower_expr(e, None);
                    operands.push((r, ty));
                }
                self.emit(Instruction::Print { operands });
            }
            Stmt::If {
                condition,
                then_body,
                else_body,
            } => {
                let (cond_reg, _) = self.lower_expr(condition, None);

                let then_block = self.new_block();
                let else_block = self.new_block();
                let join_block = self.new_block();

                self.terminate(Terminator::Branch {
                    cond: cond_reg,
                    true_block: then_block,
                    false_block: else_block,
                });

                let mut mutated = find_mutated_vars(then_body);
                mutated.extend(find_mutated_vars(else_body));
                let mutated: Vec<String> = mutated
                    .into_iter()
                    .filter(|name| self.has_var(name))
                    .collect();

                let mut phi_order: Vec<(String, RegId)> = mutated
                    .into_iter()
                    .map(|name| {
                        let local = self.read_var(&name);
                        (name, local.reg)
                    })
                    .collect();
                phi_order.sort_by(|(name_a, a), (name_b, b)| (a, name_a).cmp(&(b, name_b)));

                let snapshot = self.scopes.clone();

                self.current_block = then_block;
                self.scopes.push(HashMap::new());
                for s in then_body {
                    self.lower_stmt(s);
                }
                self.scopes.pop();
                let then_end = self.current_block;
                let then_regs: Vec<(String, RegId)> = phi_order
                    .iter()
                    .map(|(name, _)| (name.clone(), self.read_var(name).reg))
                    .collect();
                self.terminate(Terminator::Jump(join_block));

                self.scopes = snapshot;
                self.current_block = else_block;
                self.scopes.push(HashMap::new());
                for s in else_body {
                    self.lower_stmt(s);
                }
                self.scopes.pop();
                let else_end = self.current_block;
                let else_regs: Vec<(String, RegId)> = phi_order
                    .iter()
                    .map(|(name, _)| (name.clone(), self.read_var(name).reg))
                    .collect();
                self.terminate(Terminator::Jump(join_block));

                self.current_block = join_block;
                for (i, (name, _)) in phi_order.iter().enumerate() {
                    let phi_reg = self.next_reg();
                    let local = self.read_var(name);
                    self.emit(Instruction::Phi {
                        target: phi_reg,
                        ty: local.ty.clone(),
                        args: vec![(then_end, then_regs[i].1), (else_end, else_regs[i].1)],
                    });
                    self.update_var(name, phi_reg, local.ty.clone(), local.layout);
                }
            }
        }
    }

    fn lookup_layout_for(&self, expr: &Expr) -> LayoutVerdict {
        match expr {
            Expr::TableCtor(_) => {
                if let Some(&site_id) = self.shape.sites.get(&(expr as *const Expr)) {
                    self.shape.layouts[site_id]
                } else {
                    LayoutVerdict::default()
                }
            }
            Expr::Identifier(name) => {
                self.read_var(name).layout
            }
            // Fall back recursively for multi-dimensional arrays like t[i]
            Expr::Index { obj, .. } => self.lookup_layout_for(obj),
            _ => LayoutVerdict::default(),
        }
    }

    fn lower_expr(&mut self, expr: &Expr, target: Option<RegId>) -> (RegId, StaticType) {
        let reg = target.unwrap_or_else(|| self.next_reg());

        match expr {
            Expr::Integer(val) => {
                self.emit(Instruction::LoadInt {
                    target: reg,
                    val: *val,
                });
                (reg, StaticType::Integer)
            }
            Expr::Float(val) => {
                self.emit(Instruction::LoadFloat {
                    target: reg,
                    val: *val,
                });
                (reg, StaticType::Float)
            }
            Expr::Boolean(val) => {
                self.emit(Instruction::LoadBool {
                    target: reg,
                    val: *val,
                });
                (reg, StaticType::Boolean)
            }
            Expr::String(val) => {
                self.emit(Instruction::LoadString {
                    target: reg,
                    val: val.clone(),
                });
                (reg, StaticType::String)
            }
            Expr::Nil => {
                unreachable!("nil outside a table release")
            }
            Expr::SysAllocCount => {
                let target = self.next_reg();
                self.emit(Instruction::SysAllocCount { target });
                (target, StaticType::Integer)
            }
            Expr::RecordCtor(fields) => {
                // Records compile to the same LLVM table representation as arrays.
                // The distinction is purely at the shape/typing level.
                let record_ty = self.shape.elem_of(expr);

                // [Variable Capture: Deep-Free Ownership]
                let mut has_inline_tables = false;
                for (_, val) in fields {
                    if matches!(val, Expr::TableCtor(_)) {
                        has_inline_tables = true;
                    }
                }

                // Check if element type is a table for contains_tables flag
                let is_table_elem = match &record_ty {
                    StaticType::Record(rec_fields) => {
                        rec_fields.iter().any(|(_, ty)| matches!(ty, StaticType::Table(_)))
                    }
                    _ => false,
                };
                let contains_tables = is_table_elem && has_inline_tables;

                let mut elem_regs = Vec::with_capacity(fields.len());
                for (_, val) in fields {
                    let (r, _) = self.lower_expr(val, None);
                    elem_regs.push(r);
                }

                // Force all records to i64 slots: all GLM types fit in 8 bytes,
                // so we use integer buffers and LLVM bitcasting for mixed types.
                let elem_for_header = StaticType::Table(Box::new(StaticType::Integer));

                let mode_bit = match self.lookup_layout_for(expr) {
                    crate::shape::LayoutVerdict::Sparse => 0x01,
                    _ => 0x00,
                };
                let flags = mode_bit | if contains_tables { 0x80 } else { 0x00 };

                self.emit(Instruction::TableNew {
                    target: reg,
                    elem: elem_for_header,
                    flags,
                    is_record: true,
                });
                for (i, v_reg) in elem_regs.into_iter().enumerate() {
                    let i_reg = self.next_reg();
                    self.emit(Instruction::LoadInt {
                        target: i_reg,
                        val: i as i64,
                    });
                    self.emit(Instruction::TableSet {
                        table: reg,
                        index: i_reg,
                        value: v_reg,
                    });
                }
                // Return the record type for scope tracking
                (reg, record_ty)
            }
            Expr::TableCtor(elems) => {
                let elem = self.shape.elem_of(expr);

                // [Variable Capture: Deep-Free Ownership]
                // Track whether any element is an *inline anonymous constructor*.
                // If a table captures named identifiers (e.g. `local inner = {};
                // local outer = {inner}`), `lower_expr` resolves the identifier to
                // its existing SSA register — that variable manages its own lifetime
                // via block-scoping. Setting contains_tables (bit 0x80) on the outer
                // table would cause `glm_tbl_free` to deep-free the child, which
                // conflicts with the child's natural block-scope cleanup → double-
                // free.  Only *inline* constructors (`{{1,2}}`) require the parent
                // to own the child's deep-free.
                let mut has_inline_tables = false;
                for e in elems {
                    if matches!(e, Expr::TableCtor(_)) {
                        has_inline_tables = true;
                    }
                }

                // Only flag for deep-free if elements are inline anonymous tables.
                let contains_tables = matches!(elem, crate::ast::StaticType::Table(_))
                    && has_inline_tables;

                let mut elem_regs = Vec::with_capacity(elems.len());
                for e in elems {
                    // If `e` is an Identifier, `lower_expr` natively fetches its
                    // existing SSA register — no re-allocation, no ownership leak.
                    let (r, _) = self.lower_expr(e, None);
                    elem_regs.push(r);
                }

                let mode_bit = match self.lookup_layout_for(expr) {
                    crate::shape::LayoutVerdict::Sparse => 0x01,
                    _ => 0x00,
                };
                let flags = mode_bit | if contains_tables { 0x80 } else { 0x00 };

                self.emit(Instruction::TableNew {
                    target: reg,
                    // [TypeSystem: Decoupling]
                    // Clone StaticType so the IR owns an independent copy of the element type,
                    // freeing the backend from tying IR lifetimes to the AST.
                    elem: elem.clone(),
                    // Packed flags: bit 0 = mode (0=Dense, 1=Sparse), bit 7 = contains_tables.
                    flags,
                    is_record: false,
                });
                for (i, v_reg) in elem_regs.into_iter().enumerate() {
                    let i_reg = self.next_reg();
                    self.emit(Instruction::LoadInt {
                        target: i_reg,
                        val: i as i64,
                    });
                    self.emit(Instruction::TableSet {
                        table: reg,
                        index: i_reg,
                        value: v_reg,
                    });
                }
                (reg, StaticType::Table(Box::new(elem)))
            }
            Expr::Index { obj, key } => {
                let (t_reg, t_ty) = self.lower_expr(obj, None);
                let (i_reg, _) = self.lower_expr(key, None);
                // Check if key is a constant integer literal for field index lookup.
                let field_index = if let Expr::Integer(n) = key.as_ref() {
                    Some(*n)
                } else {
                    None
                };
                // Determine the actual field type for the target register.
                let target_ty = match t_ty {
                    StaticType::Table(elem) => (*elem).clone(),
                    StaticType::Record(fields) => {
                        if let Some(n) = field_index {
                            fields.get(n as usize).map(|(_, ty)| ty.clone())
                        } else {
                            None
                        }.unwrap_or(StaticType::Integer)
                    }
                    _ => unreachable!("checker guarantees a table operand"),
                };
                self.emit(Instruction::TableGet {
                    target: reg,
                    table: t_reg,
                    index: i_reg,
                    target_ty: target_ty.clone(),
                });
                (reg, target_ty)
            }
            Expr::Identifier(name) => {
                let local = self.read_var(name);
                if target.is_some() && reg != local.reg {
                    self.emit(Instruction::Move {
                        target: reg,
                        source: local.reg,
                        ty: local.ty.clone(),
                    });
                } else {
                    return (local.reg, local.ty);
                }
                (reg, local.ty)
            }
            Expr::BinaryOp {
                op: op @ (BinOp::And | BinOp::Or),
                left,
                right,
            } => {
                let (l_reg, _) = self.lower_expr(left, None);
                let then_block = self.new_block();
                let else_block = self.new_block();
                let join_block = self.new_block();
                self.terminate(Terminator::Branch {
                    cond: l_reg,
                    true_block: then_block,
                    false_block: else_block,
                });
                let and_op = matches!(op, BinOp::And);
                let (value_block, const_block, short_val) = if and_op {
                    (then_block, else_block, false)
                } else {
                    (else_block, then_block, true)
                };

                self.current_block = value_block;
                let (v_reg, _) = self.lower_expr(right, None);
                let value_end = self.current_block;
                self.terminate(Terminator::Jump(join_block));

                self.current_block = const_block;
                let c_reg = self.next_reg();
                self.emit(Instruction::LoadBool {
                    target: c_reg,
                    val: short_val,
                });
                let const_end = const_block;
                self.terminate(Terminator::Jump(join_block));

                self.current_block = join_block;
                let (t_end, t_reg, e_end, e_reg) = if and_op {
                    (value_end, v_reg, const_end, c_reg)
                } else {
                    (const_end, c_reg, value_end, v_reg)
                };
                self.emit(Instruction::Phi {
                    target: reg,
                    ty: StaticType::Boolean,
                    args: vec![(t_end, t_reg), (e_end, e_reg)],
                });
                (reg, StaticType::Boolean)
            }
            Expr::BinaryOp { op, left, right } => {
                let (l_reg, l_ty) = self.lower_expr(left, None);
                let (r_reg, r_ty) = self.lower_expr(right, None);
                match op {
                    BinOp::Add => self.emit(Instruction::Add {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::Sub => self.emit(Instruction::Sub {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::Mul => self.emit(Instruction::Mul {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::Div => self.emit(Instruction::Div {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::IntDiv => self.emit(Instruction::IntDiv {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::Mod => self.emit(Instruction::Mod {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::LessThan => self.emit(Instruction::Less {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::GreaterThan => self.emit(Instruction::Less {
                        target: reg,
                        left: r_reg,
                        right: l_reg,
                    }),
                    BinOp::LessEq => self.emit(Instruction::Leq {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::GreaterEq => self.emit(Instruction::Geq {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::Equal => self.emit(Instruction::Eq {
                        target: reg,
                        left: l_reg,
                        right: r_reg,
                    }),
                    BinOp::NotEqual => {
                        let e = self.next_reg();
                        self.emit(Instruction::Eq {
                            target: e,
                            left: l_reg,
                            right: r_reg,
                        });
                        self.emit(Instruction::Not {
                            target: reg,
                            source: e,
                        });
                    }
                    BinOp::And | BinOp::Or => unreachable!(),
                }
                let ty = match op {
                    BinOp::LessThan
                    | BinOp::GreaterThan
                    | BinOp::LessEq
                    | BinOp::GreaterEq
                    | BinOp::Equal
                    | BinOp::NotEqual => StaticType::Boolean,
                    _ => {
                        if matches!(l_ty, StaticType::Float) || matches!(r_ty, StaticType::Float) {
                            StaticType::Float
                        } else {
                            StaticType::Integer
                        }
                    }
                };
                (reg, ty)
            }
            Expr::UnaryOp { op, expr } => {
                let (x_reg, x_ty) = self.lower_expr(expr, None);
                match op {
                    UnOp::Neg => {
                        self.emit(Instruction::Neg {
                            target: reg,
                            source: x_reg,
                        });
                        (reg, x_ty)
                    }
                    UnOp::Not => {
                        self.emit(Instruction::Not {
                            target: reg,
                            source: x_reg,
                        });
                        (reg, StaticType::Boolean)
                    }
                    UnOp::Len => {
                        self.emit(Instruction::TableLen {
                            target: reg,
                            table: x_reg,
                        });
                        (reg, StaticType::Integer)
                    }
                }
            }
        }
    }
}

fn find_mutated_vars(stmts: &[Stmt]) -> BTreeSet<String> {
    let mut mutated = BTreeSet::new();
    for stmt in stmts {
        match stmt {
            Stmt::Assignment { name, .. } => {
                mutated.insert(name.clone());
            }
            Stmt::While { body, .. } => {
                mutated.extend(find_mutated_vars(body));
            }
            Stmt::Do { body } => {
                mutated.extend(find_mutated_vars(body));
            }
            Stmt::If {
                then_body,
                else_body,
                ..
            } => {
                mutated.extend(find_mutated_vars(then_body));
                mutated.extend(find_mutated_vars(else_body));
            }
            _ => {}
        }
    }
    mutated
}

fn as_ident(expr: &Expr) -> Option<&str> {
    match expr {
        Expr::Identifier(name) => Some(name),
        _ => None,
    }
}

fn get_base_identifier(expr: &Expr) -> Option<&String> {
    match expr {
        Expr::Identifier(name) => Some(name),
        Expr::Index { obj, .. } => get_base_identifier(obj),
        _ => None,
    }
}

fn free_idents(expr: &Expr) -> BTreeSet<String> {
    fn go(e: &Expr, out: &mut BTreeSet<String>) {
        match e {
            Expr::Identifier(name) => {
                out.insert(name.clone());
            }
            Expr::BinaryOp { left, right, .. } => {
                go(left, out);
                go(right, out);
            }
            Expr::UnaryOp { expr, .. } => go(expr, out),
            Expr::Index { obj, key } => {
                go(obj, out);
                go(key, out);
            }
            _ => {}
        }
    }
    let mut out = BTreeSet::new();
    go(expr, &mut out);
    out
}

fn collect_fill_stores(
    stmts: &[Stmt],
    guard: &str,
    mutated: &BTreeSet<String>,
    fills: &mut BTreeSet<String>,
    nested_fills: &mut BTreeSet<String>,
) {
    for stmt in stmts {
        if let Stmt::IndexAssign { obj, key: Expr::Identifier(key_ident), .. } = stmt {
            // Does the key match the loop guard?
            if key_ident != guard {
                continue;
            }

            let root_name = match get_base_identifier(obj) {
                Some(name) if !mutated.contains(name) => name,
                _ => continue,
            };

            // Distinguish direct fills (root == obj) from nested fills (root ≠ obj).
            // `t[j]=v` → obj is `t`, root is `t` → direct fill.
            // `t[i][j]=v` → obj is `t[i]`, root is `t` → nested fill.
            match obj {
                Expr::Identifier(name) if name == root_name => {
                    fills.insert(root_name.clone());
                }
                Expr::Index { .. } => {
                    nested_fills.insert(root_name.clone());
                }
                _ => {}
            }
        }

        // Recurse into nested statement blocks.
        match stmt {
            Stmt::While { body, .. } => {
                collect_fill_stores(body, guard, mutated, fills, nested_fills)
            }
            Stmt::Do { body } => {
                collect_fill_stores(body, guard, mutated, fills, nested_fills)
            }
            Stmt::If {
                then_body,
                else_body,
                ..
            } => {
                collect_fill_stores(then_body, guard, mutated, fills, nested_fills);
                collect_fill_stores(else_body, guard, mutated, fills, nested_fills);
            }
            _ => {}
        }
    }
}
