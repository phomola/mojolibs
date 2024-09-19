from utils import Variant
from collections import List, Dict, Optional
from textkit import tokenise, Token, word, symbol, string, number, eol, eof

@value
struct JSONObject:
    var dict: Dict[String, Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]

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
        i += 1
        var t2 = tokens[i]
        if t2.form != ".":
            return atol(t.form)
        i += 1
        var t3 = tokens[i]
        if t3.type != number:
            raise Error("expected number at " + str(t.line) + ":" + str(t.column))
        i += 1
        return atof(t.form + "." + t3.form)
    if t.form == "{":
        return _parse_json_object(tokens, i)
    if t.form == "[":
        return _parse_json_array(tokens, i)
    raise Error("unexpected value at " + str(t.line) + ":" + str(t.column))
