
use crate::ast::{BinOp, Expr, Stmt, UnOp};
use crate::lexer::Token;
use std::iter::Peekable;

pub struct Parser<'a> {
    tokens: Peekable<std::vec::IntoIter<Token<'a>>>,
}

impl<'a> Parser<'a> {
    pub fn new(tokens: Vec<Token<'a>>) -> Self {
        Self {
            tokens: tokens.into_iter().peekable(),
        }
    }

    fn expect(&mut self, expected: Token<'a>) {
        let next = self.tokens.next();
        if next != Some(expected.clone()) {
            panic!("Syntax Error: Expected {:?}, got {:?}", expected, next);
        }
    }

    pub fn parse_program(&mut self) -> Vec<Stmt> {
        let mut stmts = Vec::new();
        while self.tokens.peek().is_some() {
            stmts.push(self.parse_stmt());
        }
        stmts
    }

    fn parse_stmt(&mut self) -> Stmt {
        match self.tokens.peek().cloned() {
            Some(Token::Local) => {
                self.tokens.next();
                let mut names = Vec::new();
                loop {
                    let name = match self.tokens.next() {
                        Some(Token::Identifier(n)) => n.to_string(),
                        _ => panic!("Syntax Error: Expected variable name after 'local'"),
                    };
                    names.push(name);
                    if matches!(self.tokens.peek(), Some(Token::Comma)) {
                        self.tokens.next();
                    } else {
                        break;
                    }
                }

                // FIX: Make assignment optional!
                let mut exprs = Vec::new();
                if matches!(self.tokens.peek(), Some(Token::Assign)) {
                    self.tokens.next(); // Consume '='
                    exprs.push(self.parse_expr());
                    while matches!(self.tokens.peek(), Some(Token::Comma)) {
                        self.tokens.next();
                        exprs.push(self.parse_expr());
                    }
                    if exprs.len() != names.len() {
                        panic!(
                            "Syntax Error: 'local' binds {} names to {} values — counts must match",
                            names.len(),
                            exprs.len()
                        );
                    }
                }

                Stmt::LocalDecl { names, exprs }
            }
            Some(Token::While) => {
                self.tokens.next();
                let condition = self.parse_expr();
                self.expect(Token::Do);

                let mut body = Vec::new();
                while self.tokens.peek() != Some(&Token::End) {
                    body.push(self.parse_stmt());
                }
                self.expect(Token::End);

                Stmt::While { condition, body }
            }
            Some(Token::If) => {
                self.tokens.next();
                let condition = self.parse_expr();
                self.expect(Token::Then);

                let mut then_body = Vec::new();
                while self.peek_not_block_end() {
                    then_body.push(self.parse_stmt());
                }

                let mut else_body = Vec::new();
                match self.tokens.peek().cloned() {
                    Some(Token::ElseIf) => {
                        else_body.push(self.parse_elseif_chain());
                    }
                    Some(Token::Else) => {
                        self.tokens.next();
                        while self.peek_not_block_end() {
                            else_body.push(self.parse_stmt());
                        }
                        self.expect(Token::End);
                    }
                    Some(Token::End) => {
                        self.tokens.next();
                    }
                    _ => panic!("Syntax Error: Expected 'else', 'elseif' or 'end' after if body"),
                }

                Stmt::If {
                    condition,
                    then_body,
                    else_body,
                }
            }
            Some(Token::Do) => {
                self.tokens.next();
                let mut body = Vec::new();
                while self.tokens.peek() != Some(&Token::End) {
                    body.push(self.parse_stmt());
                }
                self.expect(Token::End);
                Stmt::Do { body }
            }
            Some(Token::Print) => {
                self.tokens.next();
                self.expect(Token::LeftParen);
                let mut exprs = Vec::new();
                if !matches!(self.tokens.peek(), Some(Token::RightParen)) {
                    exprs.push(self.parse_expr());
                    while matches!(self.tokens.peek(), Some(Token::Comma)) {
                        self.tokens.next();
                        exprs.push(self.parse_expr());
                    }
                }
                self.expect(Token::RightParen);
                Stmt::Print { exprs }
            }
            Some(Token::Identifier(_)) => {
                let lhs = self.parse_expr();
                self.expect(Token::Assign);
                let rhs = self.parse_expr();
                match lhs {
                    Expr::Identifier(name) => Stmt::Assignment { name, expr: rhs },
                    Expr::Index { obj, key } => Stmt::IndexAssign {
                        obj: *obj,
                        key: *key,
                        value: rhs,
                    },
                    _ => panic!("Syntax Error: Invalid assignment target"),
                }
            }
            _ => panic!(
                "Syntax Error: Unexpected statement starting with {:?}",
                self.tokens.peek()
            ),
        }
    }

