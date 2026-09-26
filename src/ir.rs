
use crate::ast::StaticType;

pub type BlockId = usize;

pub type RegId = u32;

#[derive(Debug, Clone)]
pub enum Terminator {
    Jump(BlockId),
    Branch {
        cond: RegId,
        true_block: BlockId,
        false_block: BlockId,
    },
    Halt,
}

#[derive(Debug, Clone)]
pub enum Instruction {
    LoadInt {
        target: RegId,
        val: i64,
    },
    LoadFloat {
        target: RegId,
        val: f64,
    },
    LoadBool {
        target: RegId,
        val: bool,
    },
    LoadString {
        target: RegId,
        val: String,
    },
    LoadNull {
        target: RegId,
    },
    Move {
        target: RegId,
        source: RegId,
        ty: StaticType,
    },

    TableNew {
        target: RegId,
        elem: StaticType,
        flags: u8,
    },
    TableGet {
        target: RegId,
        table: RegId,
        index: RegId,
        target_ty: StaticType,
    },
    TableReserve {
        table: RegId,
        bound: RegId,
    },
    TableSetFast {
        table: RegId,
        index: RegId,
        value: RegId,
        layout: crate::shape::LayoutVerdict,
    },
    TableSet {
        table: RegId,
        index: RegId,
        value: RegId,
    },
    TableLen {
        target: RegId,
        table: RegId,
    },
    TableFree {
        table: RegId,
    },

    SysAllocCount {
        target: RegId,
    },

    Add {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Sub {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Mul {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Div {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    IntDiv {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Mod {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Neg {
        target: RegId,
        source: RegId,
    },
    Less {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Leq {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Geq {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Eq {
        target: RegId,
        left: RegId,
        right: RegId,
    },
    Not {
        target: RegId,
        source: RegId,
    },

    Phi {
        target: RegId,
        ty: StaticType,
        args: Vec<(BlockId, RegId)>,
    },

    Print {
        operands: Vec<(RegId, StaticType)>,
    },
}

impl Instruction {
    pub fn def_reg(&self) -> Option<RegId> {
        match self {
            Instruction::LoadInt { target, .. }
            | Instruction::LoadFloat { target, .. }
            | Instruction::LoadBool { target, .. }
            | Instruction::LoadString { target, .. }
            | Instruction::LoadNull { target }
            | Instruction::Move { target, .. }
            | Instruction::TableNew { target, .. }
            | Instruction::TableGet { target, .. }
            | Instruction::TableLen { target, .. }
            | Instruction::Add { target, .. }
            | Instruction::Sub { target, .. }
            | Instruction::Mul { target, .. }
            | Instruction::Div { target, .. }
            | Instruction::IntDiv { target, .. }
            | Instruction::Mod { target, .. }
            | Instruction::Neg { target, .. }
            | Instruction::Less { target, .. }
            | Instruction::Leq { target, .. }
            | Instruction::Geq { target, .. }
            | Instruction::Eq { target, .. }
            | Instruction::Not { target, .. }
            | Instruction::Phi { target, .. } => Some(*target),
            Instruction::Print { .. }
            | Instruction::TableReserve { .. }
            | Instruction::TableSetFast { .. }
            | Instruction::TableSet { .. }
            | Instruction::TableFree { .. }
            | Instruction::SysAllocCount { .. } => None,
        }
    }
    pub fn def_type(&self) -> Option<StaticType> {
        match self {
            Instruction::LoadInt { .. }
            | Instruction::Add { .. }
            | Instruction::Sub { .. }
            | Instruction::Mul { .. }
            | Instruction::Div { .. }
            | Instruction::IntDiv { .. }
            | Instruction::Mod { .. }
            | Instruction::Neg { .. } => Some(StaticType::Integer),
            Instruction::TableLen { .. } => Some(StaticType::Integer),
            Instruction::LoadFloat { .. } => Some(StaticType::Float),
            Instruction::LoadString { .. } => Some(StaticType::String),
            Instruction::Less { .. }
            | Instruction::Leq { .. }
            | Instruction::Geq { .. }
            | Instruction::Eq { .. }
            | Instruction::Not { .. }
            | Instruction::LoadBool { .. } => Some(StaticType::Boolean),
            Instruction::TableNew { elem, .. } => {
                Some(StaticType::Table(Box::new(elem.clone())))
            }
            Instruction::Move { ty, .. } | Instruction::Phi { ty, .. } => Some(ty.clone()),
            Instruction::TableGet { target_ty, .. } => Some(target_ty.clone()),
            Instruction::LoadNull { .. } => None,
            Instruction::Print { .. }
            | Instruction::TableReserve { .. }
            | Instruction::TableSetFast { .. }
            | Instruction::TableSet { .. }
            | Instruction::TableFree { .. }
            | Instruction::SysAllocCount { .. } => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct BasicBlock {
    pub id: BlockId,
    pub instrs: Vec<Instruction>,
    pub terminator: Option<Terminator>,
}

impl BasicBlock {
    pub fn new(id: BlockId) -> Self {
        Self {
            id,
            instrs: Vec::new(),
            terminator: None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct IrProgram {
    pub blocks: Vec<BasicBlock>,
}
