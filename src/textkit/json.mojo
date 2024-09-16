from utils import Variant
from collections import List, Dict, Optional
from textkit import tokenise, Token, word, symbol, string, number, eol, eof

@value
struct JSONObject:
    var dict: Dict[String, Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]

    fn get_string(self, key: String) -> Optional[String]:
        var val_opt = self.dict.get(key)
        if val_opt:
            var val = val_opt.value()
            if val.isa[String]():
                return val[String]
        return None

    fn must_get_string(self, key: String) raises -> String:
        var val_opt = self.dict.get(key)
        if val_opt:
            var val = val_opt.value()
            if val.isa[String]():
                return val[String]
            else:
                raise Error("'" + key + "' in JSON object not string")    
        else:
            raise Error("'" + key + "' not in JSON object")

@value
struct JSONArray:
	var array: List[Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]

@value
struct JSONNull:
    fn __eq__(self, n: JSONNull) -> Bool:
        return True
    
    fn __ne__(self, n: JSONNull) -> Bool:
        return False
    
    fn __str__(self) -> String:
        return "null"

var null = JSONNull()

fn parse_json_object(input: String) raises -> JSONObject:
    var tokens = tokenise(input)
    var i = 0
    return _parse_json_object(tokens, i)

fn parse_json_array(input: String) raises -> JSONArray:
    var tokens = tokenise(input)
    var i = 0
    return _parse_json_array(tokens, i)

fn parse_json_value(input: String) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    var tokens = tokenise(input)
    var i = 0
    return _parse_json_value(tokens, i)

fn parse_json_object(input: List[UInt8]) raises -> JSONObject:
    var tokens = tokenise(input)
    var i = 0
    return _parse_json_object(tokens, i)

fn parse_json_array(input: List[UInt8]) raises -> JSONArray:
    var tokens = tokenise(input)
    var i = 0
    return _parse_json_array(tokens, i)

fn parse_json_value(input: List[UInt8]) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    var tokens = tokenise(input)
    var i = 0
    return _parse_json_value(tokens, i)

fn _parse_json_object(tokens: List[Token], inout i: Int) raises -> JSONObject:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.form != "{":
        raise Error("expected '{' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var dict = Dict[String, Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]()
    if t.form == "}":
        i += 1
        return JSONObject(dict)
    while True:
        if t.type != string:
            raise Error("expected string at " + str(t.line) + ":" + str(t.column))
        var key = t.form
        i += 1
        t = tokens[i]
        if t.form != ":":
            raise Error("expected ':' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]
        var value = _parse_json_value(tokens, i)
        dict[key] = value        
        t = tokens[i]
        if t.form == "}":
            i += 1
            return JSONObject(dict)
        if t.form != ",":
            raise Error("expected ',' or '}' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]

fn _parse_json_array(tokens: List[Token], inout i: Int) raises -> JSONArray:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.form != "[":
        raise Error("expected '[' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var array = List[Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]()
    if t.form == "]":
        i += 1
        return JSONArray(array)
    while True:
        var value = _parse_json_value(tokens, i)
        array.append(value)
        t = tokens[i]
        if t.form == "]":
            i += 1
            return JSONArray(array)
        if t.form != ",":
            raise Error("expected ',' or ']' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]

fn _parse_json_value(tokens: List[Token], inout i: Int) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.type == word:
        if t.form == "true":
            i += 1
            return True
        if t.form == "false":
            i += 1
            return False
        if t.form == "null":
            i += 1
            return null
        raise Error("expected 'true' or 'false' at " + str(t.line) + ":" + str(t.column))
    if t.type == string:
        i += 1
        return t.form
    if t.type == number:
        return convert_json_number(_parse_number(tokens, i))
    if t.form == "{":
        return _parse_json_object(tokens, i)
    if t.form == "[":
        return _parse_json_array(tokens, i)
    if t.form == "-":
        i += 1
        t = tokens[i]
        if t.type == number:
            return convert_json_number(_parse_number(tokens, i, neg=True))
    raise Error("unexpected value at " + str(t.line) + ":" + str(t.column))

fn _parse_number(tokens: List[Token], inout i: Int, neg: Bool = False) raises -> Variant[Int, Float64]:
    var t = tokens[i]
    i += 1
    var t2 = tokens[i]
    if t2.form != ".":
        return atol(t.form) * (-1 if neg else 1)
    i += 1
    var t3 = tokens[i]
    if t3.type != number:
        raise Error("expected number at " + str(t.line) + ":" + str(t.column))
    i += 1
    return atof(t.form + "." + t3.form) * (-1 if neg else 1)

fn convert_json_number(x: Variant[Int, Float64]) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    if x.isa[Int]():
        return x[Int]
    if x.isa[Float64]():
        return x[Float64]
    raise Error("unexpected number type")
