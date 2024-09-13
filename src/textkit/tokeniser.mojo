from utils import Variant
from collections import List, Dict, Optional
from textkit.utils import string_from_bytes, bytes_from_string

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
struct Token:
    var type: Int
    var form: String
    var line: Int
    var column: Int

    fn __eq__(tok1: Token, tok2: Token) -> Bool:
        return tok1.type == tok2.type and tok1.form == tok2.form and tok1.line == tok2.line and tok1.column == tok2.column
    
    fn __str__(self: Token) -> String:
        return str(self.type) + " " + self.form + " " + str(self.line) + ":" + str(self.column)

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

fn tokenise(text: String, keep_eol: Bool = False, word_chars: String = "") -> List[Token]:
    return tokenise(bytes_from_string(text), keep_eol, word_chars)

fn tokenise(text: List[UInt8], keep_eol: Bool = False, word_chars: String = "") -> List[Token]:
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
    var word_chars_bytes = bytes_from_string(word_chars)
    while True:
        if state == 0:
            while i < len(text):
                var r = text[i]
                if r == newline:
                    if keep_eol:
                        tokens.append(Token(eol, "\n", line, col))
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
                tokens.append(Token(word, string_from_bytes(text[start:i]), line1, col1))
                state = 0
        elif state == number:
            if is_number(r):
                i += 1
                col += 1
            else:
                tokens.append(Token(number, string_from_bytes(text[start:i]), line1, col1))
                state = 0
        elif state == string:
            if r == quote and not esc:
                tokens.append(Token(string, string_from_bytes(text[start:i]) if not has_esc else unquote(string_from_bytes(text[start:i])), line1, col1))
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
                tokens.append(Token(symbol, string_from_bytes(text[i]), line, col))
                i += 1
                col += 1
    if state == word:
        tokens.append(Token(word, string_from_bytes(text[start:i]), line1, col1))
    elif state == number:
        tokens.append(Token(number, string_from_bytes(text[start:i]), line1, col1))
    elif state == string:
        tokens.append(Token(string, string_from_bytes(text[start:i]) if not has_esc else unquote(string_from_bytes(text[start:i])), line1, col1))
    tokens.append(Token(eof, "", line, col))
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
