use crate::ast::{BinOp, Expr, StaticType, Stmt, UnOp};
use crate::shape::ShapeFacts;
use glm_rt::{signal, trace};
use std::collections::BTreeMap;

/// Type-variable ids for `local x` with no initializer: a nil-valued name
/// whose first assignment unifies with anything. Each bare declaration
/// takes a fresh id counting down from usize::MAX (real site ids count up
/// from 0), so two bare locals never share a substitution slot.
const BARE_LOCAL_MAX: usize = usize::MAX;

pub struct TypeChecker<'a> {
    scopes: Vec<BTreeMap<String, StaticType>>,
    shape: &'a mut ShapeFacts,
    substitutions: BTreeMap<usize, StaticType>,
    bare_next: usize,
}

impl<'a> TypeChecker<'a> {
    pub fn new(shape: &'a mut ShapeFacts) -> Self {
        Self {
            scopes: vec![BTreeMap::new()],
            shape,
            substitutions: BTreeMap::new(),
            bare_next: BARE_LOCAL_MAX,
        }
    }

    pub fn check_program(&mut self, stmts: &[Stmt]) {
        // Checker pokes carry no scope context: the scope register belongs
        // to the shape analyzer's recording walk (ids in first-visit
        // order), and the checker's independent walk would misattribute
        // cells to those ids. 0xFF = "no scope" reads cleanly in plate.py.
        trace::compiler_trace_current_scope(
            trace::TRACE_SCOPE_PARENT_NONE,
            0,
            trace::TRACE_SCOPE_PARENT_NONE,
        );
        self.check_block(stmts);
        // Apply substitution bindings to all variable scopes so that
        // var_type() always returns fully-resolved types for the lowerer.
        self.resolve_all_scopes();
    }

    /// The ghost-run boundary, mirroring the shape analyzer's
    /// `walk_stmts`: one statement's failure poisons only the block that
    /// contains it. The error is ledgered (GHOST_BAIL fires on the
    /// plate), the rest of this slice is skipped, and the enclosing walk
    /// resumes with the next sibling — the scope bracket in the parent
    /// statement (begin_scope/end_scope around this call) stays balanced
    /// because we return normally. Message texts are corpus-pinned:
    /// negative cases grep them on stderr, so keep the prefix verbatim.
    fn check_block(&mut self, stmts: &[Stmt]) {
        for stmt in stmts {
            if let Err(msg) = self.check_stmt(stmt) {
                // Dedicated slot (the shape analyzer owns TRACE_GHOST_BAIL):
                // the plate must name WHICH pass poisoned the block.
                signal!(trace::TRACE_GHOST_BAIL_CHECKER);
                self.shape.diagnostics.push(msg);
                return;
            }
        }
    }

    fn resolve_all_scopes(&mut self) {
        // Flush substitutions back to ShapeFacts so the lowerer can resolve
        // Unknown types via elem_of().
        for (id, ty) in &self.substitutions {
            self.shape.substitutions.insert(*id, ty.clone());
        }
        // Collect resolved types to avoid borrow checker issues.
        let mut resolved: Vec<(String, StaticType)> = Vec::new();
        for scope in &self.scopes {
            for (name, ty) in scope {
                resolved.push((name.clone(), self.resolve_var(ty)));
            }
        }
        // Reassign resolved types back.
        for (name, ty) in resolved {
            for scope in &mut self.scopes {
                if scope.contains_key(&name) {
                    scope.insert(name.clone(), ty.clone());
                }
            }
        }
    }

    fn begin_scope(&mut self) {
        self.scopes.push(BTreeMap::new());
    }
    fn end_scope(&mut self) {
        self.scopes.pop().expect("Cannot pop global scope");
    }

    fn declare_var(&mut self, name: String, ty: StaticType) -> Result<(), String> {
        let current_scope = self.scopes.last_mut().unwrap();
        if current_scope.contains_key(&name) {
            return Err(format!("Variable '{}' already declared in this scope", name));
        }
        current_scope.insert(name, ty);
        Ok(())
    }

    fn var_type(&self, name: &str) -> Result<StaticType, String> {
        for scope in self.scopes.iter().rev() {
            if let Some(ty) = scope.get(name) {
                return Ok(self.resolve_var(ty));
            }
        }
        Err(format!("Undeclared variable: '{}'", name))
    }

