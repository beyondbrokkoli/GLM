// AST -> SSA IR lowering. The fill-loop conversion (EC/HR) and its

use crate::ast::{BinOp, Expr, StaticType, Stmt, UnOp};
use crate::ir::{BasicBlock, BlockId, Instruction, IrProgram, RegId, Terminator};
use crate::shape::{LayoutVerdict, ShapeFacts};
use glm_rt::{signal, trace};
use std::collections::{BTreeMap, BTreeSet};

/// A localized lowering failure: one user-facing message, created at the
/// detection site and ledgered at `lower_program`. Ghost run contract —
/// never a panic.
pub struct LowerError(pub String);

/// The type a join phi carries when its arms disagree. A heap type
/// (Table) beats the bare-local Integer placeholder: the phi holds the
/// header or null on the arms, and ptr storage covers both — an
/// Integer-typed phi over ptr inputs is invalid IR (clang rejects
/// "'%v' defined with type 'ptr' but expected 'i64'"). Checker
/// unification rejects every other disagreement before lowering, so
/// the final fallback is unreachable in practice.
fn join_phi_ty(a: &StaticType, b: &StaticType) -> StaticType {
    if a == b {
        return a.clone();
    }
    let heap = |t: &StaticType| matches!(t, StaticType::Table(_));
    // Heap wins over the bare-local placeholder; any other disagreement
    // the checker already rejected, so the backedge type is the answer.
    if heap(a) { a.clone() } else { b.clone() }
}

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
    /// Ghost-run ledger: one entry per localized failure. The driver
    /// reports these and fails the build instead of aborting mid-compile.
    pub diagnostics: Vec<String>,
    current_block: BlockId,
    free_reg: RegId,
    scopes: Vec<BTreeMap<String, Local>>,
    loop_ctxs: Vec<LoopCtx>,
    shape: &'a ShapeFacts,
    /// Birth register of every heap site: the TableNew result and the
    /// control-nesting depth at which it was emitted. The header never
    /// moves (alias invariant), so a dominating TableNew register holds
    /// its site's header on every path — the one sound free handle.
    site_regs: BTreeMap<usize, (RegId, u32)>,
    /// Current non-linear control depth: 0 in straight-line code, one
    /// per enclosing if-arm / while-body / and-or value block. A ctor
    /// emitted at the same depth as a later do-exit dominates that
    /// exit; deeper ctors are conditional and only reach the exit
    /// through a join phi.
    ctrl_depth: u32,
}

