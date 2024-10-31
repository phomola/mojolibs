from utils import Variant, StringRef
from collections import List, Dict, Optional
from textkit.utils import string_from_bytes, bytes_from_string
from memory import UnsafePointer
from sys.ffi import c_char

alias word    = 1
alias integer = 2
alias real    = 3
alias string  = 4
alias symbol  = 5
alias eol     = 6
alias eof     = 7

alias `\n` = Byte(ord("\n"))
alias `"` = Byte(ord("\""))
alias `\` = Byte(ord("\\"))
alias `\r` = Byte(ord("\r"))
alias `\t` = Byte(ord("\t"))
alias ` ` = Byte(ord(" "))
alias `.` = Byte(ord("."))
alias `0` = Byte(ord("0"))
alias `9` = Byte(ord("9"))
alias `A` = Byte(ord("A"))
alias `Z` = Byte(ord("Z"))
alias `a` = Byte(ord("a"))
alias `z` = Byte(ord("z"))

@value
struct Span:
    var start: Int
    var len: Int

    fn __eq__(span, span2: Span) -> Bool:
        return span.start == span2.start and span.len == span2.len

@value
struct Token:
    var type: Int
    var span: Span
    var line: Int
    var column: Int
    var has_esc: Bool

@always_inline
fn is_white_char(c: UInt8) -> Bool:
    return c == ` ` or c == `\r` or c == `\n` or c == `\t`

@always_inline
fn is_alpha(c: Byte) -> Bool:
    return c >= `A` and c <= `Z` or c >= `a` and c <= `z`

@always_inline
fn is_number(c: Byte) -> Bool:
    return c >= `0` and c <= `9`

@always_inline
fn contains_char(list: List[Byte], char: Byte) -> Bool:
    for el in list:
        if el[] == char:
            return True
    return False

struct Tokeniser:
    var input: List[Byte]
    var keep_eol: Bool
    var word_chars: String

    fn __init__(inout self, input: List[Byte], keep_eol: Bool = False, word_chars: String = ""):
        self.input = input
        self.keep_eol = keep_eol
        self.word_chars = word_chars

    fn __init__(inout self, input: String, keep_eol: Bool = False, word_chars: String = ""):
        self.input = bytes_from_string(input)
        self.keep_eol = keep_eol
        self.word_chars = word_chars

    @always_inline
    fn form(self, token: Token) -> StringRef:
        return StringRef((self.input.unsafe_ptr() + token.span.start).bitcast[c_char](), token.span.len)

    @always_inline
    fn unquoted_form(self, token: Token) -> String:
        form = self.form(token)
        return form if not token.has_esc else unquote(form)

    fn tokenise(self) -> List[Token]:
        var tokens = List[Token]()
        var i = 0
        var line = 1
        var col = 1
        var line1 = 1
        var col1 = 1
        var state = 0
        var start = 0
        var esc = False
        var has_esc = False
        var start_float = -1
        var word_chars_bytes = bytes_from_string(self.word_chars)
        var text = self.input
        while True:
            if state == 0:
                while i < len(text):
                    var r = text[i]
                    if r == `\n`:
                        if self.keep_eol:
                            tokens.append(Token(eol, Span(i, 1), line, col, False))
                        line += 1
                        col = 1
                    elif not is_white_char(r):
                        break
                    else:
                        col += 1
                    i += 1
            if i == len(text):
                break
            var r = text[i]
            if state == word:
                if is_alpha(r) or is_number(r) or contains_char(word_chars_bytes, r): # `in` doesn't work here
                    i += 1
                    col += 1
                else:
                    tokens.append(Token(word, Span(start, i-start), line1, col1, False))
                    state = 0
            elif state == integer:
                if is_number(r):
                    i += 1
                    col += 1
                else:
                    if start_float != -1:
                        tokens[-1] = Token(real, Span(start, i-start_float), line1, col1, False)
                        start_float = -1
                    else:
                        tokens.append(Token(integer, Span(start, i-start), line1, col1, False))
                    state = 0
            elif state == string:
                if r == `"` and not esc:
                    tokens.append(Token(string, Span(start, i-start), line1, col1, has_esc))
                    state = 0
                    col += 1
                    i += 1
                else:
                    if r == `\` and not esc:
                        col += 1
                        esc = True
                        has_esc = True
                    elif r == `\n`:
                        line += 1
                        col = 1
                        esc = False
                    else:
                        col += 1
                        esc = False
                    i += 1
            else:
                if is_alpha(r) or contains_char(word_chars_bytes, r):
                    state = word
                    start = i
                    i += 1
                    line1 = line
                    col1 = col
                    col += 1
                elif is_number(r):
                    state = integer
                    start = i
                    i += 1
                    line1 = line
                    col1 = col
                    col += 1
                elif r == `"`:
                    state = string
                    has_esc = False
                    i += 1
                    start = i
                    line1 = line
                    col1 = col
                    col += 1
                else:
                    if r == `.` and start_float == -1 and len(tokens) > 0 and tokens[-1].type == integer:
                        if i+1 == len(text) or not is_number(text[i+1]):
                            tokens[-1] = Token(real, Span(start, i-start+1), line1, col1, False)
                        else:
                            start_float = start
                            state = integer
                    else:
                        tokens.append(Token(symbol, Span(i, 1), line, col, False))
                    i += 1
                    col += 1
        if state == word:
            tokens.append(Token(word, Span(start, i-start), line1, col1, False))
        elif state == integer:
            tokens.append(Token(integer, Span(start, i-start), line1, col1, False))
        elif state == string:
            tokens.append(Token(string, Span(start, i-start), line1, col1, has_esc))
        tokens.append(Token(eof, Span(i, 0), line, col, False))
        return tokens

fn unquote(s: String) -> String:
    var r: String = ""
    var esc = False
    for i in range(len(s)):
        var c = s[i]
        if c == "\\" and not esc:
            esc = True
        else:
            if esc:
                if c == "n":
                    r += "\n"
                elif c == "r":
                    r += "\r"
                elif c == "t":
                    r += "\t"
                else:
                    r += c
                esc = False
            else:
                r += c
    return r
