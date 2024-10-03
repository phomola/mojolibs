from textkit import bytes_from_string, string_from_bytes, tokenise, Token, word, eof
from utils import Variant
from collections import Dict, Optional

alias left_bracket = ord("{")
alias right_bracket = ord("}")

@value
struct Attr:
    var key: String
    var value: Variant[String, Int, Object, List[Object]]

@value
struct Object:
    var dict: Dict[String, Variant[String, Int, Object, List[Object]]]

    fn __init__(inout self, *attrs: Attr):
        self.dict = Dict[String, Variant[String, Int, Object, List[Object]]]()
        for attr in attrs:
            self.dict[attr[].key] = attr[].value

    fn set(inout self, name: String, value: Variant[String, Int, Object, List[Object]]):
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
        var result: String = ""
        for segment in self.segments:
            if segment[].isa[String]():
                result += segment[][String]
            elif segment[].isa[FieldExpr]():
                var field = segment[][FieldExpr].field
                var value_opt = data.dict.get(field)
                if value_opt:
                    var value = value_opt.value()
                    if value.isa[String]():
                        result += value[String]
                    elif value.isa[Int]():
                        result += str(value[Int])
                    else:
                        raise Error("field not string: " + field)
                else:
                    raise Error("field not found: " + field)
            elif segment[].isa[WithExpr]():
                var field = segment[][WithExpr].field
                var value_opt = data.dict.get(field)
                if value_opt:
                    var value = value_opt.value()
                    if value.isa[Object]():
                        var result2 = segment[][WithExpr].template.value().execute(value[Object])
                        result += result2
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
                            var result2 = template.execute(object[])
                            result += result2
                    else:
                        raise Error("field not list of objects: " + field)
            else:
                raise Error("unknown expression type")
        return result

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
                    var tokens = tokenise(code[start:i-1], word_chars = "_")
                    var j = 0
                    var expr = parse_expr(tokens, j)
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
    segments.append(string_from_bytes(code[start:]))
    return Template(segments)

fn parse_expr(tokens: List[Token], inout i: Int) raises -> Variant[String, FieldExpr, WithExpr, RangeExpr, EndExpr]:
    var token = tokens[i]
    if token.form == "end":
        i += 1
        token = tokens[i]
        if token.type != eof:
            raise Error("expected end of expression")
        return EndExpr()
    if token.form == "with":
        i += 1
        token = tokens[i]
        if token.form == ".":
            i += 1
            token = tokens[i]
            if token.type != word:
                raise Error("expected identifier after '.'")
            var ident = token.form
            i += 1
            token = tokens[i]
            if token.type != eof:
                raise Error("expected end of expression")
            return WithExpr(ident, None)
        else:
            raise Error("expected '.'")
    if token.form == "range":
        i += 1
        token = tokens[i]
        if token.form == ".":
            i += 1
            token = tokens[i]
            if token.type != word:
                raise Error("expected identifier after '.'")
            var ident = token.form
            i += 1
            token = tokens[i]
            if token.type != eof:
                raise Error("expected end of expression")
            return RangeExpr(ident, None)
        else:
            raise Error("expected '.'")
    if token.form == ".":
        i += 1
        token = tokens[i]
        if token.type != word:
            raise Error("expected identifier after '.'")
        var ident = token.form
        i += 1
        token = tokens[i]
        if token.type != eof:
            raise Error("expected end of expression")
        return FieldExpr(ident)
    raise Error("expected '.', 'with' or 'range'")
