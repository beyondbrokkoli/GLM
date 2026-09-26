// src/analysis.rs
use crate::ast::{Expr, Stmt};
use std::collections::BTreeMap;

pub struct AnalysisContext<'a> {
    pub sites: BTreeMap<*const Expr, usize>,

    // --- Tuning Parameters (Heuristics) ---
    #[allow(dead_code)]
    pub max_flat_cells: usize,
    #[allow(dead_code)]
    pub loop_escalation_weight: u32,

    pub ast: &'a [Stmt],
}

// Add the <'_> so the compiler knows it borrows the AST
pub fn build_context(ast: &[Stmt]) -> AnalysisContext<'_> {
    let mut sites = BTreeMap::new();
    number_sites(ast, &mut sites);

    AnalysisContext {
        sites,
        max_flat_cells: 64,
        loop_escalation_weight: 10,
        ast,
    }
}

pub fn number_sites(stmts: &[Stmt], sites: &mut BTreeMap<*const Expr, usize>) {
    for s in stmts {
        number_stmt(s, sites);
    }
}

fn number_stmt(stmt: &Stmt, sites: &mut BTreeMap<*const Expr, usize>) {
    match stmt {
        Stmt::LocalDecl { exprs, .. } => {
            for e in exprs {
                number_expr(e, sites);
            }
        }
        Stmt::Assignment { expr, .. } => number_expr(expr, sites),
        Stmt::IndexAssign { obj, key, value } => {
            number_expr(obj, sites);
            number_expr(key, sites);
            number_expr(value, sites);
        }
        Stmt::While { condition, body } => {
            number_expr(condition, sites);
            number_sites(body, sites);
        }
        Stmt::Do { body } => {
            number_sites(body, sites);
        }
        Stmt::If {
            condition,
            then_body,
            else_body,
        } => {
            number_expr(condition, sites);
            number_sites(then_body, sites);
            number_sites(else_body, sites);
        }
        Stmt::Print { exprs } => {
            for e in exprs {
                number_expr(e, sites);
            }
        }
    }
}

fn number_expr(expr: &Expr, sites: &mut BTreeMap<*const Expr, usize>) {
    match expr {
        Expr::TableCtor(entries) => {
            let id = sites.len();
            sites.insert(expr as *const Expr, id);
            for (_, val) in entries {
                number_expr(val, sites);
            }
        }
        Expr::SysAllocCount => {}
        Expr::Index { obj, key } => {
            number_expr(obj, sites);
            number_expr(key, sites);
        }
        Expr::BinaryOp { left, right, .. } => {
            number_expr(left, sites);
            number_expr(right, sites);
        }
        Expr::UnaryOp { expr, .. } => number_expr(expr, sites),
        _ => {}
    }
}
