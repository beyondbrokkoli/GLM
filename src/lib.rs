// The C-ABI runtime keeps its `# Safety` contracts in docs/rt.txt, not in
// the source — so the in-source safety-doc lint has nothing to check.
#![allow(clippy::missing_safety_doc)]

pub mod rt;
pub mod trace;
