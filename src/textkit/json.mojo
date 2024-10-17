from utils import Variant
from collections import List, Dict, Optional
from textkit import Tokeniser, Token, word, symbol, string, integer, real, eol, eof

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
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_json_object(tokeniser, tokens, i)

fn parse_json_array(input: String) raises -> JSONArray:
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_json_array(tokeniser, tokens, i)

fn parse_json_value(input: String) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_json_value(tokeniser, tokens, i)

fn parse_json_object(input: List[UInt8]) raises -> JSONObject:
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_json_object(tokeniser, tokens, i)

fn parse_json_array(input: List[UInt8]) raises -> JSONArray:
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_json_array(tokeniser, tokens, i)

fn parse_json_value(input: List[UInt8]) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    var tokeniser = Tokeniser(input)
    var tokens = tokeniser.tokenise()
    var i = 0
    return _parse_json_value(tokeniser, tokens, i)

fn _parse_json_object(tokeniser: Tokeniser, tokens: List[Token], inout i: Int) raises -> JSONObject:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if tokeniser.form(t) != "{":
        raise Error("expected '{' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var dict = Dict[String, Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]()
    if tokeniser.form(t) == "}":
        i += 1
        return JSONObject(dict)
    while True:
        if t.type != string:
            raise Error("expected string at " + str(t.line) + ":" + str(t.column))
        var key = tokeniser.form(t)
        i += 1
        t = tokens[i]
        if tokeniser.form(t) != ":":
            raise Error("expected ':' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]
        var value = _parse_json_value(tokeniser, tokens, i)
        dict[key] = value        
        t = tokens[i]
        if tokeniser.form(t) == "}":
            i += 1
            return JSONObject(dict)
        if tokeniser.form(t) != ",":
            raise Error("expected ',' or '}' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]

fn _parse_json_array(tokeniser: Tokeniser, tokens: List[Token], inout i: Int) raises -> JSONArray:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if tokeniser.form(t) != "[":
        raise Error("expected '[' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var array = List[Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]]()
    if tokeniser.form(t) == "]":
        i += 1
        return JSONArray(array)
    while True:
        var value = _parse_json_value(tokeniser, tokens, i)
        array.append(value)
        t = tokens[i]
        if tokeniser.form(t) == "]":
            i += 1
            return JSONArray(array)
        if tokeniser.form(t) != ",":
            raise Error("expected ',' or ']' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]

fn _parse_json_value(tokeniser: Tokeniser, tokens: List[Token], inout i: Int) raises -> Variant[Int, Float64, String, Bool, JSONObject, JSONArray, JSONNull]:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.type == word:
        if tokeniser.form(t) == "true":
            i += 1
            return True
        if tokeniser.form(t) == "false":
            i += 1
            return False
        if tokeniser.form(t) == "null":
            i += 1
            return null
        raise Error("expected 'true' or 'false' at " + str(t.line) + ":" + str(t.column))
    if t.type == string:
        i += 1
        return tokeniser.unquoted_form(t)
    if t.type == integer:
        i += 1
        return atol(tokeniser.form(t))
    if t.type == real:
        i += 1
        return atof(tokeniser.form(t))
    if tokeniser.form(t) == "{":
        return _parse_json_object(tokeniser, tokens, i)
    if tokeniser.form(t) == "[":
        return _parse_json_array(tokeniser, tokens, i)
    if tokeniser.form(t) == "-":
        i += 1
        t = tokens[i]
        if t.type == integer:
            i += 1
            return -atol(tokeniser.form(t))
        if t.type == real:
            i += 1
            return -atof(tokeniser.form(t))
    raise Error("unexpected value at " + str(t.line) + ":" + str(t.column))