    fn peek_not_block_end(&mut self) -> bool {
        !matches!(
            self.tokens.peek(),
            Some(Token::End) | Some(Token::Else) | Some(Token::ElseIf) | None
        )
    }

    fn parse_elseif_chain(&mut self) -> Stmt {
        self.expect(Token::ElseIf);
        let condition = self.parse_expr();
        self.expect(Token::Then);

        let mut then_body = Vec::new();
        while self.peek_not_block_end() {
            then_body.push(self.parse_stmt());
        }

        let mut else_body = Vec::new();
        match self.tokens.peek().cloned() {
            Some(Token::ElseIf) => {
                else_body.push(self.parse_elseif_chain());
            }
            Some(Token::Else) => {
                self.tokens.next();
                while self.peek_not_block_end() {
                    else_body.push(self.parse_stmt());
                }
                self.expect(Token::End);
            }
            Some(Token::End) => {
                self.tokens.next();
            }
            _ => panic!("Syntax Error: Expected 'else', 'elseif' or 'end' after elseif body"),
        }

        Stmt::If {
            condition,
            then_body,
            else_body,
        }
    }

    pub fn parse_expr(&mut self) -> Expr {
        self.parse_or()
    }

    fn parse_or(&mut self) -> Expr {
        let mut left = self.parse_and();
        while let Some(Token::Or) = self.tokens.peek() {
            self.tokens.next();
            let right = self.parse_and();
            left = Expr::BinaryOp {
                op: BinOp::Or,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        left
    }

    fn parse_and(&mut self) -> Expr {
        let mut left = self.parse_comparison();
        while let Some(Token::And) = self.tokens.peek() {
            self.tokens.next();
            let right = self.parse_comparison();
            left = Expr::BinaryOp {
                op: BinOp::And,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        left
    }

    fn parse_comparison(&mut self) -> Expr {
        let left = self.parse_term();

        let op = match self.tokens.peek() {
            Some(Token::LessThan) => BinOp::LessThan,
            Some(Token::LessEq) => BinOp::LessEq,
            Some(Token::GreaterThan) => BinOp::GreaterThan,
            Some(Token::GreaterEq) => BinOp::GreaterEq,
            Some(Token::Equal) => BinOp::Equal,
            Some(Token::NotEqual) => BinOp::NotEqual,
            _ => return left,
        };
        self.tokens.next();
        let right = self.parse_term();
        Expr::BinaryOp {
            op,
            left: Box::new(left),
            right: Box::new(right),
        }
    }

    fn parse_term(&mut self) -> Expr {
        let mut left = self.parse_factor();

        while let Some(Token::Plus) | Some(Token::Minus) = self.tokens.peek() {
            let op = match self.tokens.next().unwrap() {
                Token::Plus => BinOp::Add,
                Token::Minus => BinOp::Sub,
                _ => unreachable!(),
            };
            let right = self.parse_factor();
            left = Expr::BinaryOp {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        left
    }

    fn parse_factor(&mut self) -> Expr {
        let mut left = self.parse_unary();

        while let Some(Token::Star)
        | Some(Token::Slash)
        | Some(Token::DoubleSlash)
        | Some(Token::Percent) = self.tokens.peek()
        {
            let op = match self.tokens.next().unwrap() {
                Token::Star => BinOp::Mul,
                Token::Slash => BinOp::Div,
                Token::DoubleSlash => BinOp::IntDiv,
                Token::Percent => BinOp::Mod,
                _ => unreachable!(),
            };
            let right = self.parse_unary();
            left = Expr::BinaryOp {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        left
    }

    fn parse_unary(&mut self) -> Expr {
        match self.tokens.peek().cloned() {
            Some(Token::Minus) => {
                self.tokens.next();
                let expr = self.parse_unary();
                Expr::UnaryOp {
                    op: UnOp::Neg,
                    expr: Box::new(expr),
                }
            }
            Some(Token::Not) => {
                self.tokens.next();
                let expr = self.parse_unary();
                Expr::UnaryOp {
                    op: UnOp::Not,
                    expr: Box::new(expr),
                }
            }
            Some(Token::Len) => {
                self.tokens.next();
                let expr = self.parse_unary();
                Expr::UnaryOp {
                    op: UnOp::Len,
                    expr: Box::new(expr),
                }
            }
            _ => self.parse_postfix(),
        }
    }

    fn parse_postfix(&mut self) -> Expr {
        let mut expr = self.parse_primary();
        while matches!(self.tokens.peek(), Some(Token::LeftBracket)) {
            self.tokens.next();
            let key = self.parse_expr();
            self.expect(Token::RightBracket);
            expr = Expr::Index {
                obj: Box::new(expr),
                key: Box::new(key),
            };
        }
        expr
    }

    fn parse_primary(&mut self) -> Expr {
        match self.tokens.next() {
            Some(Token::Integer(val)) => Expr::Integer(val),
            Some(Token::Float(val)) => Expr::Float(val),
            Some(Token::True) => Expr::Boolean(true),
            Some(Token::False) => Expr::Boolean(false),
            Some(Token::Nil) => Expr::Nil,
            Some(Token::LeftBrace) => {
                // Peek ahead to decide: record {key: val} or array [expr, ...]
                // Record: Identifier ':' → record ctor
                // Array: anything else → table ctor
                let mut elems = Vec::new();
                let mut fields: Vec<(String, Expr)> = Vec::new();
                let mut is_record = false;

                if let Some(Token::Identifier(_)) = self.tokens.peek() {
                    // Look ahead to confirm it's a record
                    let mut look_ahead = self.tokens.clone();
                    if let Some(Token::Identifier(_)) = look_ahead.next()
                        && let Some(Token::Colon) = look_ahead.next()
                    {
                        is_record = true;
                    }
                }

                if is_record {
                    // Parse key:value pairs
                    if !matches!(self.tokens.peek(), Some(Token::RightBrace)) {
                        loop {
                            let key = match self.tokens.next() {
                                Some(Token::Identifier(n)) => n.to_string(),
                                _ => panic!("Syntax Error: Expected field name in record"),
                            };
                            self.expect(Token::Colon);
                            let val = self.parse_expr();
                            fields.push((key, val));
                            if matches!(self.tokens.peek(), Some(Token::Comma)) {
                                self.tokens.next();
                            } else {
                                break;
                            }
                        }
                    }
                    self.expect(Token::RightBrace);
                    // [Canonicalization Strike] Sort fields alphabetically so
                    // slot assignment is name-canonical: {x:1, name:"a"} and
                    // {name:"a", x:1} produce identical positional layouts.
                    // Stable sort keeps duplicate keys in insertion order.
                    fields.sort_by(|a, b| a.0.cmp(&b.0));
                    Expr::RecordCtor(fields)
                } else {
                    // Pure array table ctor
                    if !matches!(self.tokens.peek(), Some(Token::RightBrace)) {
                        loop {
                            elems.push(self.parse_expr());
                            if matches!(self.tokens.peek(), Some(Token::Comma)) {
                                self.tokens.next();
                            } else {
                                break;
                            }
                        }
                    }
                    self.expect(Token::RightBrace);
                    Expr::TableCtor(elems)
                }
            }
            Some(Token::String(s)) => Expr::String(s.trim_matches('"').to_string()),
            Some(Token::Identifier(name)) => {
                if name == "sys_alloc_count" && matches!(self.tokens.peek(), Some(Token::LeftParen)) {
                    self.tokens.next(); // consume '('
                    self.expect(Token::RightParen);
                    return Expr::SysAllocCount;
                }
                Expr::Identifier(name.to_string())
            },
            Some(Token::LeftParen) => {
                let inner = self.parse_expr();
                self.expect(Token::RightParen);
                inner
            }
            _ => panic!("Syntax Error: Expected expression"),
        }
    }
}
