from utils import Variant
from collections import List, Dict, Optional

alias word   = 1
alias number = 2
alias string = 3
alias symbol = 4
alias eol    = 5
alias eof    = 6

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

fn tokenise(text: String, keep_eol: Bool = False) -> List[Token]:
    var tokens = List[Token]()
    var i = 0
    var line = 1
    var col = 1
    var line1 = 1
    var col1 = 1
    var state = 0
    var start = 0
    var esc = False
    while True:
        if state == 0:
            while i < len(text):
                var r = text[i]
                if r == "\n":
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
            if is_alpha(r) or is_number(r):
                i += 1
                col += 1
            else:
                tokens.append(Token(word, text[start:i], line1, col1))
                state = 0
        elif state == number:
            if is_number(r):
                i += 1
                col += 1
            else:
                tokens.append(Token(number, text[start:i], line1, col1))
                state = 0
        elif state == string:
            if r == "\"" and not esc:
                tokens.append(Token(string, unquote(text[start:i]), line1, col1))
                state = 0
                col += 1
                i += 1
            else:
                if r == "\\" and not esc:
                    col += 1
                    esc = True
                elif r == "\n":
                    line += 1
                    col = 1
                    esc = False
                else:
                    col += 1
                    esc = False
                i += 1
        else:
            if is_alpha(r):
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
            elif r == "\"":
                state = string
                i += 1
                start = i
                line1 = line
                col1 = col
                col += 1
            else:
                tokens.append(Token(symbol, text[i], line, col))
                i += 1
                col += 1
    if state == word:
        tokens.append(Token(word, text[start:i], line1, col1))
    elif state == number:
        tokens.append(Token(number, text[start:i], line1, col1))
    elif state == string:
        tokens.append(Token(string, unquote(text[start:i]), line1, col1))
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
