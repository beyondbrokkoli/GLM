// src/shape/analyzer.rs
use std::collections::{BTreeMap, BTreeSet};
use crate::analysis::AnalysisContext;
use crate::ast::{BinOp, Expr, Stmt, UnOp};
use glm_rt::{signal, trace};

use super::core::{LayoutVerdict, TableShape, BOUNDS_FAIL_THRESHOLD, NULL_ROOT, SPARSE_THRESHOLD};
use super::facts::ShapeFacts;
use super::helpers::{extract_guard, merge_table_scopes};
use super::ty::{arith_ty, join_ty, scalar, Ty};
use Ty::{Bool, Conflict, Flt, Int, Pending, Record, Str, Tbl};

/// A localized shape-analysis failure. It bubbles to the nearest
/// `walk_stmts`, which records it in the diagnostics ledger, skips the
/// rest of ITS block, and lets the enclosing walk continue — the
/// ghost-run contract. Message texts are corpus-pinned: negative cases
/// grep them on stderr, so keep the prefix verbatim.
struct ShapeError(String);

struct Analyzer {
    scopes: Vec<BTreeMap<String, TableShape>>,
    scope_ids: Vec<u8>,
    scope_next: u8,
    scope_map: BTreeMap<(*const Stmt, u8), u8>,
    sites: BTreeMap<*const Expr, usize>,
    site_elem: Vec<Ty>,
    needed: Vec<bool>,
    changed: bool,
    recording: bool,
    free_sites: BTreeSet<*const Stmt>,
    name_dense: BTreeMap<(String, usize), bool>,
    verdicts: Vec<LayoutVerdict>,
    child_sites: BTreeMap<usize, BTreeSet<usize>>,
    /// Ghost-run ledger: one entry per localized failure. The recording
    /// walk is the authoritative pass; the driver reports these and
    /// fails the build instead of aborting mid-compile.
    diagnostics: Vec<String>,
    /// Conflict sites already reported — the resolution tail can reach
    /// one conflicting table through several paths (parent recursion,
    /// the main loop) and each site is reported once.
    conflict_reported: BTreeSet<usize>,
    /// Type-movement slots (JOIN_RETYPED, DECIDE_UPDATE*, INFER_TBL_
    /// CONFLICT) that fired during the fixpoint walks. The recording
    /// gate hides those walks, so analyze() flushes the set as one mark
    /// per slot right before the recording walk starts — the map shows
    /// "convergence moved types here" without inflating per-run counts.
    conv_fires: BTreeSet<u8>,
    /// Do-exit ownership decisions per `Stmt::Do` node (consumed by the
    /// lowerer; see ShapeFacts::do_exit_frees).
    do_exit_frees: BTreeMap<*const Stmt, Vec<String>>,
}

pub fn analyze(ctx: &AnalysisContext<'_>) -> ShapeFacts {
    let n = ctx.sites.len();
    let mut a = Analyzer {
        scopes: vec![BTreeMap::new()],
        scope_ids: Vec::new(),
        scope_next: 0,
        scope_map: BTreeMap::new(),
        sites: ctx.sites.clone(),
        site_elem: vec![Pending; n],
        needed: vec![false; n],
        changed: false,
        recording: false,
        free_sites: BTreeSet::new(),
        name_dense: BTreeMap::new(),
        verdicts: vec![LayoutVerdict::Growing; n],
        child_sites: BTreeMap::new(),
        diagnostics: Vec::new(),
        conflict_reported: BTreeSet::new(),
        conv_fires: BTreeSet::new(),
        do_exit_frees: BTreeMap::new(),
    };

    let mut prev_end: Vec<BTreeMap<String, TableShape>> = Vec::new();
    loop {
        a.changed = false;
        a.scopes = vec![BTreeMap::new()];
        a.walk_stmts(ctx.ast);
        let end = a.scopes.clone();
        let stable = end == prev_end && !a.changed;
        prev_end = end;
        if stable {
            break;
        }
    }

    // Convergence flush: the recording gate hid every fixpoint walk, so
    // the type-movement slots that fired only during convergence (probe()
    // below) surface here as exactly one mark each — deterministic order,
    // before any recording-walk event hits the chronology.
    for slot in std::mem::take(&mut a.conv_fires) {
        trace::compiler_trace_signal(slot);
    }

    a.recording = true;
    a.scopes = vec![BTreeMap::new()];
    // Scope numbering restarts with the recording walk: root is scope 0
    // and every block scope takes the next id in deterministic first-visit
    // order (the While fixpoint reuses its body's id via scope_map).
    a.scope_ids = vec![0];
    a.scope_next = 1;
    a.scope_map = BTreeMap::new();
    // The recording walk is the authoritative ghost pass — start it with
    // an empty ledger so fixpoint probes can never double-report.
    a.diagnostics.clear();
    trace::compiler_trace_current_scope(0, 0, trace::TRACE_SCOPE_PARENT_NONE);
    a.walk_stmts(ctx.ast);

    let mut elems = vec![crate::ast::StaticType::Integer; n];

    let site_ids: Vec<usize> = a.sites.values().copied().collect();
    for id in site_ids {
        if a.needed[id] && a.site_elem[id] == Pending {
            signal!(a.recording, trace::TRACE_ANALYZE_MISSING_VALUE);
            a.diagnostics.push(format!(
                "Type Error: a table is read before it is ever given a value \
                 (table site #{id})"
            ));
            elems[id] = crate::ast::StaticType::Unknown(id);
        } else if a.site_elem[id] == Pending {
            signal!(a.recording, trace::TRACE_ANALYZE_PENDING);
            elems[id] = crate::ast::StaticType::Unknown(id);
        } else {
            signal!(a.recording, trace::TRACE_ANALYZE_RESOLVED);
            elems[id] = a.elem_type_of_tbl(id);
        }
    }

    ShapeFacts {
        sites: a.sites,
        elems,
        layouts: a.verdicts,
        free_sites: a.free_sites,
        do_exit_frees: a.do_exit_frees,
        name_dense: a.name_dense,
        substitutions: BTreeMap::new(),
        diagnostics: a.diagnostics,
    }
}

