// src/shape.rs
use crate::analysis::AnalysisContext;
use crate::ast::{BinOp, Expr, Stmt, UnOp};
use std::collections::{BTreeSet, HashMap, HashSet};

#[derive(Clone, PartialEq, Eq, Debug, Default)]
pub enum Ty {
    #[default]
    Pending,
    Int,
    Flt,
    Bool,
    Str,
    Tbl(Box<Ty>),
    Record(Vec<(String, Ty)>),
    Conflict,
}

use Ty::{Bool, Conflict, Flt, Int, Pending, Record, Str, Tbl};

pub fn merge_table_scopes(
    into: &mut [HashMap<String, TableShape>],
    a: &[HashMap<String, TableShape>],
    b: &[HashMap<String, TableShape>],
) {
    for ((into_slot, a_slot), b_slot) in into.iter_mut().zip(a).zip(b) {
        for (name, val) in into_slot.iter_mut() {
            if let Some(x) = a_slot.get(name) {
                val.join(x);
            }
            if let Some(x) = b_slot.get(name) {
                val.join(x);
            }
        }
    }
}

fn scalar(t: &Ty) -> bool {
    matches!(t, Int | Flt | Bool | Str)
}

fn join_ty(a: &Ty, b: &Ty) -> Ty {
    match (a, b) {
        (Pending, x) | (x, Pending) => x.clone(),
        (Conflict, _) | (_, Conflict) => Conflict,
        (Tbl(inner_a), Tbl(inner_b)) => {
            // Deep monomorphism: recursively join inner types to safely collapse Pending.
            let merged = join_ty(inner_a, inner_b);
            if merged != Conflict {
                Tbl(Box::new(merged))
            } else {
                Conflict
            }
        }
        (Record(fields_a), Record(fields_b)) => {
            // Strict structural equivalence: identical keys required, join each value.
            if fields_a.len() != fields_b.len() {
                return Conflict;
            }
            let mut result = Vec::with_capacity(fields_a.len());
            for (name_a, ty_a) in fields_a {
                if let Some((_, ty_b)) = fields_b.iter().find(|(n, _)| n == name_a) {
                    match join_ty(ty_a, ty_b) {
                        Conflict => return Conflict,
                        merged => result.push((name_a.clone(), merged)),
                    }
                } else {
                    return Conflict;
                }
            }
            Record(result)
        }
        (x, y) if x == y => x.clone(),
        _ => Conflict,
    }
}

fn arith_ty(a: Ty, b: Ty) -> Ty {
    if a == Pending || b == Pending {
        Pending
    } else if a == b && matches!(a, Int | Flt) {
        a
    } else {
        Conflict
    }
}


#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum LayoutVerdict {
    #[default]
    Dense,
    Growing,
    Sparse,
    BoundsFail,
}

impl LayoutVerdict {
        fn join(self, other: LayoutVerdict) -> LayoutVerdict {
        use LayoutVerdict::*;
        match (self, other) {
            (BoundsFail, _) | (_, BoundsFail) => BoundsFail,
            (Sparse, _) | (_, Sparse) => Sparse,
            (Growing, _) | (_, Growing) => Growing,
            _ => Dense,
        }
    }
}


#[derive(Clone, PartialEq, Debug)]
pub struct TableShape {
        pub ty: Ty,
        pub layout: LayoutVerdict,
        pub aliases: BTreeSet<usize>,
}

impl TableShape {
        pub fn join(&mut self, other: &Self) -> bool {
        let mut changed = false;

        let new_ty = join_ty(&self.ty, &other.ty);
        if self.ty != new_ty {
            self.ty = new_ty;
            changed = true;
        }

        let new_layout = self.layout.join(other.layout);
        if self.layout != new_layout {
            self.layout = new_layout;
            changed = true;
        }

        let len_before = self.aliases.len();
        self.aliases.extend(&other.aliases);
        if self.aliases.len() > len_before {
            changed = true;
        }

        changed
    }
}

pub struct ShapeFacts {
    pub sites: HashMap<*const Expr, usize>,
    pub elems: Vec<crate::ast::StaticType>,

