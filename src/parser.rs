// src/parser.rs
use crate::ast::{BinOp, Expr, Stmt, UnOp};
use crate::lexer::Token;
use std::iter::Peekable;

pub struct ParseError(pub String);

pub struct Parser<'a> {
    tokens: Peekable<std::vec::IntoIter<Token<'a>>>,
    pub diagnostics: Vec<String>,
}

impl<'a> Parser<'a> {
    pub fn new(tokens: Vec<Token<'a>>) -> Self {
        Self {
            tokens: tokens.into_iter().peekable(),
            diagnostics: Vec::new(),
        }
    }

    fn expect(&mut self, expected: Token<'a>) -> Result<(), ParseError> {
        let next = self.tokens.next();
        if next != Some(expected.clone()) {
            return Err(ParseError(format!("Syntax Error: Expected {:?}, got {:?}", expected, next)));
        }
        Ok(())
    }

    pub fn parse_program(&mut self) -> Vec<Stmt> {
        let mut stmts = Vec::new();
        while self.tokens.peek().is_some() {
            match self.parse_stmt() {
                Ok(stmt) => stmts.push(stmt),
                Err(e) => {
                    self.diagnostics.push(e.0);
                    // Ghost run: bail the rest of the file on first syntax
                    // error to prevent cascading desynchronization panics.
                    // parse_program is the file's root block, so the bail is
                    // scope-tagged (scope 0, depth 0, no parent) exactly like
                    // the shape analyzer's GHOST_BAIL.
                    glm_rt::trace::compiler_trace_current_scope(
                        0,
                        0,
                        glm_rt::trace::TRACE_SCOPE_PARENT_NONE,
                    );
                    glm_rt::trace::compiler_trace_signal(glm_rt::trace::TRACE_GHOST_BAIL_PARSER);
                    break;
                }
            }
        }
        stmts
    }

    fn parse_stmt(&mut self) -> Result<Stmt, ParseError> {
        match self.tokens.peek().cloned() {
            Some(Token::Local) => {
                self.tokens.next();
                let mut names = Vec::new();
                loop {
                    let name = match self.tokens.next() {
                        Some(Token::Identifier(n)) => n.to_string(),
                        _ => return Err(ParseError("Syntax Error: Expected variable name after 'local'".into())),
                    };
                    names.push(name);
                    if matches!(self.tokens.peek(), Some(Token::Comma)) {
                        self.tokens.next();
                    } else {
                        break;
                    }
                }

                let mut exprs = Vec::new();
                if matches!(self.tokens.peek(), Some(Token::Assign)) {
                    self.tokens.next(); // Consume '='
                    exprs.push(self.parse_expr()?);
                    while matches!(self.tokens.peek(), Some(Token::Comma)) {
                        self.tokens.next();
                        exprs.push(self.parse_expr()?);
                    }
                    if exprs.len() != names.len() {
                        return Err(ParseError(format!(
                            "Syntax Error: 'local' binds {} names to {} values — counts must match",
                            names.len(),
                            exprs.len()
                        )));
                    }
                }

                Ok(Stmt::LocalDecl { names, exprs })
            }
            Some(Token::While) => {
                self.tokens.next();
                let condition = self.parse_expr()?;
                self.expect(Token::Do)?;

                let mut body = Vec::new();
                while self.tokens.peek() != Some(&Token::End) {
                    body.push(self.parse_stmt()?);
                }
                self.expect(Token::End)?;

                Ok(Stmt::While { condition, body })
            }
            Some(Token::If) => {
                self.tokens.next();
                let condition = self.parse_expr()?;
                self.expect(Token::Then)?;

                let mut then_body = Vec::new();
                while self.peek_not_block_end() {
                    then_body.push(self.parse_stmt()?);
                }

                let mut else_body = Vec::new();
                match self.tokens.peek().cloned() {
                    Some(Token::ElseIf) => {
                        else_body.push(self.parse_elseif_chain()?);
                    }
                    Some(Token::Else) => {
                        self.tokens.next();
                        while self.peek_not_block_end() {
                            else_body.push(self.parse_stmt()?);
                        }
                        self.expect(Token::End)?;
                    }
                    Some(Token::End) => {
                        self.tokens.next();
                    }
                    _ => return Err(ParseError("Syntax Error: Expected 'else', 'elseif' or 'end' after if body".into())),
                }

                Ok(Stmt::If {
                    condition,
                    then_body,
                    else_body,
                })
            }
            Some(Token::Do) => {
                self.tokens.next();
                let mut body = Vec::new();
                while self.tokens.peek() != Some(&Token::End) {
                    body.push(self.parse_stmt()?);
                }
                self.expect(Token::End)?;
                Ok(Stmt::Do { body })
            }
            Some(Token::Print) => {
                self.tokens.next();
                self.expect(Token::LeftParen)?;
                let mut exprs = Vec::new();
                if !matches!(self.tokens.peek(), Some(Token::RightParen)) {
                    exprs.push(self.parse_expr()?);
                    while matches!(self.tokens.peek(), Some(Token::Comma)) {
                        self.tokens.next();
                        exprs.push(self.parse_expr()?);
                    }
                }
                self.expect(Token::RightParen)?;
                Ok(Stmt::Print { exprs })
            }
            Some(Token::Identifier(_)) => {
                let lhs = self.parse_expr()?;
                self.expect(Token::Assign)?;
                let rhs = self.parse_expr()?;
                match lhs {
                    Expr::Identifier(name) => Ok(Stmt::Assignment { name, expr: rhs }),
                    Expr::Index { obj, key } => Ok(Stmt::IndexAssign {
                        obj: *obj,
                        key: *key,
                        value: rhs,
                    }),
                    _ => Err(ParseError("Syntax Error: Invalid assignment target".into())),
                }
            }
            _ => Err(ParseError(format!(
                "Syntax Error: Unexpected statement starting with {:?}",
                self.tokens.peek()
            ))),
        }
    }

