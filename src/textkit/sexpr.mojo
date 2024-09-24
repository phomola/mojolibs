from utils import Variant
from collections import List, Dict, Optional
from textkit.utils import string_from_bytes, bytes_from_string
from textkit import tokenise, Token, word, symbol, string, number, eol, eof

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
    var tokens = tokenise(input)
    var i = 0
    return _parse_sexpr(tokens, i)

fn _parse_sexpr(tokens: List[Token], inout i: Int) raises -> Sexpr:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.form != "(":
        raise Error("expected ')' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var list = List[Variant[Identifier, String, Int, Float64, Sexpr]]()
    while True:
        if t.type == eof:
            raise Error("unexpected EOF")
        if t.form == ")":
            return Sexpr(list)
        if t.type == word:
            list.append(Identifier(t.form))
        elif t.type == number:
            list.append(atol(t.form))
        elif t.type == string:
            list.append(t.form)
        elif t.form == "(":
            list.append(_parse_sexpr(tokens, i))
        else:
            raise Error("expected valid element type at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]