    #[allow(dead_code)] // The LLVM backend will use this soon!
    pub layouts: Vec<LayoutVerdict>,

    pub free_sites: HashSet<*const Stmt>,
    pub name_dense: HashMap<(String, usize), bool>,
    pub substitutions: HashMap<usize, crate::ast::StaticType>,
}

impl ShapeFacts {
    pub fn elem_of(&self, ctor: &Expr) -> crate::ast::StaticType {
        let id = self.sites[&(ctor as *const Expr)];
        let elem = self.elems[id].clone();
        // Resolve any Unknown type variables using the substitution map.
        self.resolve_elem_type(elem)
    }

    fn resolve_elem_type(&self, ty: crate::ast::StaticType) -> crate::ast::StaticType {
        match &ty {
            crate::ast::StaticType::Unknown(id) => {
                self.substitutions
                    .get(id)
                    .cloned()
                    .unwrap_or(ty)
            }
            crate::ast::StaticType::Table(inner) => {
                let resolved = self.resolve_elem_type((**inner).clone());
                crate::ast::StaticType::Table(Box::new(resolved))
            }
            _ => ty,
        }
    }

    pub fn is_dense_at_depth(&self, name: &str, depth: usize) -> bool {
        self.name_dense
            .get(&(name.to_string(), depth))
            .copied()
            .unwrap_or(false)
    }

    pub fn is_free(&self, stmt: &Stmt) -> bool {
        self.free_sites.contains(&(stmt as *const Stmt))
    }
}


const SPARSE_THRESHOLD: i64 = 100_000;

const BOUNDS_FAIL_THRESHOLD: i64 = i64::MAX / 8;

const NULL_ROOT: usize = usize::MAX;

struct Analyzer {
    scopes: Vec<HashMap<String, TableShape>>,
    sites: HashMap<*const Expr, usize>,
    site_elem: Vec<Ty>,
    needed: Vec<bool>,
    changed: bool,
    recording: bool,
    free_sites: HashSet<*const Stmt>,
    name_dense: HashMap<(String, usize), bool>,
    verdicts: Vec<LayoutVerdict>,
    child_sites: HashMap<usize, BTreeSet<usize>>,
}