    fn check_stmt(&mut self, stmt: &Stmt) -> Result<(), String> {
        match stmt {
            Stmt::LocalDecl { names, exprs } => {
                let mut expr_types = Vec::with_capacity(exprs.len());
                for expr in exprs {
                    expr_types.push(self.check_expr(expr)?);
                }
                for (name, ty) in names.iter().zip(expr_types) {
                    self.declare_var(name.clone(), ty)?;
                }
                // `local x` without initializer: declare the name so it
                // stops falling out of the zip above. The shape layer
                // already models it as a nil-valued binding (Pending,
                // NULL_ROOT alias); here it gets its own bare-local
                // Unknown — the first assignment unifies with any type.
                for name in &names[exprs.len()..] {
                    let id = self.bare_next;
                    self.bare_next -= 1;
                    self.declare_var(name.clone(), StaticType::Unknown(id))?;
                }
            }
            Stmt::Assignment { name, expr } => {
                let expected = self.var_type(name)?;
                if matches!(expr, Expr::Nil) {
                    // [Lifecycle Parity Strike] Records are heap GlmTables
                    // exactly like tables, so they are valid nil-release
                    // targets: the shape layer's sole-ownership proof and
                    // the lowerer's TableFree emission are type-agnostic.
                    // A bare local (unbound Unknown) holds nil already —
                    // releasing it is a no-op, not a type error.
                    if !matches!(
                        expected,
                        StaticType::Table(_) | StaticType::Record(_) | StaticType::Unknown(_)
                    ) {
                        return Err(format!(
                            "Type Error: 'nil' releases tables — '{}' is a {}",
                            name,
                            type_name(&expected)
                        ));
                    }
                    return Ok(());
                }
                let actual = self.check_expr(expr)?;
                if expected != actual {
                    // Reject reassigning an empty table constructor to a
                    // variable that was initialized with concrete content.
                    // Empty constructors produce Unknown types which only
                    // participate in unification through element access.
                    if is_empty_table_constructor(expr) {
                        return Err(format!(
                            "Type Error: cannot assign {} to variable '{}' of type {}",
                            type_name(&actual),
                            name,
                            type_name(&expected)
                        ));
                    }
                    // Use unification to resolve any Unknown type variables.
                    self.unify(&expected, &actual)?;
                    // Store the resolved type back into the scope.
                    let resolved = self.resolve_var(&actual);
                    for scope in self.scopes.iter_mut().rev() {
                        if scope.contains_key(name) {
                            scope.insert(name.clone(), resolved);
                            break;
                        }
                    }
                }
            }
            Stmt::IndexAssign { obj, key, value } => {
                let (elem, _obj_desc) = self.check_index_base(obj)?;
                let key_ty = self.check_expr(key)?;
                if key_ty != StaticType::Integer {
                    return Err(format!(
                        "Type Error: table index must be an Integer, got {}",
                        type_name(&key_ty)
                    ));
                }

                let val_ty = self.check_expr(value)?;

                // Strict monomorphism: nested table element types must match recursively.
                if matches!(elem, StaticType::Table(_)) && matches!(val_ty, StaticType::Table(_)) {
                    let expected_inner = match &elem {
                        StaticType::Table(inner) => inner.as_ref(),
                        _ => unreachable!(),
                    };
                    let actual_inner = match &val_ty {
                        StaticType::Table(inner) => inner.as_ref(),
                        _ => unreachable!(),
                    };
                    self.unify(expected_inner, actual_inner)?;
                } else {
                    // Both are non-table types, or there's a scalar vs table conflict
                    // Unify will naturally typecheck them or return a clean type conflict error.
                    self.unify(&elem, &val_ty)?;
                }
            }
            Stmt::While { condition, body } => {
                self.check_condition(condition, "while")?;
                self.begin_scope();
                self.check_block(body);
                self.end_scope();
            }
            Stmt::If {
                condition,
                then_body,
                else_body,
            } => {
                self.check_condition(condition, "if")?;
                self.begin_scope();
                self.check_block(then_body);
                self.end_scope();
                self.begin_scope();
                self.check_block(else_body);
                self.end_scope();
            }
            Stmt::Do { body } => {
                self.begin_scope();
                self.check_block(body);
                self.end_scope();
            }
            Stmt::Print { exprs } => {
                for e in exprs {
                    let ty = self.check_expr(e)?;
                    // BS-6 marker: a record passes this gate (only Table is
                    // rejected here) and dies later at IR generation.
                    if matches!(ty, StaticType::Record(_)) {
                        signal!(trace::TRACE_CHK_PRINT_REC);
                    }
                    if matches!(ty, StaticType::Table(_)) {
                        return Err(
                            "Type Error: cannot print a table — print its cells or '#t' instead"
                                .to_string(),
                        );
                    }
                }
            }
        }
        Ok(())
    }

