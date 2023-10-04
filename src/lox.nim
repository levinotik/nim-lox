import os
import std/options
import std/rdstdin

var
  hadError = false

proc report(line: int, where, message: string) =
  stdErr.writeLine("[line ", line, "] Error", where, ": ", message)
  hadError = true

proc error(line: int, message: string) =
  report(line, "", message)

type
  TokenType = enum
    # single-character tokens
    LEFT_PAREN, RIGHT_PAREN, LEFT_BRACE, RIGHT_BRACE,
    COMMA, DOT, MINUS, PLUS, SEMICOLON, SLASH, STAR

    # one or two char tokens
    BANG, BANG_EQUAL,
    EQUAL, EQUAL_EQUAL,
    GREATER, GREATER_EQUAL
    LESS, LESS_EQUAL

    # literals
    IDENTIFIER, `STRING`, NUMBER,

    # keywords
    `AND`, CLASS, `ELSE`, `FALSE`, FUN,
    `FOR`, `IF`, `NIL`, `OR`,
    PRINT, `RETURN`, SUPER, THIS, `TRUE`, `VAR`,
    `WHILE`

    EOF

  Literal = object
    case kind: TokenType
    of IDENTIFIER, `STRING`: str: string
    of NUMBER: floatVal: float
    else: discard
  Token = object
    tokenType: TokenType
    lexeme: string
    literal: Option[Literal] = none(Literal)
    line: int
  Scanner = object
    source: string
    tokens: seq[Token]
    start: int = 0
    current: int = 0
    line: int = 1

func initScanner(source: string): Scanner =
  result.source = source
  result.tokens = @[]

using 
  s: var Scanner 

func isAtEnd(scanner: Scanner): bool =
  scanner.current >= len(scanner.source)

proc advance(s): char {.discardable.} =
  let ch = s.source[s.current]
  s.current += 1
  ch

proc addToken(s; `type`: TokenType, 
              literal: Option[Literal]) =
  let text: string = s.source[s.start..s.current]
  echo "the text I'm using for start..current is: ", text
  s.tokens.add(Token(tokenType: `type`, lexeme: text, literal: literal,
      line: s.line))

proc addToken(s; `type`: TokenType) =
  s.addToken(`type`, none(Literal))


proc match(s; expected: char): bool =
  if s.isAtEnd():
    false
  elif s.source[s.current] != expected:
    false
  else:
    s.current += 1
    true

proc peek(scanner: Scanner): char =
  if scanner.isAtEnd():
    '\0'
  else:
    scanner.source[scanner.current]

proc `string`(s) =
  while s.peek() != '"' and not s.isAtEnd:
    if s.peek() == '\n':
      s.line += 1
    s.advance()

  if s.isAtEnd():
    error(s.line, "Unterminated string.")
    return

  s.advance()

  let value = s.source[(s.start + 1)..(s.current - 1)]
  s.addToken(`STRING`, some(Literal(kind: `STRING`, str: value)))

proc scanToken(s) =
  let c = advance(s)
  case c
  of '(':
    addToken(s, LEFT_PAREN)
  of ')':
    addToken(s, RIGHT_PAREN)
  of '{':
    addToken(s, LEFT_BRACE)
  of '}':
    addToken(s, RIGHT_BRACE)
  of ',':
    addToken(s, COMMA)
  of '.':
    addToken(s, DOT)
  of '-':
    addToken(s, MINUS)
  of '+':
    addToken(s, PLUS)
  of ';':
    addToken(s, SEMICOLON)
  of '*':
    addToken(s, STAR)
  of '!':
    let token = if s.match('='): BANG_EQUAL else: BANG
    s.addToken(token)
  of '=':
    let token = if s.match('='): EQUAL_EQUAL else: EQUAL
    s.addToken(token)
  of '<':
    let token = if s.match('='): LESS_EQUAL else: LESS
    s.addToken(token)
  of '>':
    let token = if s.match('='): GREATER_EQUAL else: GREATER
    s.addToken(token)
  of '/':
    if s.match('/'):
      while s.peek() != '\n' and not s.isAtEnd():
        s.advance()
    else:
      s.addToken(SLASH)
  of ' ', '\r', '\t':
    discard
  of '\n':
    s.line += 1
  of '"':
    s.`string`()
  else:
    error(s.line, "Unexpected character")
    discard

proc scanTokens(s): seq[Token] =
  while not s.isAtEnd():
    s.start = s.current
    scanToken(s)

  s.tokens.add(Token(tokenType: EOF, lexeme: "", literal: none(Literal),
      line: s.line))
  result = s.tokens

proc run(source: string) =
  var s = initScanner(source)
  let tokens = s.scanTokens()
  for token in tokens:
    echo token

proc runFile(path: string) =
  run(readFile(path))
  if hadError:
    system.quit(65)

proc runPrompt() =
  var line: string
  while true:
    let ok = readLineFromStdin("> ", line)
    if not ok: break
    run(line)
    hadError = false

when isMainModule:
  let args = commandLineParams()
  if args.len() > 1:
    echo "Usage: jlox [script]"
  elif args.len() == 1:
    runFile(args[0])
  else:
    runPrompt()
