// src/shape/facts.rs
use std::collections::{BTreeMap, BTreeSet};
use crate::ast::{Expr, Stmt, StaticType};
use super::core::LayoutVerdict;

pub struct ShapeFacts {
    pub sites: BTreeMap<*const Expr, usize>,
    pub elems: Vec<StaticType>,
    #[allow(dead_code)]
    pub layouts: Vec<LayoutVerdict>,
    pub free_sites: BTreeSet<*const Stmt>,
    pub name_dense: BTreeMap<(String, usize), bool>,
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