    fn check_index_base(&mut self, obj: &Expr) -> Result<(StaticType, String), String> {
        let ty = self.check_expr(obj)?;
        match ty {
            StaticType::Table(elem) => {
                let desc = type_name(&StaticType::Table(elem.clone()));
                Ok((*elem, desc))
            }
            StaticType::Record(fields) => {
                // Records are stored as tables internally — field 0 = first value, etc.
                // Element type is the first field's type.
                // BS-5 marker: every record index (read AND write) is checked
                // against field 0's type — the hole that lets a field-0-typed
                // value compile into any slot.
                signal!(trace::TRACE_CHK_IDX_REC_FIELD0);
                let first_ty = fields.first().map(|(_, ty)| ty.clone())
                    .unwrap_or(StaticType::Integer);
                let desc = type_name(&StaticType::Table(Box::new(first_ty.clone())));
                Ok((first_ty, desc))
            }
            _ => Err(format!(
                "Type Error: cannot index {} — only tables support '[]'",
                type_name(&ty)
            )),
        }
    }

    fn check_condition(&mut self, condition: &Expr, kw: &str) -> Result<(), String> {
        let ty = self.check_expr(condition)?;
        if ty != StaticType::Boolean {
            return Err(format!(
                "Type Error: '{}' condition must be a Boolean, got {}",
                kw,
                type_name(&ty)
            ));
        }
        Ok(())
    }

