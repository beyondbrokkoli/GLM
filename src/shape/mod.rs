// src/shape/mod.rs
mod core;
mod facts;
mod helpers;
mod ty;
mod analyzer;

pub use self::core::*;
pub use self::facts::*;
// Globs over `helpers`/`ty` keep the external API identical to the
// pre-split monolithic shape.rs; nothing outside the module consumes
// them today, and the bin crate flags unused `pub use`s.
#[allow(unused_imports)]
pub use self::helpers::*;
#[allow(unused_imports)]
pub use self::ty::*;
pub use self::analyzer::analyze;