pub fn analyze(ctx: &AnalysisContext<'_>) -> ShapeFacts {
    let n = ctx.sites.len();
    let mut a = Analyzer {
        scopes: vec![HashMap::new()],
        sites: ctx.sites.clone(),
        site_elem: vec![Pending; n],
        needed: vec![false; n],
        changed: false,
        recording: false,
        free_sites: HashSet::new(),
        name_dense: HashMap::new(),
        verdicts: vec![LayoutVerdict::Growing; n],
        child_sites: HashMap::new(),
    };

    let mut prev_end: Vec<HashMap<String, TableShape>> = Vec::new();
    loop {
        a.changed = false;
        a.scopes = vec![HashMap::new()];
        a.walk_stmts(ctx.ast);
        let end = a.scopes.clone();
        let stable = end == prev_end && !a.changed;
        prev_end = end;
        if stable {
            break;
        }
    }

    a.recording = true;
    a.scopes = vec![HashMap::new()];
    a.walk_stmts(ctx.ast);

    let mut elems = vec![crate::ast::StaticType::Integer; n];

    for &id in a.sites.values() {
        if a.needed[id] && a.site_elem[id] == Pending {
            panic!("Type Error: a table is read before it is ever given a value");
        }
        if a.site_elem[id] == Pending {
            elems[id] = crate::ast::StaticType::Unknown(id);
        } else {
            elems[id] = a.elem_type_of_tbl(id);
        }
    }

    ShapeFacts {
        sites: a.sites,
        elems,
        layouts: a.verdicts,
        free_sites: a.free_sites,
        name_dense: a.name_dense,
        substitutions: HashMap::new(),
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
    fn elem_type_of_tbl(&self, id: usize) -> crate::ast::StaticType {
        // [FIX]: The parent site may have been flagged Conflict by a heterogeneous
        // IndexAssign (e.g. {{7}, {8}} → v34[1][1] = "string"). Check before
        // rebuilding from children — the children are pure Int tables that never
        // saw the conflict, so the child_sites path would silently return a valid
        // Table<Table<Integer>> and ignore the Corruption entirely.
        if self.site_elem[id] == Conflict {
            panic!("Type Error: heterogeneous tables are not supported.");
        }

        // Fast path for tracked child constructors: enforce multi-child coherence
        if let Some(children) = self.child_sites.get(&id) {
            let mut uniform_type: Option<crate::ast::StaticType> = None;

            for &child_id in children {
                if self.site_elem[child_id] == Conflict {
                    panic!("Type Error: heterogeneous tables are not supported.");
                }

                let child_ty = self.elem_type_of_tbl(child_id);

                match &uniform_type {
                    None => uniform_type = Some(child_ty.clone()),
                    Some(expected) if *expected != child_ty => {
                        panic!("Type Error: heterogeneous tables are not supported — \
                                nested constructors have conflicting memory shapes.");
                    }
                    Some(_) => {}
                }
            }

            if let Some(ty) = uniform_type {
                return crate::ast::StaticType::Table(Box::new(ty));
            }
        }

        // If child_sites is missing or empty, resolve from the known site type.
        // Handle both Tbl(inner) for constructors and scalar types from IndexAssign propagation.
        match &self.site_elem[id] {
            Tbl(inner) => crate::ast::StaticType::Table(Box::new(self.ty_to_static(inner))),
            Record(fields) => crate::ast::StaticType::Record(
                fields.iter().map(|(name, ty)| (name.clone(), self.ty_to_static(ty))).collect()
            ),
            Int | Pending => crate::ast::StaticType::Integer,
            Flt => crate::ast::StaticType::Float,
            Bool => crate::ast::StaticType::Boolean,
            Str => crate::ast::StaticType::String,
            Conflict => panic!(
                "Type Error: heterogeneous tables are not supported"
            ),
        }
    }

    fn ty_to_static(&self, ty: &Ty) -> crate::ast::StaticType {
        match ty {
            Int => crate::ast::StaticType::Integer,
            Pending => crate::ast::StaticType::Integer,
            Flt => crate::ast::StaticType::Float,
            Bool => crate::ast::StaticType::Boolean,
            Str => crate::ast::StaticType::String,
            Tbl(inner) => crate::ast::StaticType::Table(Box::new(self.ty_to_static(inner))),
            Record(fields) => crate::ast::StaticType::Record(
                fields.iter().map(|(name, ty)| (name.clone(), self.ty_to_static(ty))).collect()
            ),
            Conflict => panic!(
                "Type Error: heterogeneous tables are not supported"
            ),
        }
    }

    fn walk_stmts(&mut self, stmts: &[Stmt]) {
        for s in stmts {
            self.walk_stmt(s);
        }
    }


    fn walk_stmt(&mut self, stmt: &Stmt) {
        match stmt {
            Stmt::LocalDecl { names, exprs } => {
                let mut sets = Vec::with_capacity(names.len());
                for expr in exprs {
                    self.check_uses(expr);
                    if matches!(expr, Expr::Nil) {
                        sets.push(TableShape {
                            ty: Pending,
                            layout: LayoutVerdict::default(),
                            aliases: BTreeSet::from([NULL_ROOT]),
                        });
                    } else {
                        sets.push(self.infer_bind(expr));
                    }
                }
                while sets.len() < names.len() {
                    sets.push(TableShape {
                        ty: Pending,
                        layout: LayoutVerdict::default(),
                        aliases: BTreeSet::from([NULL_ROOT]),
                    });
                }

                // Only set initial bindings; preserve later updates from IndexAssign.
                for (name, set) in names.iter().zip(sets) {
                    let scope = self.scopes.last_mut().unwrap();
                    scope.entry(name.clone()).or_insert(set);
                }
            }

            Stmt::Assignment { name, expr } => {
                if matches!(expr, Expr::Nil) {
                    self.drop_reference(name, stmt);
                    return;
                }
                self.check_uses(expr);
                let bind = self.infer_bind(expr);

                if matches!(bind.ty, Tbl(_)) {
                    let mut incoming = Pending;
                    for s in &bind.aliases {
                        if *s != NULL_ROOT {
                            incoming = join_ty(&incoming, &self.site_elem[*s]);
                        }
                    }
                    if scalar(&incoming) {
                        let old = self.resolve_aliases(name);
                        for s in old {
                            if s != NULL_ROOT {
                                self.decide(s, &incoming);
                            }
                        }
                    }
                }

                for scope in self.scopes.iter_mut().rev() {
                    if scope.contains_key(name) {
                        scope.insert(name.clone(), bind);
                        return;
                    }
                }
                panic!("Scope Error: assignment to undeclared variable '{}'", name);
            }

            Stmt::IndexAssign { obj, key, value } => {
                let (t, _) = self.infer_expr(obj);
                self.infer_expr(key);
                self.check_table_use(obj);
                self.check_uses(obj);
                self.check_uses(key);

                let (vt, _) = self.infer_expr(value);

                let mut base_obj = obj;
                let mut expected_ty = vt.clone();

                while let Expr::Index { obj: parent_obj, .. } = base_obj {
                    expected_ty = Tbl(Box::new(expected_ty));
                    base_obj = parent_obj.as_ref();
                }

                let (_, base_sites) = self.infer_expr(base_obj);

                if matches!(t, Tbl(_) | Pending) {
                    for s in &base_sites {
                        if *s != NULL_ROOT {
                            self.decide(*s, &expected_ty);
                        }
                    }
                }

                if self.recording {
                    self.check_key_threshold(key, &base_sites);
                }
            }

            Stmt::While { condition, body } => {
                self.infer_expr(condition);
                self.check_uses(condition);

                if self.recording
                    && let Some(guard) = extract_guard(condition)
                {
                    self.detect_fill_loop(guard, body);
                }

                let entry = self.scopes.clone();
                let mut head = entry.clone();
                loop {
                    self.scopes = head.clone();
                    self.check_uses(condition);
                    self.scopes.push(HashMap::new());
                    self.walk_stmts(body);
                    self.scopes.pop();
                    let latch = self.scopes.clone();
                    let mut merged = entry.clone();
                    merge_table_scopes(&mut merged, &head, &latch);
                    if merged == head {
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
                self.infer_expr(condition);
                self.check_uses(condition);
                let snapshot = self.scopes.clone();
                self.scopes.push(HashMap::new());
                self.walk_stmts(then_body);
                self.scopes.pop();
                let then_exit = self.scopes.clone();
                self.scopes = snapshot;
                self.scopes.push(HashMap::new());
                self.walk_stmts(else_body);
                self.scopes.pop();
                let else_exit = self.scopes.clone();
                merge_table_scopes(&mut self.scopes, &then_exit, &else_exit);
            }

            Stmt::Do { body } => {
                self.scopes.push(HashMap::new());
                self.walk_stmts(body);
                self.scopes.pop();
            }

            Stmt::Print { exprs } => {
                for e in exprs {
                    self.infer_expr(e);
                    self.check_uses(e);
                }
            }
        }
    }


    fn infer_bind(&mut self, expr: &Expr) -> TableShape {
        let (ty, aliases) = self.infer_expr(expr);
        TableShape {
            ty,
            layout: LayoutVerdict::default(),
            aliases,
        }
    }


    fn resolve(&self, name: &str) -> (usize, TableShape) {
        for (depth, scope) in self.scopes.iter().enumerate().rev() {
            if let Some(bind) = scope.get(name) {
                return (depth, bind.clone());
            }
        }
        panic!("Scope Error: reference to undeclared variable '{}'", name);
    }

        fn resolve_aliases(&self, name: &str) -> BTreeSet<usize> {
        self.resolve(name).1.aliases
    }


    fn decide(&mut self, site: usize, vt: &Ty) {
        // Already in final state — don't re-trigger changed.
        if self.site_elem[site] == Conflict {
            return;
        }

        // Use join_ty instead of brittle != checks to cleanly absorb Pending types.
        let joined = join_ty(&self.site_elem[site], vt);
        if self.site_elem[site] != joined {
            self.site_elem[site] = joined.clone();
            self.changed = true;
        }
        // Propagate decided type to scope entries for all aliases.
        // Reconstruct the full table type before assigning to the scope variable,
        // since site_elem stores the element type but scopes track the variable type.
        let expected_var_ty = Tbl(Box::new(self.site_elem[site].clone()));

        for scope in &mut self.scopes {
            for ts in scope.values_mut() {
                if ts.aliases.contains(&site) && site != NULL_ROOT
                    && (ts.ty == Pending || ts.ty != expected_var_ty)
                {
                    ts.ty = expected_var_ty.clone();
                    if ts.ty != Pending {
                        self.changed = true;
                    }
                }
            }
        }
    }
    fn infer_expr(&mut self, expr: &Expr) -> (Ty, BTreeSet<usize>) {
        match expr {
            Expr::Integer(_) => (Int, BTreeSet::new()),
            Expr::Float(_) => (Flt, BTreeSet::new()),
            Expr::Boolean(_) => (Bool, BTreeSet::new()),
            Expr::String(_) => (Str, BTreeSet::new()),
            Expr::Nil => (Conflict, BTreeSet::new()),
            Expr::TableCtor(elems) => {
                let id = self.sites[&(expr as *const Expr)];
                let mut first_elem_ty: Option<Ty> = None;
                for e in elems {
                    let (t, _) = self.infer_expr(e);
                    if matches!(t, Tbl(_)) {
                        // FIX: Only insert into child_sites if it is actually a Table constructor AST node
                        if let Some(&child_site) = self.sites.get(&(e as *const Expr)) {
                            self.child_sites.entry(id).or_default().insert(child_site);
                        }
                    }
                    // Validate constructor homogeneity: first element sets the expected type.
                    match first_elem_ty {
                        None => first_elem_ty = Some(t.clone()),
                        Some(ref expected) if *expected != t => {
                            if self.site_elem[id] != Conflict {
                                self.site_elem[id] = Conflict;
                                self.changed = true;
                            }
                        }
                        Some(_) => {} // matches — continue
                    }
                    self.decide(id, &t);
                }
                // Use the resolved site type if available, otherwise fall back to first element.
                let resolved = if self.site_elem[id] != Pending {
                    self.site_elem[id].clone()
                } else {
                    first_elem_ty.unwrap_or(Pending)
                };
                (Tbl(Box::new(resolved)), BTreeSet::from([id]))
            }
            Expr::RecordCtor(fields) => {
                let id = self.sites[&(expr as *const Expr)];
                let mut record_ty: Vec<(String, Ty)> = Vec::with_capacity(fields.len());
                for (name, val_expr) in fields {
                    let (t, _) = self.infer_expr(val_expr);
                    // Track child constructors for nested tables within records
                    if matches!(t, Tbl(_))
                        && let Some(&child_site) = self.sites.get(&(val_expr as *const Expr))
                    {
                        self.child_sites.entry(id).or_default().insert(child_site);
                    }
                    record_ty.push((name.clone(), t));
                }
                // Set the site element type so elem_type_of_tbl returns StaticType::Record
                self.site_elem[id] = Record(record_ty.clone());
                (Record(record_ty), BTreeSet::from([id]))
            }
            Expr::Index { obj, key } => {
                let (kt, _) = self.infer_expr(key);
                if matches!(kt, Flt | Bool | Str) {
                    self.infer_expr(obj);
                    return (Conflict, BTreeSet::new());
                }
                let (t, sites) = self.infer_expr(obj);
                if !matches!(t, Tbl(_) | Record(_)) {
                    return (Conflict, BTreeSet::new());
                }
                let mut r = Pending;
                for s in &sites {
                    if *s != NULL_ROOT {
                        self.needed[*s] = true;
                        r = join_ty(&r, &self.site_elem[*s]);
                    }
                }
                (r, BTreeSet::new())
            }
            Expr::Identifier(name) => {
                let (depth, bind) = self.resolve(name);
                let _ = depth;
                (bind.ty, bind.aliases.clone())
            }
            Expr::BinaryOp { op, left, right } => {
                let (lt, _) = self.infer_expr(left);
                let (rt, _) = self.infer_expr(right);
                match op {
                    BinOp::Add
                    | BinOp::Sub
                    | BinOp::Mul
                    | BinOp::Div
                    | BinOp::IntDiv
                    | BinOp::Mod => (arith_ty(lt, rt), BTreeSet::new()),
                    _ => (Bool, BTreeSet::new()),
                }
            }
            Expr::UnaryOp { op, expr } => {
                let (t, _) = self.infer_expr(expr);
                match op {
                    UnOp::Neg => (t, BTreeSet::new()),
                    UnOp::Not => (Bool, BTreeSet::new()),
                    UnOp::Len => (Int, BTreeSet::new()),
                }
            }
            Expr::SysAllocCount => (Int, BTreeSet::new()),
        }
    }


    fn drop_reference(&mut self, name: &str, stmt: &Stmt) {
        let (depth, bind) = self.resolve(name);
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
        }
        self.scopes[depth].insert(
            name.to_string(),
            TableShape {
                ty: Pending,
                layout: LayoutVerdict::default(),
                aliases: BTreeSet::from([NULL_ROOT]),
            },
        );
    }


    fn check_table_use(&mut self, obj: &Expr) {
        if let Expr::Identifier(name) = obj {
            let (_, bind) = self.resolve(name);
            if bind.aliases.contains(&NULL_ROOT) && self.recording {
                panic!(
                    "Lifetime Error: '{name}' may be nil here — table reads, stores, and \
                     '#' through a possibly-nil name are rejected at compile time"
                );
            }
        }
    }


    fn check_uses(&mut self, expr: &Expr) {
        match expr {
            Expr::TableCtor(elems) => {
                for e in elems {
                    self.check_uses(e);
                }
            }
            Expr::RecordCtor(fields) => {
                for (_, val) in fields {
                    self.check_uses(val);
                }
            }
            Expr::Index { obj, key } => {
                self.check_table_use(obj);
                self.check_uses(obj);
                self.check_uses(key);
            }
            Expr::UnaryOp { op, expr } => {
                if matches!(op, UnOp::Len) {
                    self.check_table_use(expr);
                }
                self.check_uses(expr);
            }
            Expr::BinaryOp { left, right, .. } => {
                self.check_uses(left);
                self.check_uses(right);
            }
            _ => {}
        }
    }


            fn check_key_threshold(&mut self, key: &Expr, sites: &BTreeSet<usize>) {
        if let Expr::Integer(i) = key {
            if *i >= BOUNDS_FAIL_THRESHOLD {
                panic!("table index overflow");
            }
            if *i > SPARSE_THRESHOLD {
                for &site in sites {
                    if site != NULL_ROOT {
                        self.verdicts[site] = self.verdicts[site].join(LayoutVerdict::Sparse);
                    }
                }
            }
            let _ = i;
        }
    }


    fn detect_fill_loop(&mut self, guard: &str, body: &[Stmt]) {
        let mutated = self.collect_mutated_names(body);
        let mut fills = BTreeSet::new();

        // Recursive helper to find fills even inside nested if/do/while blocks.
        // Uses get_base_identifier to unwrap chains like t[i][j] → "t".
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
                    mutated.insert(name.clone());
                }
                Stmt::While { .. } => {}
                Stmt::Do { .. } => {}
                Stmt::If {
                    then_body,
                    else_body,
                    ..
                } => {
                    for ss in then_body {
                        if let Stmt::Assignment { name, .. } = ss {
                            mutated.insert(name.clone());
                        }
                    }
                    for ss in else_body {
                        if let Stmt::Assignment { name, .. } = ss {
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


fn extract_guard(condition: &Expr) -> Option<&str> {
    if let Expr::BinaryOp {
        op: BinOp::LessThan,
        left,
        ..
    } = condition
    {
        if let Expr::Identifier(name) = left.as_ref() {
            Some(name.as_str())
        } else {
            None
        }
    } else {
        None
    }
}