impl<'a> IrLowerer<'a> {
    pub fn new(shape: &'a ShapeFacts) -> Self {
        Self {
            blocks: vec![BasicBlock::new(0)],
            diagnostics: Vec::new(),
            current_block: 0,
            free_reg: 0,
            scopes: vec![BTreeMap::new()],
            loop_ctxs: Vec::new(),
            shape,
            site_regs: BTreeMap::new(),
            ctrl_depth: 0,
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

    fn update_var(
        &mut self,
        name: &str,
        reg: RegId,
        ty: StaticType,
        layout: LayoutVerdict,
    ) -> Result<(), LowerError> {
        for scope in self.scopes.iter_mut().rev() {
            if let Some(local) = scope.get_mut(name) {
                local.reg = reg;
                local.ty = ty;
                local.layout = layout;
                return Ok(());
            }
        }
        Err(LowerError("Lower Error: Undeclared variable".into()))
    }

    fn read_var(&self, name: &str) -> Result<Local, LowerError> {
        for scope in self.scopes.iter().rev() {
            if let Some(local) = scope.get(name) {
                return Ok(local.clone());
            }
        }
        Err(LowerError("Lower Error: Undeclared variable".into()))
    }

    fn has_var(&self, name: &str) -> bool {
        for scope in self.scopes.iter().rev() {
            if scope.contains_key(name) {
                return true;
            }
        }
        false
    }

    pub fn lower_program(&mut self, stmts: &[Stmt]) -> IrProgram {
        // Lowerer pokes tag the root scope, same convention as the
        // GHOST_BAIL_LOWERER bracket below: the analyzer's scope
        // register is not this pass's to use, and root (not 0xFF)
        // keeps the do-exit emission signals visible in the scope
        // histogram.
        glm_rt::trace::compiler_trace_current_scope(
            0,
            0,
            glm_rt::trace::TRACE_SCOPE_PARENT_NONE,
        );
        for stmt in stmts {
            match self.lower_stmt(stmt) {
                Ok(_) => {}
                Err(e) => {
                    self.diagnostics.push(e.0);
                    // Ghost run: bail the rest of the file on the first
                    // lowering error — a poisoned block leaves half-built
                    // SSA (dangling jumps, missing phis), so siblings cannot
                    // resume. lower_program is the file's root block, so the
                    // bail is scope-tagged (scope 0, depth 0, no parent)
                    // exactly like the parser's GHOST_BAIL_PARSER.
                    glm_rt::trace::compiler_trace_current_scope(
                        0,
                        0,
                        glm_rt::trace::TRACE_SCOPE_PARENT_NONE,
                    );
                    glm_rt::trace::compiler_trace_signal(
                        glm_rt::trace::TRACE_GHOST_BAIL_LOWERER,
                    );
                    break;
                }
            }
        }
        if self.blocks[self.current_block].terminator.is_none() {
            self.terminate(Terminator::Halt);
        }
        IrProgram {
            blocks: std::mem::take(&mut self.blocks),
        }
    }

    fn lower_stmt(&mut self, stmt: &Stmt) -> Result<(), LowerError> {
        match stmt {
            Stmt::LocalDecl { names, exprs } => {
                let mut bindings = Vec::with_capacity(exprs.len());
                for expr in exprs {
                    let target_reg = self.next_reg();
                    let (_, ty) = self.lower_expr(expr, Some(target_reg))?;
                    let layout = self.lookup_layout_for(expr)?;
                    bindings.push((target_reg, ty, layout));
                }
                // `local x` without initializer: declare the name over a
                // null register — the shape layer models it as a nil-valued
                // binding and the checker as the bare-local Unknown, so the
                // zip above must not drop it. The first assignment
                // overwrites the register exactly like `x = nil` does.
                while bindings.len() < names.len() {
                    let null_reg = self.next_reg();
                    self.emit(Instruction::LoadNull { target: null_reg });
                    bindings.push((null_reg, StaticType::Integer, LayoutVerdict::default()));
                }
                for (name, (reg, ty, layout)) in names.iter().zip(bindings) {
                    self.declare_var(name.clone(), reg, ty, layout);
                }
            }
            Stmt::Assignment { name, expr } => {
                if matches!(expr, Expr::Nil) {
                    let local = self.read_var(name)?;
                    if self.shape.is_free(stmt) {
                        self.emit(Instruction::TableFree { table: local.reg });
                    }
                    let null_reg = self.next_reg();
                    self.emit(Instruction::LoadNull { target: null_reg });
                    self.update_var(name, null_reg, local.ty.clone(), local.layout)?;
                    return Ok(());
                }
                let new_reg = self.next_reg();
                let (actual_reg, ty) = self.lower_expr(expr, Some(new_reg))?;
                let layout = self.lookup_layout_for(expr)?;
                self.update_var(name, actual_reg, ty, layout)?;
            }
            Stmt::IndexAssign { obj, key, value } => {
                let (t_reg, _) = self.lower_expr(obj, None)?;
                let (i_reg, _) = self.lower_expr(key, None)?;

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

                let (v_reg, _) = self.lower_expr(value, None)?;

                if fast {
                    // Safe layout lookup — falls back recursively for Expr::Index
                    let layout = self.lookup_layout_for(obj)?;
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
                        let local = self.read_var(name)?;
                        Ok((name.clone(), local))
                    })
                    .collect::<Result<Vec<_>, LowerError>>()?;
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
                    let (b_reg, _) = self.lower_expr(bound_expr, None)?;
                    self.scopes = saved_scopes;
                    conv_bound_reg = Some(b_reg);
                    for name in names {
                        let t_reg = self.read_var(name)?.reg;
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
                    self.update_var(&var, phi_reg, pre_loop_local.ty.clone(), pre_loop_local.layout)?;
                    phis.push((var, phi_reg));
                }

                let cond_reg = if let (Some((guard, _, _)), Some(b_reg)) = (&conv, conv_bound_reg) {
                    let g_reg = self.read_var(guard)?.reg;
                    let c_reg = self.next_reg();
                    self.emit(Instruction::Less {
                        target: c_reg,
                        left: g_reg,
                        right: b_reg,
                    });
                    c_reg
                } else {
                    self.lower_expr(condition, None)?.0
                };
                self.terminate(Terminator::Branch {
                    cond: cond_reg,
                    true_block: body_block,
                    false_block: exit_block,
                });

                if let Some((guard, names, nested_fills)) = &conv {
                    let guard_reg = self.read_var(guard)?.reg;
                    let reserved = names
                        .iter()
                        .map(|name| Ok(self.read_var(name)?.reg))
                        .collect::<Result<Vec<_>, LowerError>>()?;

                    // --- Nested Table Reserve for Multidimensional Matrices ---
                    // For a 2D fill like `t[i][j] = 0`, detect tables whose
                    // element type is itself a table.  Pre-allocate the outer spine
                    // (row count) before the loop starts.
                    let mut nested_fill_regs: Vec<(String, RegId)> = Vec::new();
                    for name in names {
                        let local = self.read_var(name)?;
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
                            let local = self.read_var(name)?;
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
                self.scopes.push(BTreeMap::new());
                self.ctrl_depth += 1;
                for s in body {
                    self.lower_stmt(s)?;
                }
                self.ctrl_depth -= 1;
                self.scopes.pop();
                if conv.is_some() {
                    self.loop_ctxs.pop();
                }

                let end_of_body = self.current_block;
                self.terminate(Terminator::Jump(header_block));

                for (var, phi_reg) in &phis {
                    let back_edge_local = self.read_var(var)?;
                    for instr in &mut self.blocks[header_block].instrs {
                        if let Instruction::Phi { target, ty, args } = instr
                            && *target == *phi_reg
                        {
                            args.push((end_of_body, back_edge_local.reg));
                            // The phi was emitted with the pre-loop type
                            // before the body existed; a body that first
                            // binds the var to a table (bare local) must
                            // retypes the phi or it carries i64 over ptr
                            // inputs — invalid IR.
                            *ty = join_phi_ty(ty, &back_edge_local.ty);
                            break;
                        }
                    }
                }

                for (var, phi_reg) in &phis {
                    let local = self.read_var(var)?;
                    self.update_var(var, *phi_reg, local.ty.clone(), local.layout)?;
                }

                self.current_block = exit_block;
            }
            Stmt::Do { body } => {
                self.scopes.push(BTreeMap::new());

                for s in body {
                    self.lower_stmt(s)?;
                }

                // [Ownership at scope exit] The analyzer owns the proof
                // (shape::decide_do_exit): one DoExitFree per heap site
                // proved solely owned by this block. Emission stays here
                // and is per SITE, never per name — a dying name whose
                // binding is an if-join over several sites is ONE runtime
                // register, and freeing it once per site freed the join
                // phi's header twice (the do_exit_alias_join_double_free
                // residual). Register choice per site:
                //   - ctor dominating the exit (ctrl depth equal): free
                //     the TableNew birth register — the header never
                //     moves, so it holds this site's header on every
                //     path, whichever way the joins resolved;
                //   - conditional ctor (if-arm / loop body): free the
                //     carrier name's join register — it holds the header
                //     or null, both free-safe — unless it may alias a
                //     register already freed at this exit, in which case
                //     the site leaks on some path (bounded, loud on the
                //     plate) instead of double-freeing.
                let frees = self
                    .shape
                    .do_exit_frees
                    .get(&(stmt as *const Stmt))
                    .cloned()
                    .unwrap_or_default();

                // Defining registers first: they are unconditionally
                // sound and anchor the alias-hazard set the phi pass
                // checks against.
                let mut freed_roots: BTreeSet<RegId> = BTreeSet::new();
                let mut free_regs: Vec<RegId> = Vec::new();
                for f in &frees {
                    let Some(&(reg, depth)) = self.site_regs.get(&f.site) else {
                        continue;
                    };
                    if depth == self.ctrl_depth {
                        signal!(trace::TRACE_DO_EXIT_FREE_DEFREG);
                        freed_roots.insert(reg);
                        free_regs.push(reg);
                    }
                }
                for f in &frees {
                    if self
                        .site_regs
                        .get(&f.site)
                        .is_some_and(|&(_, depth)| depth == self.ctrl_depth)
                    {
                        continue; // already freed through its birth register
                    }
                    let carrier_reg = self.read_var(&f.carrier)?.reg;
                    let roots = self.alias_roots(carrier_reg);
                    if roots.iter().any(|r| freed_roots.contains(r)) {
                        // The join register may hold a header another
                        // free at this exit already covers — freeing it
                        // would double-free on some path. Leak the site
                        // instead; DO_EXIT_JOIN_LEAK is the tripwire.
                        signal!(trace::TRACE_DO_EXIT_JOIN_LEAK);
                        continue;
                    }
                    signal!(trace::TRACE_DO_EXIT_FREE_PHI);
                    freed_roots.extend(roots);
                    free_regs.push(carrier_reg);
                }

                // [Determinism] sort by register id so the block-exit
                // frees emit in reverse construction order (LIFO) and
                // codegen stays byte-identical.
                free_regs.sort_unstable_by_key(|reg| *reg);
                free_regs.dedup();
                for reg in free_regs.into_iter().rev() {
                    self.emit(Instruction::TableFree { table: reg });
                }

                self.scopes.pop();
            }

            Stmt::Print { exprs } => {
                let mut operands = Vec::new();
                for e in exprs {
                    let (r, ty) = self.lower_expr(e, None)?;
                    operands.push((r, ty));
                }
                self.emit(Instruction::Print { operands });
            }
            Stmt::If {
                condition,
                then_body,
                else_body,
            } => {
                let (cond_reg, _) = self.lower_expr(condition, None)?;

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
                        let local = self.read_var(&name)?;
                        Ok((name, local.reg))
                    })
                    .collect::<Result<Vec<_>, LowerError>>()?;
                phi_order.sort_by(|(name_a, a), (name_b, b)| (a, name_a).cmp(&(b, name_b)));

                let snapshot = self.scopes.clone();

                self.current_block = then_block;
                self.scopes.push(BTreeMap::new());
                self.ctrl_depth += 1;
                for s in then_body {
                    self.lower_stmt(s)?;
                }
                self.ctrl_depth -= 1;
                self.scopes.pop();
                let then_end = self.current_block;
                // Arm-exit state captured BEFORE the snapshot restore:
                // types included, so the join phi can carry the arms'
                // joined type instead of the stale pre-if one (a bare
                // local first assigned a table inside an arm).
                let then_regs: Vec<(String, RegId, StaticType)> = phi_order
                    .iter()
                    .map(|(name, _)| {
                        let local = self.read_var(name)?;
                        Ok((name.clone(), local.reg, local.ty))
                    })
                    .collect::<Result<Vec<_>, LowerError>>()?;
                self.terminate(Terminator::Jump(join_block));

                self.scopes = snapshot;
                self.current_block = else_block;
                self.scopes.push(BTreeMap::new());
                self.ctrl_depth += 1;
                for s in else_body {
                    self.lower_stmt(s)?;
                }
                self.ctrl_depth -= 1;
                self.scopes.pop();
                let else_end = self.current_block;
                let else_regs: Vec<(String, RegId, StaticType)> = phi_order
                    .iter()
                    .map(|(name, _)| {
                        let local = self.read_var(name)?;
                        Ok((name.clone(), local.reg, local.ty))
                    })
                    .collect::<Result<Vec<_>, LowerError>>()?;
                self.terminate(Terminator::Jump(join_block));

                self.current_block = join_block;
                for (i, (name, _)) in phi_order.iter().enumerate() {
                    let phi_reg = self.next_reg();
                    let local = self.read_var(name)?;
                    let ty = join_phi_ty(&then_regs[i].2, &else_regs[i].2);
                    self.emit(Instruction::Phi {
                        target: phi_reg,
                        ty: ty.clone(),
                        args: vec![(then_end, then_regs[i].1), (else_end, else_regs[i].1)],
                    });
                    self.update_var(name, phi_reg, ty, local.layout)?;
                }
            }
        }
        Ok(())
    }

    fn lookup_layout_for(&self, expr: &Expr) -> Result<LayoutVerdict, LowerError> {
        match expr {
            Expr::TableCtor(_) => {
                if let Some(&site_id) = self.shape.sites.get(&(expr as *const Expr)) {
                    Ok(self.shape.layouts[site_id])
                } else {
                    Ok(LayoutVerdict::default())
                }
            }
            Expr::Identifier(name) => {
                Ok(self.read_var(name)?.layout)
            }
            // Fall back recursively for multi-dimensional arrays like t[i]
            Expr::Index { obj, .. } => self.lookup_layout_for(obj),
            _ => Ok(LayoutVerdict::default()),
        }
    }

    /// The defining instruction of `reg`, if any (linear scan — scripts
    /// are small and this runs only at do-exits).
    fn def_of(&self, reg: RegId) -> Option<&Instruction> {
        self.blocks
            .iter()
            .find_map(|b| b.instrs.iter().find(|i| i.def_reg() == Some(reg)))
    }

    /// The set of birth registers whose runtime value `reg` may hold:
    /// a Move collapses to its source (table moves are identity GEP-0
    /// aliases of the same header), a Phi expands to its inputs.
    /// Terminal registers (TableNew results, LoadNull, loads) are their
    /// own roots. This is the alias truth the do-exit hazard check
    /// needs: two registers with intersecting roots may hold the same
    /// header, so freeing both would double-free.
    fn alias_roots(&self, reg: RegId) -> BTreeSet<RegId> {
        let mut roots = BTreeSet::new();
        let mut visited = BTreeSet::new();
        let mut stack = vec![reg];
        while let Some(r) = stack.pop() {
            if !visited.insert(r) {
                continue;
            }
            match self.def_of(r) {
                Some(Instruction::Move { source, .. }) => stack.push(*source),
                Some(Instruction::Phi { args, .. }) => {
                    stack.extend(args.iter().map(|(_, a)| *a));
                }
                _ => {
                    roots.insert(r);
                }
            }
        }
        roots
    }

    fn lower_expr(&mut self, expr: &Expr, target: Option<RegId>) -> Result<(RegId, StaticType), LowerError> {
        let reg = target.unwrap_or_else(|| self.next_reg());

        match expr {
            Expr::Integer(val) => {
                self.emit(Instruction::LoadInt {
                    target: reg,
                    val: *val,
                });
                Ok((reg, StaticType::Integer))
            }
            Expr::Float(val) => {
                self.emit(Instruction::LoadFloat {
                    target: reg,
                    val: *val,
                });
                Ok((reg, StaticType::Float))
            }
            Expr::Boolean(val) => {
                self.emit(Instruction::LoadBool {
                    target: reg,
                    val: *val,
                });
                Ok((reg, StaticType::Boolean))
            }
            Expr::String(val) => {
                self.emit(Instruction::LoadString {
                    target: reg,
                    val: val.clone(),
                });
                Ok((reg, StaticType::String))
            }
            Expr::Nil => {
                unreachable!("nil outside a table release")
            }
            Expr::SysAllocCount => {
                let target = self.next_reg();
                self.emit(Instruction::SysAllocCount { target });
                Ok((target, StaticType::Integer))
            }
            Expr::TableCtor(entries) => {
                let elem = self.shape.elem_of(expr);

                // [Variable Capture: Deep-Free Ownership]
                // Track whether any entry value is an *inline anonymous
                // constructor*. If a table captures named identifiers (e.g.
                // `local inner = {}; local outer = {[0] = inner}`),
                // `lower_expr` resolves the identifier to its existing SSA
                // register — that variable manages its own lifetime via
                // block-scoping. Setting contains_tables (bit 0x80) on the
                // outer table would cause `glm_tbl_free` to deep-free the
                // child, which conflicts with the child's natural block-scope
                // cleanup → double-free. Only *inline* constructors
                // (`{[0] = {1, 2}}`) require the parent to own the child's
                // deep-free.
                let mut has_inline_tables = false;
                for (_, e) in entries {
                    if matches!(e, Expr::TableCtor(_)) {
                        has_inline_tables = true;
                    }
                }

                // Only flag for deep-free if elements are inline anonymous tables.
                let contains_tables = matches!(elem, crate::ast::StaticType::Table(_))
                    && has_inline_tables;

                let mut elem_regs = Vec::with_capacity(entries.len());
                for (_, e) in entries {
                    // If `e` is an Identifier, `lower_expr` natively fetches its
                    // existing SSA register — no re-allocation, no ownership leak.
                    let (r, _) = self.lower_expr(e, None)?;
                    elem_regs.push(r);
                }

                let mode_bit = match self.lookup_layout_for(expr)? {
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
                });
                // Birth register of this table site — the do-exit free
                // path frees through it when the ctor dominates the exit.
                if let Some(&site) = self.shape.sites.get(&(expr as *const Expr)) {
                    self.site_regs.insert(site, (reg, self.ctrl_depth));
                }
                // The constructor "desugars" here, at the IR level: one
                // TableSet per entry, slots as resolved at parse. This is
                // the same instruction sequence a store-built table
                // produces, so populated and store-built tables share one
                // code path downstream.
                for ((slot, _), v_reg) in entries.iter().zip(elem_regs) {
                    let i_reg = self.next_reg();
                    self.emit(Instruction::LoadInt {
                        target: i_reg,
                        val: *slot,
                    });
                    self.emit(Instruction::TableSet {
                        table: reg,
                        index: i_reg,
                        value: v_reg,
                    });
                }
                Ok((reg, StaticType::Table(Box::new(elem))))
            }
            Expr::Index { obj, key } => {
                let (t_reg, t_ty) = self.lower_expr(obj, None)?;
                let (i_reg, _) = self.lower_expr(key, None)?;
                // Determine the actual element type for the target register.
                let target_ty = match t_ty {
                    StaticType::Table(elem) => (*elem).clone(),
                    _ => unreachable!("checker guarantees a table operand"),
                };
                self.emit(Instruction::TableGet {
                    target: reg,
                    table: t_reg,
                    index: i_reg,
                    target_ty: target_ty.clone(),
                });
                Ok((reg, target_ty))
            }
            Expr::Identifier(name) => {
                let local = self.read_var(name)?;
                if target.is_some() && reg != local.reg {
                    self.emit(Instruction::Move {
                        target: reg,
                        source: local.reg,
                        ty: local.ty.clone(),
                    });
                } else {
                    return Ok((local.reg, local.ty));
                }
                Ok((reg, local.ty))
            }
            Expr::BinaryOp {
                op: op @ (BinOp::And | BinOp::Or),
                left,
                right,
            } => {
                let (l_reg, _) = self.lower_expr(left, None)?;
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
                self.ctrl_depth += 1;
                let (v_reg, _) = self.lower_expr(right, None)?;
                self.ctrl_depth -= 1;
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
                Ok((reg, StaticType::Boolean))
            }
            Expr::BinaryOp { op, left, right } => {
                let (l_reg, l_ty) = self.lower_expr(left, None)?;
                let (r_reg, r_ty) = self.lower_expr(right, None)?;
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
                Ok((reg, ty))
            }
            Expr::UnaryOp { op, expr } => {
                let (x_reg, x_ty) = self.lower_expr(expr, None)?;
                match op {
                    UnOp::Neg => {
                        self.emit(Instruction::Neg {
                            target: reg,
                            source: x_reg,
                        });
                        Ok((reg, x_ty))
                    }
                    UnOp::Not => {
                        self.emit(Instruction::Not {
                            target: reg,
                            source: x_reg,
                        });
                        Ok((reg, StaticType::Boolean))
                    }
                    UnOp::Len => {
                        self.emit(Instruction::TableLen {
                            target: reg,
                            table: x_reg,
                        });
                        Ok((reg, StaticType::Integer))
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
