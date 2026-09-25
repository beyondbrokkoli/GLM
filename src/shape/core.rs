// src/shape/core.rs
use std::collections::BTreeSet;
use super::ty::{Ty, join_ty};

pub const SPARSE_THRESHOLD: i64 = 100_000;
pub const BOUNDS_FAIL_THRESHOLD: i64 = i64::MAX / 8;
pub const NULL_ROOT: usize = usize::MAX;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub enum LayoutVerdict {
    #[default]
    Dense,
    Growing,
    Sparse,
    BoundsFail,
}

impl LayoutVerdict {
    pub fn join(self, other: LayoutVerdict) -> LayoutVerdict {
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
