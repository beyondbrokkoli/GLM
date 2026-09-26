// src/shape/facts.rs
use std::collections::{BTreeMap, BTreeSet};
use crate::ast::{Expr, Stmt, StaticType};
use super::core::LayoutVerdict;

/// One do-exit free handed from the analyzer to the lowerer: the dying
/// heap site plus a carrier name (the first dying binding, deterministic
/// BTreeMap order) that still holds it. The lowerer picks the register:
/// the site's TableNew defining register when the ctor dominates the
/// exit, otherwise the carrier's join register.
#[derive(Clone)]
pub struct DoExitFree {
    pub site: usize,
    pub carrier: String,
}

pub struct ShapeFacts {
    pub sites: BTreeMap<*const Expr, usize>,
    pub elems: Vec<StaticType>,
    #[allow(dead_code)]
    pub layouts: Vec<LayoutVerdict>,
    pub free_sites: BTreeSet<*const Stmt>,
    /// Do-exit ownership decisions, keyed by the `Stmt::Do` node: ONE
    /// entry per heap site proved solely owned by the dying block,
    /// however many dying names alias it. The analyzer owns the proof,
    /// the lowerer owns the emission (per site, never per name — a
    /// name whose binding is an if-join over several sites is ONE
    /// runtime register and must not be freed once per site).
    pub do_exit_frees: BTreeMap<*const Stmt, Vec<DoExitFree>>,
    pub name_dense: BTreeMap<(String, usize), bool>,
    /// Heap sites of tables that received a *syntactically inline*
    /// `Expr::TableCtor` through a direct `obj[key] = {...}` store on an
    /// identifier. The row has no binding of its own, so only the
    /// parent's deep-free flag (TableNew bit 7) can own it — the lowerer
    /// reads this set when lowering the parent's constructor. Named rows
    /// (`m[0] = row`) never land here: they own themselves via their own
    /// binding, and a parent flag would double-free (the BS-11 trap).
    /// Nested targets (`m[0][1] = {...}`) stay unmarked too — the cell
    /// may hold a named row; their leak stays bounded and documented.
    pub stored_ctor_parents: BTreeSet<usize>,
    pub substitutions: BTreeMap<usize, StaticType>,
    /// Localized shape errors from the ghost run: the walk completed and
    /// the plate is whole, but these blocks were poisoned and skipped.
    /// Non-empty means the compile must fail; the driver reports them.
    pub diagnostics: Vec<String>,
}

impl ShapeFacts {
    pub fn elem_of(&self, ctor: &Expr) -> StaticType {
        let id = self.sites[&(ctor as *const Expr)];
        let elem = self.elems[id].clone();
        self.resolve_elem_type(elem)
    }

    fn resolve_elem_type(&self, ty: StaticType) -> StaticType {
        match &ty {
            StaticType::Unknown(id) => self.substitutions.get(id).cloned().unwrap_or(ty),
            StaticType::Table(inner) => {
                let resolved = self.resolve_elem_type((**inner).clone());
                StaticType::Table(Box::new(resolved))
            }
            _ => ty,
        }
    }

    pub fn is_dense_at_depth(&self, name: &str, depth: usize) -> bool {
        self.name_dense.get(&(name.to_string(), depth)).copied().unwrap_or(false)
    }

    pub fn is_free(&self, stmt: &Stmt) -> bool {
        self.free_sites.contains(&(stmt as *const Stmt))
    }
}
