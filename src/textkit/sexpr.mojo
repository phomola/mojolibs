from utils import Variant
from collections import List, Dict, Optional
from textkit.utils import string_from_bytes, bytes_from_string
from textkit import Tokeniser, Token, word, symbol, string, integer, real, eol, eof

@value
struct Identifier(Stringable):
    var name: String

    fn __str__(self) -> String:
        return self.name

@value
struct Sexpr:
    var list: List[Variant[Identifier, String, Int, Float64, Sexpr]]

    fn __str__(self) -> String:
        var s: String = "("
        var first = True
        for el in self.list:
            if first:
                first = False
            else:
                s += " "
            if el[].isa[Identifier]():
                s += "@" + el[][Identifier].name
            elif el[].isa[String]():
                s += el[][String]
            elif el[].isa[Int]():
                s += str(el[][Int])
            elif el[].isa[Float64]():
                s += str(el[][Float64])
            elif el[].isa[Sexpr]():
                s += str(el[][Sexpr])
            else:
                s += "???"
        return s + ")"

fn parse_sexpr(input: String) raises -> Sexpr:
    return parse_sexpr(bytes_from_string(input))

fn parse_sexpr(input: List[UInt8]) raises -> Sexpr:
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_sexpr(tokens, tokeniser, i)

fn _parse_sexpr(tokens: List[Token], tokeniser: Tokeniser, inout i: Int) raises -> Sexpr:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if tokeniser.form(t) != "(":
        raise Error("expected ')' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var list = List[Variant[Identifier, String, Int, Float64, Sexpr]]()
    while True:
        if t.type == eof:
            raise Error("unexpected EOF")
        if tokeniser.form(t) == ")":
            i += 1
            return Sexpr(list)
        if t.type == word:
            list.append(Identifier(tokeniser.form(t)))
            i += 1
        elif t.type == integer:
            list.append(atol(tokeniser.form(t)))
            i += 1
        elif t.type == real:
            list.append(atof(tokeniser.form(t)))
            i += 1
        elif t.type == string:
            list.append(tokeniser.form(t))
            i += 1
        elif tokeniser.form(t) == "(":
            list.append(_parse_sexpr(tokens, tokeniser, i))
        else:
            raise Error("expected valid element type at " + str(t.line) + ":" + str(t.column))
        t = tokens[i]
