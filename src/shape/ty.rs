// src/shape/ty.rs
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

pub fn scalar(t: &Ty) -> bool {
    matches!(t, Int | Flt | Bool | Str)
}

pub fn join_ty(a: &Ty, b: &Ty) -> Ty {
    match (a, b) {
        (Pending, x) | (x, Pending) => x.clone(),
        (Conflict, _) | (_, Conflict) => Conflict,
        (Tbl(inner_a), Tbl(inner_b)) => {
            let merged = join_ty(inner_a, inner_b);
            if merged != Conflict {
                Tbl(Box::new(merged))
            } else {
                Conflict
            }
        }
        (Record(fields_a), Record(fields_b)) => {
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

pub fn arith_ty(a: Ty, b: Ty) -> Ty {
    if a == Pending || b == Pending {
        Pending
    } else if a == b && matches!(a, Int | Flt) {
        a
    } else {
        Conflict
    }
}