    fn peek_not_block_end(&mut self) -> bool {
        !matches!(
            self.tokens.peek(),
            Some(Token::End) | Some(Token::Else) | Some(Token::ElseIf) | None
        )
    }

    fn parse_elseif_chain(&mut self) -> Result<Stmt, ParseError> {
        self.expect(Token::ElseIf)?;
        let condition = self.parse_expr()?;
        self.expect(Token::Then)?;

        let mut then_body = Vec::new();
        while self.peek_not_block_end() {
            then_body.push(self.parse_stmt()?);
        }

        let mut else_body = Vec::new();
        match self.tokens.peek().cloned() {
            Some(Token::ElseIf) => {
                else_body.push(self.parse_elseif_chain()?);
            }
            Some(Token::Else) => {
                self.tokens.next();
                while self.peek_not_block_end() {
                    else_body.push(self.parse_stmt()?);
                }
                self.expect(Token::End)?;
            }
            Some(Token::End) => {
                self.tokens.next();
            }
            _ => return Err(ParseError("Syntax Error: Expected 'else', 'elseif' or 'end' after elseif body".into())),
        }

        Ok(Stmt::If {
            condition,
            then_body,
            else_body,
        })
    }

    pub fn parse_expr(&mut self) -> Result<Expr, ParseError> {
        self.parse_or()
    }