fn get_base_identifier(expr: &Expr) -> Option<&String> {
    match expr {
        Expr::Identifier(name) => Some(name),
        Expr::Index { obj, .. } => get_base_identifier(obj),
        _ => None,
    }
}

impl Analyzer {
    /// Convergence-aware poke for the type-movement slots (JOIN_RETYPED,
    /// DECIDE_UPDATE*, INFER_TBL_CONFLICT): they fire while the fixpoint
    /// is still moving types — walks the recording gate excludes — and
    /// never again on the converged recording walk. During the fixpoint
    /// they accumulate into conv_fires (flushed once by analyze); during
    /// the recording walk this pokes the plate directly, like signal!.
    fn probe(&mut self, slot: u8) {
        if self.recording {
            trace::compiler_trace_signal(slot);
        } else {
            self.conv_fires.insert(slot);
        }
    }

    /// Heterogeneous-table conflict found while resolving elem types:
    /// record ONE diagnostic per conflicting site (the resolution tail
    /// can reach a site through several paths) and degrade to Unknown so
    /// the tail finishes and the plate stays whole. The compile still
    /// fails — the driver reports the ledger after the walk completes.
    fn report_conflict(&mut self, id: usize) -> crate::ast::StaticType {
        if self.conflict_reported.insert(id) {
            self.diagnostics.push(format!(
                "Type Error: heterogeneous tables are not supported (table site #{id})"
            ));
        }
        crate::ast::StaticType::Unknown(id)
    }

