
#[derive(Debug, Clone, PartialEq)]
pub enum StaticType {
    Integer, 
    Float,   
    Boolean, 
    String,  
    Table(Box<StaticType>),
    Unknown(usize),
    Record(Vec<(String, StaticType)>),
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
            StaticType::Record(fields) => {
                let parts: Vec<String> = fields.iter()
                    .map(|(name, ty)| format!("{}:{}", name, ty))
                    .collect();
                write!(f, "Record<{}>", parts.join(", "))
            }
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
    TableCtor(Vec<Expr>),
    RecordCtor(Vec<(String, Expr)>),
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