    fn parse_or(&mut self) -> Result<Expr, ParseError> {
        let mut left = self.parse_and()?;
        while let Some(Token::Or) = self.tokens.peek() {
            self.tokens.next();
            let right = self.parse_and()?;
            left = Expr::BinaryOp {
                op: BinOp::Or,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn parse_and(&mut self) -> Result<Expr, ParseError> {
        let mut left = self.parse_comparison()?;
        while let Some(Token::And) = self.tokens.peek() {
            self.tokens.next();
            let right = self.parse_comparison()?;
            left = Expr::BinaryOp {
                op: BinOp::And,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn parse_comparison(&mut self) -> Result<Expr, ParseError> {
        let left = self.parse_term()?;

        let op = match self.tokens.peek() {
            Some(Token::LessThan) => BinOp::LessThan,
            Some(Token::LessEq) => BinOp::LessEq,
            Some(Token::GreaterThan) => BinOp::GreaterThan,
            Some(Token::GreaterEq) => BinOp::GreaterEq,
            Some(Token::Equal) => BinOp::Equal,
            Some(Token::NotEqual) => BinOp::NotEqual,
            _ => return Ok(left),
        };
        self.tokens.next();
        let right = self.parse_term()?;
        Ok(Expr::BinaryOp {
            op,
            left: Box::new(left),
            right: Box::new(right),
        })
    }

    fn parse_term(&mut self) -> Result<Expr, ParseError> {
        let mut left = self.parse_factor()?;

        while let Some(Token::Plus) | Some(Token::Minus) = self.tokens.peek() {
            let op = match self.tokens.next().unwrap() {
                Token::Plus => BinOp::Add,
                Token::Minus => BinOp::Sub,
                _ => unreachable!(),
            };
            let right = self.parse_factor()?;
            left = Expr::BinaryOp {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn parse_factor(&mut self) -> Result<Expr, ParseError> {
        let mut left = self.parse_unary()?;

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
            let right = self.parse_unary()?;
            left = Expr::BinaryOp {
                op,
                left: Box::new(left),
                right: Box::new(right),
            };
        }
        Ok(left)
    }

    fn parse_unary(&mut self) -> Result<Expr, ParseError> {
        match self.tokens.peek().cloned() {
            Some(Token::Minus) => {
                self.tokens.next();
                let expr = self.parse_unary()?;
                Ok(Expr::UnaryOp {
                    op: UnOp::Neg,
                    expr: Box::new(expr),
                })
            }
            Some(Token::Not) => {
                self.tokens.next();
                let expr = self.parse_unary()?;
                Ok(Expr::UnaryOp {
                    op: UnOp::Not,
                    expr: Box::new(expr),
                })
            }
            Some(Token::Len) => {
                self.tokens.next();
                let expr = self.parse_unary()?;
                Ok(Expr::UnaryOp {
                    op: UnOp::Len,
                    expr: Box::new(expr),
                })
            }
            _ => self.parse_postfix(),
        }
    }

    fn parse_postfix(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.parse_primary()?;
        while matches!(self.tokens.peek(), Some(Token::LeftBracket)) {
            self.tokens.next();
            let key = self.parse_expr()?;
            self.expect(Token::RightBracket)?;
            expr = Expr::Index {
                obj: Box::new(expr),
                key: Box::new(key),
            };
        }
        Ok(expr)
    }

    fn parse_primary(&mut self) -> Result<Expr, ParseError> {
        match self.tokens.next() {
            Some(Token::Integer(val)) => Ok(Expr::Integer(val)),
            Some(Token::Float(val)) => Ok(Expr::Float(val)),
            Some(Token::True) => Ok(Expr::Boolean(true)),
            Some(Token::False) => Ok(Expr::Boolean(false)),
            Some(Token::Nil) => Ok(Expr::Nil),
            Some(Token::LeftBrace) => {
                // [Constructor Cut] Only the empty literal `{}` parses.
                // Populated constructors — `{e1, e2, ...}` tables and
                // `{k: v, ...}` records — shipped half-designed with the
                // record feature and are OFF until the Lua-style
                // redesign (`[k] = v`, `k = v` entries) lands: build
                // tables with stores (`local t = {}` then `t[i] = v`)
                // instead. The rejection is a syntax error, so the whole
                // file ghosts out here (GHOST_BAIL_PARSER) exactly like
                // any other parse failure.
                if !matches!(self.tokens.peek(), Some(Token::RightBrace)) {
                    return Err(ParseError(
                        "Syntax Error: populated constructors are not supported — use 'local t \
                         = {}' and 't[i] = v' stores (constructor redesign pending)"
                            .into(),
                    ));
                }
                self.tokens.next();
                // Constructor census for the map: the empty literal is
                // the Pending/F9 root (it can never join a record site).
                glm_rt::trace::compiler_trace_signal(glm_rt::trace::TRACE_PARSE_TBL_EMPTY);
                Ok(Expr::TableCtor(Vec::new()))
            }
            Some(Token::String(s)) => Ok(Expr::String(s.trim_matches('"').to_string())),
            Some(Token::Identifier(name)) => {
                if name == "sys_alloc_count" && matches!(self.tokens.peek(), Some(Token::LeftParen)) {
                    self.tokens.next(); // consume '('
                    self.expect(Token::RightParen)?;
                    return Ok(Expr::SysAllocCount);
                }
                Ok(Expr::Identifier(name.to_string()))
            }
            Some(Token::LeftParen) => {
                let inner = self.parse_expr()?;
                self.expect(Token::RightParen)?;
                Ok(inner)
            }
            _ => Err(ParseError("Syntax Error: Expected expression".into())),
        }
    }
}
