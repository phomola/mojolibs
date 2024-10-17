from utils import Variant, StringRef
from collections import List, Dict, Optional
from textkit.utils import string_from_bytes, bytes_from_string
from memory import UnsafePointer

alias word   = 1
alias number = 2
alias string = 3
alias symbol = 4
alias eol    = 5
alias eof    = 6

alias newline = ord("\n")
alias quote = ord("\"")
alias backslash = ord("\\")
alias space = ord(" ")
alias linefeed = ord("\r")
alias tab = ord("\t")
alias zero = ord("0")
alias nine = ord("9")
alias char_A = ord("A")
alias char_Z = ord("Z")
alias char_a = ord("a")
alias char_z = ord("z")

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

fn is_white_char(s: String) -> Bool:
    return s == " " or s == "\r" or s == "\n" or s == "\t"

fn is_alpha(s: String) -> Bool:
    return s >= "A" and s <= "Z" or s >= "a" and s <= "z"

fn is_number(s: String) -> Bool:
    return s >= "0" and s <= "9"

fn is_white_char(c: UInt8) -> Bool:
    return c == space or c == linefeed or c == newline or c == tab

fn is_alpha(c: UInt8) -> Bool:
    return c >= char_A and c <= char_Z or c >= char_a and c <= char_z

fn is_number(c: UInt8) -> Bool:
    return c >= zero and c <= nine

fn contains_char(list: List[UInt8], char: UInt8) -> Bool:
    for el in list:
        if el[] == char:
            return True
    return False

struct Tokeniser:
    var input: List[UInt8]
    var keep_eol: Bool
    var word_chars: String

    fn __init__(inout self, input: List[UInt8], keep_eol: Bool = False, word_chars: String = ""):
        self.input = input
        self.keep_eol = keep_eol
        self.word_chars = word_chars

    fn __init__(inout self, input: String, keep_eol: Bool = False, word_chars: String = ""):
        self.input = bytes_from_string(input)
        self.keep_eol = keep_eol
        self.word_chars = word_chars

    fn form(self, token: Token) -> StringRef:
        return StringRef(self.input.unsafe_ptr() + token.span.start, token.span.len)

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
        var word_chars_bytes = bytes_from_string(self.word_chars)
        var text = self.input
        while True:
            if state == 0:
                while i < len(text):
                    var r = text[i]
                    if r == newline:
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
            elif state == number:
                if is_number(r):
                    i += 1
                    col += 1
                else:
                    tokens.append(Token(number, Span(start, i-start), line1, col1, False))
                    state = 0
            elif state == string:
                if r == quote and not esc:
                    tokens.append(Token(string, Span(start, i-start), line1, col1, has_esc))
                    state = 0
                    col += 1
                    i += 1
                else:
                    if r == backslash and not esc:
                        col += 1
                        esc = True
                        has_esc = True
                    elif r == newline:
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
                    state = number
                    start = i
                    i += 1
                    line1 = line
                    col1 = col
                    col += 1
                elif r == quote:
                    state = string
                    has_esc = False
                    i += 1
                    start = i
                    line1 = line
                    col1 = col
                    col += 1
                else:
                    tokens.append(Token(symbol, Span(i, 1), line, col, False))
                    i += 1
                    col += 1
        if state == word:
            tokens.append(Token(word, Span(start, i-start), line1, col1, False))
        elif state == number:
            tokens.append(Token(number, Span(start, i-start), line1, col1, False))
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