    fn check_expr(&mut self, expr: &Expr) -> Result<StaticType, String> {
        match expr {
            Expr::Integer(_) => Ok(StaticType::Integer),
            Expr::Float(_) => Ok(StaticType::Float),
            Expr::Boolean(_) => Ok(StaticType::Boolean),
            Expr::String(_) => Ok(StaticType::String),
            Expr::Nil => {
                // nil in expression position: poked before the rejection so
                // the plate maps every nil-value reach, not just the first.
                signal!(trace::TRACE_CHK_NIL_EXPR);
                Err(
                    "Type Error: 'nil' is only valid as the right-hand side of 't = nil' — \
                     it releases a table's memory, it is not a value"
                        .to_string(),
                )
            }
            Expr::TableCtor(elems) => {
                let elem = self.shape.elem_of(expr);
                for e in elems {
                    let ty = self.check_expr(e)?;
                    // Allow nested table types — the runtime supports deep-free.
                    if matches!(elem, StaticType::Table(_)) && matches!(ty, StaticType::Table(_)) {
                        // Both are tables — compare their resolved inner types.
                        let expected_inner = match &elem {
                            StaticType::Table(inner) => inner.as_ref(),
                            _ => unreachable!(),
                        };
                        let actual_inner = match &ty {
                            StaticType::Table(inner) => inner.as_ref(),
                            _ => unreachable!(),
                        };
                        if expected_inner != actual_inner {
                            self.unify(expected_inner, actual_inner)?;
                        }
                    } else if ty != elem {
                        return Err(format!(
                            "Type Error: mixed table constructor elements — {} after {}",
                            type_name(&ty),
                            type_name(&elem)
                        ));
                    }
                }
                Ok(StaticType::Table(Box::new(elem)))
            }
            Expr::RecordCtor(fields) => {
                let mut record_types: Vec<(String, StaticType)> = Vec::with_capacity(fields.len());
                for (name, val_expr) in fields.iter() {
                    let val_ty = self.check_expr(val_expr)?;
                    record_types.push((name.to_string(), val_ty));
                }
                Ok(StaticType::Record(record_types))
            }
            Expr::Index { obj, key } => {
                let (elem, _) = self.check_index_base(obj)?;
                let key_ty = self.check_expr(key)?;
                if key_ty != StaticType::Integer {
                    return Err(format!(
                        "Type Error: table index must be an Integer, got {}",
                        type_name(&key_ty)
                    ));
                }
                Ok(elem)
            }
            Expr::Identifier(name) => self.var_type(name),
            Expr::BinaryOp { op, left, right } => {
                let l = self.check_expr(left)?;
                let r = self.check_expr(right)?;
                match op {
                    BinOp::And | BinOp::Or => {
                        if l == StaticType::Boolean && r == StaticType::Boolean {
                            Ok(StaticType::Boolean)
                        } else {
                            Err(format!(
                                "Type Error: '{}' requires Boolean operands on both sides",
                                match op {
                                    BinOp::And => "and",
                                    _ => "or",
                                }
                            ))
                        }
                    }
                    BinOp::Add
                    | BinOp::Sub
                    | BinOp::Mul
                    | BinOp::Div
                    | BinOp::IntDiv
                    | BinOp::Mod => self.numeric_operand(&l, &r, op),
                    BinOp::LessThan | BinOp::GreaterThan | BinOp::LessEq | BinOp::GreaterEq => {
                        self.numeric_operand(&l, &r, op)?;
                        Ok(StaticType::Boolean)
                    }
                    BinOp::Equal | BinOp::NotEqual => {
                        if l == StaticType::String || r == StaticType::String {
                            return Err("Type Error: String comparison is not supported yet".to_string());
                        }
                        // C.4 marker: record == record passes compatibility
                        // here, then the backend compares the registers as
                        // i64 while they hold ptr — clang rejects.
                        if matches!(l, StaticType::Record(_)) && matches!(r, StaticType::Record(_)) {
                            signal!(trace::TRACE_CHK_REC_EQ);
                        }
                        if !types_compatible(&l, &r) {
                            return Err(format!(
                                "Type Error: '{}' compares {} with {}",
                                match op {
                                    BinOp::Equal => "==",
                                    _ => "~=",
                                },
                                type_name(&l),
                                type_name(&r)
                            ));
                        }
                        Ok(StaticType::Boolean)
                    }
                }
            }
            Expr::UnaryOp { op, expr } => {
                let t = self.check_expr(expr)?;
                match op {
                    UnOp::Neg => match t {
                        StaticType::Integer | StaticType::Float => Ok(t),
                        _ => Err("Type Error: unary '-' requires a numeric operand".to_string()),
                    },
                    UnOp::Not => match t {
                        StaticType::Boolean => Ok(StaticType::Boolean),
                        _ => Err("Type Error: 'not' requires a Boolean operand".to_string()),
                    },
                    UnOp::Len => match self.resolve_var(&t) {
                        StaticType::Table(_) => Ok(StaticType::Integer),
                        _ => Err(format!(
                            "Type Error: '#' requires a table operand, got {}",
                            type_name(&t)
                        )),
                    },
                }
            }
            Expr::SysAllocCount => Ok(StaticType::Integer),
        }
    }

    fn numeric_operand(
        &self,
        l: &StaticType,
        r: &StaticType,
        op: &BinOp,
    ) -> Result<StaticType, String> {
        match (l, r) {
            (StaticType::Integer, StaticType::Integer) => Ok(StaticType::Integer),
            (StaticType::Float, StaticType::Float) => Ok(StaticType::Float),
            (StaticType::Integer, StaticType::Float) | (StaticType::Float, StaticType::Integer) => {
                Err(format!(
                    "Type Error: '{}' does not support mixed Integer and Float operands",
                    bin_op_name(op)
                ))
            }
            _ => Err(format!(
                "Type Error: '{}' requires numeric operands",
                bin_op_name(op)
            )),
        }
    }
}

// ---------------------------------------------------------------------------
// Type Unification Engine
// ---------------------------------------------------------------------------

impl<'a> TypeChecker<'a> {
    fn resolve_var(&self, ty: &StaticType) -> StaticType {
        match ty {
            StaticType::Unknown(id) => match self.substitutions.get(id) {
                Some(resolved) => self.resolve_var(resolved),
                None => ty.clone(),
            },
            StaticType::Table(inner) => {
                StaticType::Table(Box::new(self.resolve_var(inner)))
            }
            StaticType::Record(fields) => StaticType::Record(
                fields.iter().map(|(name, ty)| (name.clone(), self.resolve_var(ty))).collect()
            ),
            other => other.clone(),
        }
    }