    fn elem_type_of_tbl(&mut self, id: usize) -> crate::ast::StaticType {
        if self.site_elem[id] == Conflict {
            signal!(self.recording, trace::TRACE_SHAPE_CONFLICT_GUARD);
            return self.report_conflict(id);
        }

        if let Record(fields) = self.site_elem[id].clone() {
            signal!(self.recording, trace::TRACE_RECORD_PRESERVED);
            let mapped = fields
                .iter()
                .map(|(name, ty)| (name.clone(), self.ty_to_static(ty, id)))
                .collect();
            return crate::ast::StaticType::Record(mapped);
        }

        if let Some(children) = self.child_sites.get(&id).cloned() {
            signal!(self.recording, trace::TRACE_CHILD_FAST_PATH);
            let mut uniform_type: Option<crate::ast::StaticType> = None;

            for &child_id in &children {
                if self.site_elem[child_id] == Conflict {
                    signal!(self.recording, trace::TRACE_ELEM_CHILD_CONFLICT);
                    return self.report_conflict(child_id);
                }

                let child_ty = self.elem_type_of_tbl(child_id);

                match &uniform_type {
                    None => {
                        signal!(self.recording, trace::TRACE_ELEM_CHILD_FIRST);
                        uniform_type = Some(child_ty.clone());
                    },
                    Some(expected) if *expected != child_ty => {
                        signal!(self.recording, trace::TRACE_ELEM_CHILD_MISMATCH);
                        return self.report_conflict(child_id);
                    }
                    Some(_) => {
                        signal!(self.recording, trace::TRACE_ELEM_CHILD_MATCH);
                    }
                }
            }

            if let Some(ty) = uniform_type {
                signal!(self.recording, trace::TRACE_ELEM_CHILD_UNIFORM);
                return crate::ast::StaticType::Table(Box::new(ty));
            }
        }

        signal!(self.recording, trace::TRACE_FALLBACK_RESOLVE);
        match self.site_elem[id].clone() {
            Tbl(inner) => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_TBL);
                crate::ast::StaticType::Table(Box::new(self.ty_to_static(&inner, id)))
            },
            Record(fields) => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_REC);
                let mapped = fields
                    .iter()
                    .map(|(name, ty)| (name.clone(), self.ty_to_static(ty, id)))
                    .collect();
                crate::ast::StaticType::Record(mapped)
            },
            Int | Pending => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_INT);
                crate::ast::StaticType::Integer
            },
            Flt => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_FLT);
                crate::ast::StaticType::Float
            },
            Bool => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_BOOL);
                crate::ast::StaticType::Boolean
            },
            Str => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_STR);
                crate::ast::StaticType::String
            },
            Conflict => {
                signal!(self.recording, trace::TRACE_ELEM_FALLBACK_CONFLICT);
                self.report_conflict(id)
            },
        }
    }

    fn ty_to_static(&mut self, ty: &Ty, site: usize) -> crate::ast::StaticType {
        match ty {
            Int => {
                signal!(self.recording, trace::TRACE_TY_STATIC_INT);
                crate::ast::StaticType::Integer
            },
            Pending => {
                signal!(self.recording, trace::TRACE_TY_STATIC_PENDING);
                crate::ast::StaticType::Integer
            },
            Flt => {
                signal!(self.recording, trace::TRACE_TY_STATIC_FLT);
                crate::ast::StaticType::Float
            },
            Bool => {
                signal!(self.recording, trace::TRACE_TY_STATIC_BOOL);
                crate::ast::StaticType::Boolean
            },
            Str => {
                signal!(self.recording, trace::TRACE_TY_STATIC_STR);
                crate::ast::StaticType::String
            },
            Tbl(inner) => {
                signal!(self.recording, trace::TRACE_TY_STATIC_TBL);
                crate::ast::StaticType::Table(Box::new(self.ty_to_static(inner, site)))
            },
            Record(fields) => {
                signal!(self.recording, trace::TRACE_TY_STATIC_REC);
                let mapped = fields
                    .iter()
                    .map(|(name, ty)| (name.clone(), self.ty_to_static(ty, site)))
                    .collect();
                crate::ast::StaticType::Record(mapped)
            },
            Conflict => {
                signal!(self.recording, trace::TRACE_TY_STATIC_CONFLICT);
                self.report_conflict(site)
            },
        }
    }

    /// The ghost-run boundary: one statement's failure poisons only the
    /// block that contains it. The error is ledgered and scope-tagged
    /// (GHOST_BAIL fires with the current block's register), the rest of
    /// this slice is skipped, and the enclosing walk resumes with the
    /// next sibling — the scope bracket in the parent statement
    /// (enter_scope/exit_scope around this call) stays balanced because
    /// we return normally.
    fn walk_stmts(&mut self, stmts: &[Stmt]) {
        for s in stmts {
            if let Err(err) = self.walk_stmt(s) {
                signal!(self.recording, trace::TRACE_GHOST_BAIL);
                self.diagnostics.push(err.0);
                return;
            }
        }
    }

    fn walk_stmt(&mut self, stmt: &Stmt) -> Result<(), ShapeError> {
        match stmt {
            Stmt::LocalDecl { names, exprs } => {
                let mut sets = Vec::with_capacity(names.len());
                for expr in exprs {
                    self.check_uses(expr)?;
                    if matches!(expr, Expr::Nil) {
                        signal!(self.recording, trace::TRACE_BIND_SCALAR);
                        sets.push(TableShape {
                            ty: Pending,
                            layout: LayoutVerdict::default(),
                            aliases: BTreeSet::from([NULL_ROOT]),
                        });
                    } else {
                        let bind = self.infer_bind(expr)?;
                        if scalar(&bind.ty) {
                            signal!(self.recording, trace::TRACE_BIND_SCALAR);
                        } else if matches!(expr, Expr::TableCtor(_) | Expr::RecordCtor(_)) {
                            signal!(self.recording, trace::TRACE_BIND_HEAP);
                        }
                        sets.push(bind);
                    }
                }
                while sets.len() < names.len() {
                    signal!(self.recording, trace::TRACE_BIND_SCALAR);
                    sets.push(TableShape {
                        ty: Pending,
                        layout: LayoutVerdict::default(),
                        aliases: BTreeSet::from([NULL_ROOT]),
                    });
                }

                for (name, set) in names.iter().zip(sets) {
                    let shadowed = self
                        .scopes
                        .last()
                        .is_some_and(|s| s.contains_key(name));
                    if shadowed {
                        signal!(self.recording, trace::TRACE_SHAPE_DROP);
                    }
                    let scope = self.scopes.last_mut().unwrap();
                    scope.insert(name.clone(), set);
                }
            }

            Stmt::Assignment { name, expr } => {
                if matches!(expr, Expr::Nil) {
                    signal!(self.recording, trace::TRACE_STMT_ASSIGN_NIL);
                    self.drop_reference(name, stmt)?;
                    return Ok(());
                }
                self.check_uses(expr)?;
                let bind = self.infer_bind(expr)?;
                if scalar(&bind.ty) {
                    signal!(self.recording, trace::TRACE_BIND_SCALAR);
                } else if matches!(expr, Expr::TableCtor(_) | Expr::RecordCtor(_)) {
                    signal!(self.recording, trace::TRACE_BIND_HEAP);
                }

                if matches!(bind.ty, Tbl(_)) {
                    signal!(self.recording, trace::TRACE_STMT_ASSIGN_TBL);
                    let mut incoming = Pending;
                    for s in &bind.aliases {
                        if *s != NULL_ROOT {
                            signal!(self.recording, trace::TRACE_STMT_ASSIGN_TBL_VALID);
                            incoming = join_ty(&incoming, &self.site_elem[*s]);
                        }
                    }
                    if scalar(&incoming) {
                        signal!(self.recording, trace::TRACE_STMT_ASSIGN_TBL_SCALAR);
                        let old = self.resolve_aliases(name)?;
                        for s in old {
                            if s != NULL_ROOT {
                                signal!(self.recording, trace::TRACE_STMT_ASSIGN_TBL_SCALAR_VALID);
                                self.decide(s, &incoming);
                            }
                        }
                    }
                }

                for scope in self.scopes.iter_mut().rev() {
                    if scope.contains_key(name) {
                        signal!(self.recording, trace::TRACE_STMT_ASSIGN_RESOLVED);
                        scope.insert(name.clone(), bind);
                        return Ok(());
                    }
                }
                return Err(ShapeError(format!(
                    "Scope Error: assignment to undeclared variable '{}'",
                    name
                )));
            }

            Stmt::IndexAssign { obj, key, value } => {
                let (t, _) = self.infer_expr(obj)?;
                self.infer_expr(key)?;
                self.check_table_use(obj)?;
                self.check_uses(obj)?;
                self.check_uses(key)?;

                let (vt, _) = self.infer_expr(value)?;

                // Store-value discrimination for the ownership map: a
                // record stored into a table is the BS-11 enabler (no
                // ownership edge, never frees); a table stored into a
                // table rides the deep-free flag edge.
                if self.recording {
                    if matches!(vt, Record(_)) {
                        signal!(self.recording, trace::TRACE_STMT_IDX_REC_VALUE);
                    } else if matches!(vt, Tbl(_)) {
                        signal!(self.recording, trace::TRACE_STMT_IDX_TBL_VALUE);
                    }
                }

                let mut base_obj = obj;
                let mut expected_ty = vt.clone();

                while let Expr::Index { obj: parent_obj, .. } = base_obj {
                    signal!(self.recording, trace::TRACE_STMT_IDX_NESTED);
                    expected_ty = Tbl(Box::new(expected_ty));
                    base_obj = parent_obj.as_ref();
                }

                let (_, base_sites) = self.infer_expr(base_obj)?;

                if matches!(t, Tbl(_) | Pending) {
                    signal!(self.recording, trace::TRACE_STMT_IDX_BASE_TBL);
                    for s in &base_sites {
                        if *s != NULL_ROOT {
                            signal!(self.recording, trace::TRACE_STMT_IDX_VALID_ALIAS);
                            self.decide(*s, &expected_ty);
                        }
                    }
                }

                if self.recording {
                    signal!(self.recording, trace::TRACE_STMT_IDX_CHECK_THRESH);
                    self.check_key_threshold(key, &base_sites)?;
                }
            }

            Stmt::While { condition, body } => {
                self.infer_expr(condition)?;
                self.check_uses(condition)?;

                if self.recording && let Some(guard) = extract_guard(condition) {
                    signal!(self.recording, trace::TRACE_STMT_WHILE_FILL);
                    self.detect_fill_loop(guard, body);
                }

                let entry = self.scopes.clone();
                let mut head = entry.clone();
                let scope_key = (stmt as *const Stmt, 0);
                loop {
                    self.scopes = head.clone();
                    self.check_uses(condition)?;
                    self.enter_scope(scope_key);
                    self.walk_stmts(body);
                    self.exit_scope();
                    let latch = self.scopes.clone();
                    let mut merged = entry.clone();
                    merge_table_scopes(&mut merged, &head, &latch);
                    if merged == head {
                        signal!(self.recording, trace::TRACE_STMT_WHILE_STABLE);
                        break;
                    }
                    head = merged;
                }
                self.scopes = head;
            }

            Stmt::If {
                condition,
                then_body,
                else_body,
            } => {
                signal!(self.recording, trace::TRACE_STMT_IF);
                self.infer_expr(condition)?;
                self.check_uses(condition)?;
                let snapshot = self.scopes.clone();
                self.enter_scope((stmt as *const Stmt, 0));
                self.walk_stmts(then_body);
                self.exit_scope();
                let then_exit = self.scopes.clone();
                self.scopes = snapshot;
                self.enter_scope((stmt as *const Stmt, 1));
                self.walk_stmts(else_body);
                self.exit_scope();
                let else_exit = self.scopes.clone();
                merge_table_scopes(&mut self.scopes, &then_exit, &else_exit);
            }

            Stmt::Do { body } => {
                signal!(self.recording, trace::TRACE_STMT_DO);
                self.enter_scope((stmt as *const Stmt, 0));
                self.walk_stmts(body);
                // Ownership proof while the dying scope is still on the
                // stack: the pokes land in the block's own scope id. The
                // refusal is RETURNED, not `?`-propagated, until the
                // scope bracket closes — an early `?` here would skip
                // exit_scope, leave the shape stack and the trace
                // register unbalanced, and make every enclosing do-exit
                // decision read a stale scope as its own.
                let verdict = self.decide_do_exit(stmt);
                self.exit_scope();
                verdict?
            }

            Stmt::Print { exprs } => {
                signal!(self.recording, trace::TRACE_STMT_PRINT);
                for e in exprs {
                    self.infer_expr(e)?;
                    self.check_uses(e)?;
                }
            }
        }
        Ok(())
    }

    fn infer_bind(&mut self, expr: &Expr) -> Result<TableShape, ShapeError> {
        let (ty, aliases) = self.infer_expr(expr)?;
        Ok(TableShape {
            ty,
            layout: LayoutVerdict::default(),
            aliases,
        })
    }

    /// Stable scope id for a block scope: first visit assigns the next id
    /// in deterministic walk order; re-visits — the While fixpoint re-walks
    /// its body — reuse it so per-scope counts never split. Beyond 254
    /// block scopes fold into id 255 (plate limit, small scripts).
    fn scope_id(&mut self, key: (*const Stmt, u8)) -> u8 {
        if let Some(&id) = self.scope_map.get(&key) {
            return id;
        }
        let id = self.scope_next;
        self.scope_next = self.scope_next.saturating_add(1);
        self.scope_map.insert(key, id);
        id
    }

    /// Open a block scope. Always pushes the shape scope (the fixpoint
    /// walk depends on it); the trace register and the parallel id stack
    /// move only during the recording walk.
    fn enter_scope(&mut self, key: (*const Stmt, u8)) {
        if self.recording {
            let id = self.scope_id(key);
            let parent = *self.scope_ids.last().expect("root scope always open");
            trace::compiler_trace_current_scope(id, self.scopes.len() as u8, parent);
            self.scope_ids.push(id);
        }
        self.scopes.push(BTreeMap::new());
    }

    /// Close a block scope; the register returns to the parent scope.
    fn exit_scope(&mut self) {
        if self.recording {
            self.scope_ids.pop();
            let id = *self.scope_ids.last().expect("root scope always open");
            let depth = self.scope_ids.len() as u8 - 1;
            let parent = if self.scope_ids.len() >= 2 {
                self.scope_ids[self.scope_ids.len() - 2]
            } else {
                trace::TRACE_SCOPE_PARENT_NONE
            };
            trace::compiler_trace_current_scope(id, depth, parent);
        }
        self.scopes.pop();
    }

    fn resolve(&self, name: &str) -> Result<(usize, TableShape), ShapeError> {
        for (depth, scope) in self.scopes.iter().enumerate().rev() {
            if let Some(bind) = scope.get(name) {
                signal!(self.recording, trace::TRACE_RESOLVE_FOUND);
                return Ok((depth, bind.clone()));
            }
        }
        Err(ShapeError(format!(
            "Scope Error: reference to undeclared variable '{}'",
            name
        )))
    }

    fn resolve_aliases(&self, name: &str) -> Result<BTreeSet<usize>, ShapeError> {
        Ok(self.resolve(name)?.1.aliases)
    }

    fn decide(&mut self, site: usize, vt: &Ty) {
        signal!(self.recording, trace::TRACE_DECIDE_VISIT);
        if self.site_elem[site] == Conflict {
            signal!(self.recording, trace::TRACE_DECIDE_CONFLICT);
            return;
        }

        let joined = join_ty(&self.site_elem[site], vt);
        if self.site_elem[site] != joined {
            self.probe(trace::TRACE_JOIN_RETYPED);
            self.site_elem[site] = joined.clone();
            self.changed = true;
        }

        let expected_var_ty = Tbl(Box::new(self.site_elem[site].clone()));

        // Split borrow: probe bookkeeping (conv_fires) and the scope walk
        // touch disjoint fields, so both run in one pass.
        let Self { scopes, conv_fires, recording, changed, .. } = self;
        for scope in scopes.iter_mut() {
            for ts in scope.values_mut() {
                if ts.aliases.contains(&site) && site != NULL_ROOT
                    && (ts.ty == Pending || ts.ty != expected_var_ty)
                {
                    if *recording {
                        trace::compiler_trace_signal(trace::TRACE_DECIDE_UPDATE);
                    } else {
                        conv_fires.insert(trace::TRACE_DECIDE_UPDATE);
                    }
                    ts.ty = expected_var_ty.clone();
                    if ts.ty != Pending {
                        if *recording {
                            trace::compiler_trace_signal(trace::TRACE_DECIDE_UPDATE_CHANGED);
                        } else {
                            conv_fires.insert(trace::TRACE_DECIDE_UPDATE_CHANGED);
                        }
                        *changed = true;
                    }
                }
            }
        }
    }

    fn infer_expr(&mut self, expr: &Expr) -> Result<(Ty, BTreeSet<usize>), ShapeError> {
        match expr {
            Expr::Integer(_) => {
                signal!(self.recording, trace::TRACE_INFER_INT);
                Ok((Int, BTreeSet::new()))
            },
            Expr::Float(_) => {
                signal!(self.recording, trace::TRACE_INFER_FLT);
                Ok((Flt, BTreeSet::new()))
            },
            Expr::Boolean(_) => {
                signal!(self.recording, trace::TRACE_INFER_BOOL);
                Ok((Bool, BTreeSet::new()))
            },
            Expr::String(_) => {
                signal!(self.recording, trace::TRACE_INFER_STR);
                Ok((Str, BTreeSet::new()))
            },
            Expr::Nil => {
                signal!(self.recording, trace::TRACE_INFER_NIL);
                Ok((Conflict, BTreeSet::new()))
            },
            Expr::TableCtor(elems) => {
                let id = self.sites[&(expr as *const Expr)];
                let mut first_elem_ty: Option<Ty> = None;
                for e in elems {
                    let (t, _) = self.infer_expr(e)?;
                    if matches!(t, Tbl(_))
                        && let Some(&child_site) = self.sites.get(&(e as *const Expr))
                    {
                        signal!(self.recording, trace::TRACE_INFER_TBL_CHILD);
                        self.child_sites.entry(id).or_default().insert(child_site);
                    }
                    match first_elem_ty {
                        None => {
                            signal!(self.recording, trace::TRACE_INFER_TBL_FIRST);
                            first_elem_ty = Some(t.clone());
                        },
                        Some(ref expected) if *expected != t => {
                            signal!(self.recording, trace::TRACE_INFER_TBL_MISMATCH);
                            if self.site_elem[id] != Conflict {
                                self.probe(trace::TRACE_INFER_TBL_CONFLICT);
                                self.site_elem[id] = Conflict;
                                self.changed = true;
                            }
                        }
                        Some(_) => {
                            signal!(self.recording, trace::TRACE_INFER_TBL_MATCH);
                        }
                    }
                    self.decide(id, &t);
                }
                let resolved = if self.site_elem[id] != Pending {
                    signal!(self.recording, trace::TRACE_INFER_TBL_RESOLVED);
                    self.site_elem[id].clone()
                } else {
                    signal!(self.recording, trace::TRACE_INFER_TBL_PENDING);
                    first_elem_ty.unwrap_or(Pending)
                };
                Ok((Tbl(Box::new(resolved)), BTreeSet::from([id])))
            }
            Expr::RecordCtor(fields) => {
                let id = self.sites[&(expr as *const Expr)];
                signal!(self.recording, trace::TRACE_REC_CTOR);
                let mut record_ty: Vec<(String, Ty)> = Vec::with_capacity(fields.len());
                for (name, val_expr) in fields {
                    signal!(self.recording, trace::TRACE_REC_FIELD);
                    let (t, _) = self.infer_expr(val_expr)?;
                    if matches!(t, Record(_)) {
                        signal!(self.recording, trace::TRACE_REC_NESTED);
                    }
                    if matches!(t, Tbl(_))
                        && let Some(&child_site) = self.sites.get(&(val_expr as *const Expr))
                    {
                        signal!(self.recording, trace::TRACE_INFER_REC_CHILD);
                        self.child_sites.entry(id).or_default().insert(child_site);
                    }
                    record_ty.push((name.clone(), t));
                }
                self.site_elem[id] = Record(record_ty.clone());
                Ok((Record(record_ty), BTreeSet::from([id])))
            }
            Expr::Index { obj, key } => {
                let (kt, _) = self.infer_expr(key)?;
                if matches!(kt, Flt | Bool | Str) {
                    signal!(self.recording, trace::TRACE_INFER_IDX_BAD_KEY);
                    self.infer_expr(obj)?;
                    return Ok((Conflict, BTreeSet::new()));
                }
                let (t, sites) = self.infer_expr(obj)?;
                if !matches!(t, Tbl(_) | Record(_)) {
                    signal!(self.recording, trace::TRACE_INFER_IDX_BAD_OBJ);
                    return Ok((Conflict, BTreeSet::new()));
                }
                let mut r = Pending;
                for s in &sites {
                    if *s != NULL_ROOT {
                        signal!(self.recording, trace::TRACE_INFER_IDX_VALID);
                        self.needed[*s] = true;
                        r = join_ty(&r, &self.site_elem[*s]);
                    }
                }
                Ok((r, BTreeSet::new()))
            }
            Expr::Identifier(name) => {
                signal!(self.recording, trace::TRACE_INFER_IDENT);
                let (depth, bind) = self.resolve(name)?;
                let _ = depth;
                Ok((bind.ty, bind.aliases.clone()))
            }
            Expr::BinaryOp { op, left, right } => {
                let (lt, _) = self.infer_expr(left)?;
                let (rt, _) = self.infer_expr(right)?;
                match op {
                    BinOp::Add
                    | BinOp::Sub
                    | BinOp::Mul
                    | BinOp::Div
                    | BinOp::IntDiv
                    | BinOp::Mod => {
                        signal!(self.recording, trace::TRACE_INFER_BINOP_ARITH);
                        Ok((arith_ty(lt, rt), BTreeSet::new()))
                    },
                    _ => {
                        signal!(self.recording, trace::TRACE_INFER_BINOP_OTHER);
                        Ok((Bool, BTreeSet::new()))
                    },
                }
            }
            Expr::UnaryOp { op, expr } => {
                let (t, _) = self.infer_expr(expr)?;
                match op {
                    UnOp::Neg => {
                        signal!(self.recording, trace::TRACE_INFER_UNOP_NEG);
                        Ok((t, BTreeSet::new()))
                    },
                    UnOp::Not => {
                        signal!(self.recording, trace::TRACE_INFER_UNOP_NOT);
                        Ok((Bool, BTreeSet::new()))
                    },
                    UnOp::Len => {
                        signal!(self.recording, trace::TRACE_INFER_UNOP_LEN);
                        Ok((Int, BTreeSet::new()))
                    },
                }
            }
            Expr::SysAllocCount => {
                signal!(self.recording, trace::TRACE_INFER_SYSALLOC);
                Ok((Int, BTreeSet::new()))
            },
        }
    }

    /// The do-exit ownership proof — the scope-exit face of the same
    /// analysis `drop_reference` runs for explicit `t = nil`. A heap
    /// site may be freed at block exit iff it appears in no binding
    /// that survives the block; every dying binding that holds it
    /// shares ONE TableFree (the lowerer frees per site, not per
    /// name). A site held by a surviving binding used to be freed
    /// through the block-local anyway — an early free leaving the
    /// surviving name dangling (silent UAF); it is now a loud,
    /// localized compile-time rejection. Runs only on the recording
    /// walk: the fixpoint's scope state is intermediate and its
    /// probes never see errors (same gate as check_table_use).
    fn decide_do_exit(&mut self, stmt: &Stmt) -> Result<(), ShapeError> {
        if !self.recording {
            return Ok(());
        }

        let dying = self.scopes.last().expect("do scope always open").clone();
        let surviving: BTreeSet<usize> = self.scopes[..self.scopes.len() - 1]
            .iter()
            .flat_map(|scope| scope.values())
            .flat_map(|shape| shape.aliases.iter().copied())
            .filter(|site| *site != NULL_ROOT)
            .collect();

        let mut seen_sites: BTreeSet<usize> = BTreeSet::new();
        let mut free_names: Vec<String> = Vec::new();
        for (name, shape) in &dying {
            let roots: Vec<usize> = shape
                .aliases
                .iter()
                .copied()
                .filter(|site| *site != NULL_ROOT)
                .collect();
            if roots.is_empty() {
                // Scalar, bare local, or explicitly nil-dropped — the
                // nil-drop already freed at its own statement.
                continue;
            }
            for site in roots {
                if surviving.contains(&site) {
                    signal!(self.recording, trace::TRACE_DO_EXIT_ALIAS_SURVIVES);
                    return Err(ShapeError(format!(
                        "Lifetime Error: block-local '{name}' aliases a table that outlives \
                         the block — block-exit frees are rejected at compile time"
                    )));
                }
                if !seen_sites.insert(site) {
                    signal!(self.recording, trace::TRACE_DO_EXIT_FREE_SHARED);
                } else {
                    signal!(self.recording, trace::TRACE_DO_EXIT_FREE_SITE);
                    free_names.push(name.clone());
                }
            }
        }
        self.do_exit_frees.insert(stmt as *const Stmt, free_names);
        Ok(())
    }

    fn drop_reference(&mut self, name: &str, stmt: &Stmt) -> Result<(), ShapeError> {
        let (depth, bind) = self.resolve(name)?;
        let roots: Vec<usize> = bind
            .aliases
            .iter()
            .copied()
            .filter(|r| *r != NULL_ROOT)
            .collect();
        let sole = roots.iter().all(|r| {
            self.scopes.iter().enumerate().all(|(d, scope)| {
                scope
                    .iter()
                    .all(|(n, s)| (d == depth && n == name) || !s.aliases.contains(r))
            })
        });
        if !roots.is_empty() && sole && self.recording {
            self.free_sites.insert(stmt as *const Stmt);
            signal!(self.recording, trace::TRACE_SHAPE_DROP);
        } else if !roots.is_empty() && !sole && self.recording {
            signal!(self.recording, trace::TRACE_FAIL_ALIAS_UNION);
        }
        self.scopes[depth].insert(
            name.to_string(),
            TableShape {
                ty: Pending,
                layout: LayoutVerdict::default(),
                aliases: BTreeSet::from([NULL_ROOT]),
            },
        );
        Ok(())
    }

    /// The lifetime guard, unhooked: instead of aborting the compiler it
    /// returns the localized error to the enclosing `walk_stmts`, which
    /// ghosts the rest of the block. Same recording gate as before — the
    /// fixpoint probes never see the error, so convergence is unchanged.
    fn check_table_use(&mut self, obj: &Expr) -> Result<(), ShapeError> {
        if let Expr::Identifier(name) = obj {
            signal!(self.recording, trace::TRACE_CHK_TBL_IDENT);
            let (_, bind) = self.resolve(name)?;
            if bind.aliases.contains(&NULL_ROOT) && self.recording {
                signal!(self.recording, trace::TRACE_CHK_TBL_NIL);
                return Err(ShapeError(format!(
                    "Lifetime Error: '{name}' may be nil here — table reads, stores, and \
                     '#' through a possibly-nil name are rejected at compile time"
                )));
            }
        }
        Ok(())
    }

    fn check_uses(&mut self, expr: &Expr) -> Result<(), ShapeError> {
        match expr {
            Expr::TableCtor(elems) => {
                signal!(self.recording, trace::TRACE_CHK_USE_TBL);
                for e in elems {
                    self.check_uses(e)?;
                }
            }
            Expr::RecordCtor(fields) => {
                signal!(self.recording, trace::TRACE_CHK_USE_REC);
                for (_, val) in fields {
                    self.check_uses(val)?;
                }
            }
            Expr::Index { obj, key } => {
                signal!(self.recording, trace::TRACE_CHK_USE_IDX);
                self.check_table_use(obj)?;
                self.check_uses(obj)?;
                self.check_uses(key)?;
            }
            Expr::UnaryOp { op, expr } => {
                if matches!(op, UnOp::Len) {
                    signal!(self.recording, trace::TRACE_CHK_USE_UNOP_LEN);
                    self.check_table_use(expr)?;
                }
                self.check_uses(expr)?;
            }
            Expr::BinaryOp { left, right, .. } => {
                signal!(self.recording, trace::TRACE_CHK_USE_BINOP);
                self.check_uses(left)?;
                self.check_uses(right)?;
            }
            _ => {}
        }
        Ok(())
    }

    fn check_key_threshold(&mut self, key: &Expr, sites: &BTreeSet<usize>) -> Result<(), ShapeError> {
        if let Expr::Integer(i) = key {
            signal!(self.recording, trace::TRACE_THRESH_INT);
            if *i >= BOUNDS_FAIL_THRESHOLD {
                signal!(self.recording, trace::TRACE_THRESH_BOUNDS);
                return Err(ShapeError("Table Bounds Error: table index overflow".to_string()));
            }
            if *i > SPARSE_THRESHOLD {
                signal!(self.recording, trace::TRACE_THRESH_SPARSE);
                for &site in sites {
                    if site != NULL_ROOT {
                        signal!(self.recording, trace::TRACE_THRESH_SPARSE_ALIAS);
                        self.verdicts[site] = self.verdicts[site].join(LayoutVerdict::Sparse);
                    }
                }
            }
            let _ = i;
        }
        Ok(())
    }

    fn detect_fill_loop(&mut self, guard: &str, body: &[Stmt]) {
        let mutated = self.collect_mutated_names(body);
        let mut fills = BTreeSet::new();

        fn collect_fills(stmts: &[Stmt], guard: &str, mutated: &BTreeSet<String>, fills: &mut BTreeSet<String>) {
            for stmt in stmts {
                if let Stmt::IndexAssign { obj, key: Expr::Identifier(key_ident), .. } = stmt
                    && key_ident == guard
                    && let Some(table_name) = get_base_identifier(obj)
                    && !mutated.contains(table_name)
                {
                    fills.insert(table_name.clone());
                }
                match stmt {
                    Stmt::While { body, .. } | Stmt::Do { body } => {
                        collect_fills(body, guard, mutated, fills)
                    }
                    Stmt::If { then_body, else_body, .. } => {
                        collect_fills(then_body, guard, mutated, fills);
                        collect_fills(else_body, guard, mutated, fills);
                    }
                    _ => {}
                }
            }
        }

        collect_fills(body, guard, &mutated, &mut fills);

        let depth = self.scopes.len();
        for table_name in fills {
            let site_ids: BTreeSet<usize> = self
                .scopes
                .iter()
                .rev()
                .filter_map(|s| s.get(&table_name))
                .flat_map(|ts| ts.aliases.iter().copied())
                .collect();

            for &site in &site_ids {
                if site != NULL_ROOT {
                    signal!(self.recording, trace::TRACE_FILL_LOOP_DENSE);
                    self.verdicts[site] = LayoutVerdict::Dense;
                }
            }

            self.name_dense.insert((table_name, depth), true);
        }
    }

    fn collect_mutated_names(&self, stmts: &[Stmt]) -> BTreeSet<String> {
        let mut mutated = BTreeSet::new();
        for s in stmts {
            match s {
                Stmt::Assignment { name, .. } => {
                    signal!(self.recording, trace::TRACE_MUT_ASSIGN);
                    mutated.insert(name.clone());
                }
                Stmt::While { .. } => {}
                Stmt::Do { .. } => {}
                Stmt::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    signal!(self.recording, trace::TRACE_MUT_IF);
                    for ss in then_body {
                        if let Stmt::Assignment { name, .. } = ss {
                            signal!(self.recording, trace::TRACE_MUT_THEN_ASSIGN);
                            mutated.insert(name.clone());
                        }
                    }
                    for ss in else_body {
                        if let Stmt::Assignment { name, .. } = ss {
                            signal!(self.recording, trace::TRACE_MUT_ELSE_ASSIGN);
                            mutated.insert(name.clone());
                        }
                    }
                }
                _ => {}
            }
        }
        mutated
    }
}
