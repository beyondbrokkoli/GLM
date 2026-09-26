
#[derive(Debug, Clone, PartialEq)]
pub enum StaticType {
    Integer,
    Float,
    Boolean,
    String,
    Table(Box<StaticType>),
    Unknown(usize),
}

impl std::fmt::Display for StaticType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            StaticType::Integer => write!(f, "Int"),
            StaticType::Float => write!(f, "Float"),
            StaticType::Boolean => write!(f, "Bool"),
            StaticType::String => write!(f, "String"),
            StaticType::Table(inner) => write!(f, "Table<{}>", inner),
            StaticType::Unknown(_) => write!(f, "?"),
        }
    }
}

#[derive(Debug, Clone)]
pub enum BinOp {
    Add,
    Sub,
    Mul,
    Div,
    IntDiv,
    Mod,
    LessThan,
    GreaterThan,
    LessEq,
    GreaterEq,
    Equal,
    NotEqual,
    And,
    Or,
}

#[derive(Debug, Clone)]
pub enum UnOp {
    Neg,
    Not,
    Len, 
}

#[derive(Debug, Clone)]
pub enum Expr {
    Integer(i64),
    Float(f64),
    Boolean(bool),
    String(String),
    Nil,
    /// Lua-style table constructor. Each entry is a resolved
    /// `(slot, value)` pair: positional entries take slots 0..n-1 in
    /// source order (glm's 0-indexed dialect), `{[k] = v}` entries take
    /// their constant integer slot. The parser rejects duplicate slots
    /// (no last-wins) and every non-constant or named key, so the slots
    /// here are unique and the emission order is the source order.
    /// Empty (`{}`) stays the Pending first-touch root.
    TableCtor(Vec<(i64, Expr)>),
    Identifier(String),
    Index {
        obj: Box<Expr>,
        key: Box<Expr>,
    },
    BinaryOp {
        op: BinOp,
        left: Box<Expr>,
        right: Box<Expr>,
    },
    UnaryOp {
        op: UnOp,
        expr: Box<Expr>,
    },
    SysAllocCount,
}

#[derive(Debug, Clone)]
pub enum Stmt {
    LocalDecl {
        names: Vec<String>,
        exprs: Vec<Expr>,
    },
    Assignment {
        name: String,
        expr: Expr,
    },
    IndexAssign {
        obj: Expr,
        key: Expr,
        value: Expr,
    },
    While {
        condition: Expr,
        body: Vec<Stmt>,
    },
    Do {
        body: Vec<Stmt>,
    },
    If {
        condition: Expr,
        then_body: Vec<Stmt>,
        else_body: Vec<Stmt>,
    },
    Print {
        exprs: Vec<Expr>,
    },
}