    fn unify(&mut self, expected: &StaticType, actual: &StaticType) -> Result<(), String> {
        match (expected, actual) {
            // Same type — trivially unify.
            (a, b) if a == b => Ok(()),

            // Both Unknown — bind the second to the first (if different IDs).
            (StaticType::Unknown(id_a), StaticType::Unknown(id_b)) if id_a != id_b => {
                signal!(trace::TRACE_CHK_UNIFY);
                self.substitutions
                    .insert(*id_b, StaticType::Unknown(*id_a));
                Ok(())
            }

            // Bind the Unknown to the concrete type.
            (StaticType::Unknown(_), _) | (_, StaticType::Unknown(_)) => {
                signal!(trace::TRACE_CHK_UNIFY);
                let (u_id, c_ty) = match (expected, actual) {
                    (StaticType::Unknown(id), ty) => (*id, ty.clone()),
                    (ty, StaticType::Unknown(id)) => (*id, ty.clone()),
                    _ => unreachable!(),
                };
                self.substitutions.insert(u_id, c_ty);
                Ok(())
            }

            // Both tables — recursively unify element types.
            (StaticType::Table(e1), StaticType::Table(e2)) => {
                let e1 = self.resolve_var(e1);
                let e2 = self.resolve_var(e2);
                self.unify(&e1, &e2)
            }

            // Type conflict.
            _ => Err(format!(
                "Type Error: type conflict — {} vs {}",
                type_name(expected),
                type_name(actual)
            )),
        }
    }
}

fn is_empty_table_constructor(expr: &Expr) -> bool {
    matches!(expr, Expr::TableCtor(elems) if elems.is_empty())
}

fn types_compatible(l: &StaticType, r: &StaticType) -> bool {
    match (l, r) {
        (a, b) if a == b => true,
        // Two Unknowns are always compatible (they may unify).
        (StaticType::Unknown(_), StaticType::Unknown(_)) => true,
        // Unknown is compatible with any concrete type.
        (StaticType::Unknown(_), _) | (_, StaticType::Unknown(_)) => true,
        // Two tables are compatible if their inner element types are compatible.
        (StaticType::Table(e1), StaticType::Table(e2)) => types_compatible(e1, e2),
        // Two records are compatible if their inner field types are compatible.
        (StaticType::Record(f1), StaticType::Record(f2)) => types_compatible_records(f1, f2),
        // Everything else is a conflict.
        _ => false,
    }
}

fn types_compatible_records(f1: &[(String, StaticType)], f2: &[(String, StaticType)]) -> bool {
    if f1.len() != f2.len() {
        return false;
    }
    for (name1, ty1) in f1 {
        if let Some((_, ty2)) = f2.iter().find(|(n, _)| n == name1) {
            if !types_compatible(ty1, ty2) {
                return false;
            }
        } else {
            return false;
        }
    }
    true
}

fn type_name(ty: &StaticType) -> String {
    match ty {
        StaticType::Integer => "Integer".to_string(),
        StaticType::Float => "Float".to_string(),
        StaticType::Boolean => "Boolean".to_string(),
        StaticType::String => "String".to_string(),
            StaticType::Table(elem) => match **elem {
                StaticType::Integer => "IntTable".to_string(),
                StaticType::Float => "FloatTable".to_string(),
                StaticType::Boolean => "BoolTable".to_string(),
                StaticType::String => "StringTable".to_string(),
                StaticType::Unknown(_) => "Table<?>".to_string(),
                _ => format!("Table of {}", type_name(elem)),
            },
            StaticType::Record(fields) => {
                let parts: Vec<String> = fields.iter()
                    .map(|(name, ty)| format!("{}:{}", name, type_name(ty)))
                    .collect();
                format!("Record<{}>", parts.join(", "))
            }
        StaticType::Unknown(_) => "?".to_string(),
    }
}

fn bin_op_name(op: &BinOp) -> &'static str {
    match op {
        BinOp::Add => "+",
        BinOp::Sub => "-",
        BinOp::Mul => "*",
        BinOp::Div => "/",
        BinOp::IntDiv => "//",
        BinOp::Mod => "%",
        BinOp::LessThan => "<",
        BinOp::GreaterThan => ">",
        BinOp::LessEq => "<=",
        BinOp::GreaterEq => ">=",
        BinOp::Equal => "==",
        BinOp::NotEqual => "~=",
        BinOp::And => "and",
        BinOp::Or => "or",
    }
}
