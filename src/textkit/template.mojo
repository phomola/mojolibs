from textkit import bytes_from_string, string_from_bytes, Tokeniser, Token, word, eof
from ioutils import IOWriter, write_string, StringBuilder
from utils import Variant
from collections import Dict, Optional
from sys import exit

alias left_bracket = ord("{")
alias right_bracket = ord("}")

@value
struct Attr:
    var key: String
    var value: Variant[String, Int, Float64, Object, List[Object]]

@value
struct Object:
    var dict: Dict[String, Variant[String, Int, Float64, Object, List[Object]]]

    fn __init__(inout self, *attrs: Attr):
        self.dict = Dict[String, Variant[String, Int, Float64, Object, List[Object]]]()
        for attr in attrs:
            self.dict[attr[].key] = attr[].value

    fn set(inout self, name: String, value: Variant[String, Int, Float64, Object, List[Object]]):
        self.dict[name] = value

@value
struct FieldExpr:
    var field: String

@value
struct WithExpr:
    var field: String
    var template: Optional[Template]

@value
struct RangeExpr:
    var field: String
    var template: Optional[Template]

@value
struct EndExpr:
    pass

@value
struct Template:
    var segments: List[Variant[String, FieldExpr, WithExpr, RangeExpr, EndExpr]]

    fn execute(self, data: Object) raises -> String:
        var sb = StringBuilder()
        self.execute(data, sb)
        return str(sb)

    fn execute[T: IOWriter](self, data: Object, inout writer: T) raises:
        for segment in self.segments:
            if segment[].isa[String]():
                write_string(writer, segment[][String])
            elif segment[].isa[FieldExpr]():
                var field = segment[][FieldExpr].field
                var value_opt = data.dict.get(field)
                if value_opt:
                    var value = value_opt.value()
                    if value.isa[String]():
                        write_string(writer, value[String])
                    elif value.isa[Int]():
                        write_string(writer, str(value[Int]))
                    elif value.isa[Float64]():
                        write_string(writer, str(value[Float64]))
                    else:
                        raise Error("field not string or integer or float: " + field)
                else:
                    raise Error("field not found: " + field)
            elif segment[].isa[WithExpr]():
                var field = segment[][WithExpr].field
                var value_opt = data.dict.get(field)
                if value_opt:
                    var value = value_opt.value()
                    if value.isa[Object]():
                        segment[][WithExpr].template.value().execute(value[Object], writer)
                    else:
                        raise Error("field not object: " + field)
            elif segment[].isa[RangeExpr]():
                var field = segment[][RangeExpr].field
                var value_opt = data.dict.get(field)
                if value_opt:
                    var value = value_opt.value()
                    if value.isa[List[Object]]():
                        var template = segment[][RangeExpr].template.value()
                        for object in value[List[Object]]:
                            template.execute(object[], writer)
                    else:
                        raise Error("field not list of objects: " + field)
            else:
                raise Error("unknown expression type")

fn must_parse_template(code: String) -> Template:
    return must_parse_template(bytes_from_string(code))

fn must_parse_template(code: List[UInt8]) -> Template:
    try:
        return parse_template(code)
    except e:
        print("fatal error: " + str(e))
        exit(1)
        return Template(List[Variant[String, FieldExpr, WithExpr, RangeExpr, EndExpr]]())

fn parse_template(code: String) raises -> Template:
    return parse_template(bytes_from_string(code))

fn parse_template(code: List[UInt8]) raises -> Template:
    var i = 0
    return parse_template(code, i)

fn parse_template(code: List[UInt8], inout i: Int) raises -> Template:
    var start = i
    var in_brackets = False
    var segments = List[Variant[String, FieldExpr, WithExpr, RangeExpr, EndExpr]]()
    while i < len(code):
        print("##### 0", i, len(code))
        if not in_brackets:
            if code[i] == left_bracket:
                i += 1
                if i == len(code):
                    break
                if code[i] == left_bracket:
                    segments.append(string_from_bytes(code[start:i-1]))
                    i += 1
                    start = i
                    in_brackets = True
            else:
                i += 1
        else:
            if code[i] == right_bracket:
                i += 1
                if i == len(code):
                    break
                if code[i] == right_bracket:
                    var tokeniser = Tokeniser(code[start:i-1], word_chars = "_")
                    var tokens = tokeniser.tokenise()
                    var j = 0
                    var expr = parse_expr(tokeniser, tokens, j)
                    if expr.isa[FieldExpr]():
                        segments.append(expr)
                        i += 1
                    elif expr.isa[WithExpr]():
                        i += 1
                        var template = parse_template(code, i)
                        expr[WithExpr].template = template
                        segments.append(expr)
                    elif expr.isa[RangeExpr]():
                        i += 1
                        var template = parse_template(code, i)
                        expr[RangeExpr].template = template
                        segments.append(expr)
                    elif expr.isa[EndExpr]():
                        i += 1
                        return Template(segments)
                    start = i
                    in_brackets = False
            else:
                i += 1
    print("##### 1")
    segments.append(string_from_bytes(code[start:]))
    print("##### 2")
    return Template(segments)

fn parse_expr(tokeniser: Tokeniser, tokens: List[Token], inout i: Int) raises -> Variant[String, FieldExpr, WithExpr, RangeExpr, EndExpr]:
    var token = tokens[i]
    if tokeniser.form(token) == "end":
        i += 1
        token = tokens[i]
        if token.type != eof:
            raise Error("expected end of expression")
        return EndExpr()
    if tokeniser.form(token) == "with":
        i += 1
        token = tokens[i]
        if tokeniser.form(token) == ".":
            i += 1
            token = tokens[i]
            if token.type != word:
                raise Error("expected identifier after '.'")
            var ident = tokeniser.form(token)
            i += 1
            token = tokens[i]
            if token.type != eof:
                raise Error("expected end of expression")
            return WithExpr(ident, None)
        else:
            raise Error("expected '.'")
    if tokeniser.form(token) == "range":
        i += 1
        token = tokens[i]
        if tokeniser.form(token) == ".":
            i += 1
            token = tokens[i]
            if token.type != word:
                raise Error("expected identifier after '.'")
            var ident = tokeniser.form(token)
            i += 1
            token = tokens[i]
            if token.type != eof:
                raise Error("expected end of expression")
            return RangeExpr(ident, None)
        else:
            raise Error("expected '.'")
    if tokeniser.form(token) == ".":
        i += 1
        token = tokens[i]
        if token.type != word:
            raise Error("expected identifier after '.'")
        var ident = tokeniser.form(token)
        i += 1
        token = tokens[i]
        if token.type != eof:
            raise Error("expected end of expression")
        return FieldExpr(ident)
    raise Error("expected '.', 'with' or 'range'")
