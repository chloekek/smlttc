use std::rc::Rc;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct Position
{
    pub line: u32,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum Token
{
    ParenL(Position),
    ParenR(Position),
    Int(Position, i64),
    Str(Position, Rc<[u8]>),
    Sym(Position, Rc<[u8]>),
    Eof,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Error
{
    UnknownByte(Position, u8),
}

#[derive(Clone)]
pub struct Lexer<'a>
{
    input: &'a [u8],
    position: Position,
}

impl<'a> Lexer<'a>
{
    pub fn new(input: &'a [u8]) -> Self
    {
        Lexer{input, position: Position{line: 1}}
    }

    fn readByte(&mut self) -> Option<(Position, u8)>
    {
        match self.input.get(0) {
            Some(&b) => {
                let p = self.position;
                if b == b'\n' { self.position.line += 1 }
                self.input = &self.input[1 ..];
                Some((p, b))
            },
            None => None,
        }
    }

    pub fn readToken(&mut self) -> Result<Token, Error>
    {
        match self.readByte() {
            Some((p, b'(')) => Ok(Token::ParenL(p)),
            Some((p, b')')) => Ok(Token::ParenR(p)),
            Some((p, b)) => Err(Error::UnknownByte(p, b)),
            None => Ok(Token::Eof),
        }
    }
}

#[test]
fn testLexer()
{
    let mut lexer = Lexer::new(b"()");
    assert_eq!(lexer.readToken(), Ok(Token::ParenL(Position{line: 1})));
    assert_eq!(lexer.readToken(), Ok(Token::ParenR(Position{line: 1})));
    assert_eq!(lexer.readToken(), Ok(Token::Eof));
}
