// src/shape/helpers.rs
use std::collections::BTreeMap;
use crate::ast::{BinOp, Expr};
use super::core::TableShape;

pub fn extract_guard(condition: &Expr) -> Option<&str> {
    if let Expr::BinaryOp { op: BinOp::LessThan, left, .. } = condition {
        if let Expr::Identifier(name) = left.as_ref() {
            Some(name.as_str())
        } else {
            None
        }
    } else {
        None
    }
}

pub fn merge_table_scopes(
    into: &mut [BTreeMap<String, TableShape>],
    a: &[BTreeMap<String, TableShape>],
    b: &[BTreeMap<String, TableShape>],
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
