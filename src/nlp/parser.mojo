from nlp import AVM, AVP, Chart, Edge, Grammar, Rule
from textkit import tokenise, Token, word, symbol, string, number, eol, eof
from sys import argv, stderr, exit
from pathlib import Path
from utils import Variant
from collections import List, Dict, Optional
from textkit import bytes_from_string
from memory import Arc

fn parse_grammar(input: String) raises -> Grammar:
    return parse_grammar(bytes_from_string(input))

fn parse_grammar(input: List[UInt8]) raises -> Grammar:
    var tokens = tokenise(input, word_chars="_'")
    var i = 0
    return _parse_grammar(tokens, i)

fn parse_chart(input: String) raises -> Chart:
    return parse_chart(bytes_from_string(input))

fn parse_chart(input: List[UInt8]) raises -> Chart:
    var tokens = tokenise(input, word_chars="_'")
    var i = 0
    return _parse_chart(tokens, i)

fn _parse_grammar(tokens: List[Token], inout i: Int) raises -> Grammar:
    var rules = List[Rule]()
    while True:
        var rule = _parse_rule(tokens, i)
        if rule:
            rules.append(rule.value())
        else:
            break
    return Grammar(rules)

fn _parse_rule(tokens: List[Token], inout i: Int) raises -> Optional[Rule]:
    var t = tokens[i]
    if t.type == eof:
        return None
    if t.type != word:
        raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
    var lhs = t.form
    i += 1
    t = tokens[i]
    if t.form != ">":
        raise Error("expected '>' at " + str(t.line) + ":" + str(t.column))
    var rhs = List[String]()
    var idx = 0
    i += 1
    t = tokens[i]
    var annotations = List[Annotation]()
    while True:
        if t.form == ".":
            i += 1
            fn f(avms: List[AVM]) -> Optional[AVM]:
                var avm = AVM(Dict[String, Variant[String, AVM]]())
                for annotation in annotations:
                    if len(annotation[].path) == 0:
                        var avm_opt = avm.unify(avms[annotation[].idx])
                        if avm_opt:
                            avm = avm_opt.value()
                        else:
                            return None
                    else:
                        if annotation[].value == "":
                            var avm_opt = avm.unify(annotation[].get_avm(avms[annotation[].idx]))
                            if avm_opt:
                                avm = avm_opt.value()
                            else:
                                return None
                        else:
                            var avm_opt = avm.unify(annotation[].get_avm(annotation[].value))
                            if avm_opt:
                                avm = avm_opt.value()
                            else:
                                return None
                return avm
            return Rule(lhs, rhs, f)
        if t.type != word:
            raise Error("expected identifier or '.' at " + str(t.line) + ":" + str(t.column))
        rhs.append(t.form)
        i += 1
        for annotation in _parse_annotations(tokens, i, idx):
            annotations.append(annotation[])
        t = tokens[i]
        idx += 1

@value
struct Annotation:
    var idx: Int
    var path: List[String]
    var value: String

    fn get_avm(self, value: Variant[String, AVM]) -> AVM:
        var avm = AVM(AVP(self.path[len(self.path)-1], value))
        for i in range(len(self.path)-2, -1, -1):
            avm = AVM(AVP(self.path[i], avm))
        return avm

fn _parse_annotations(tokens: List[Token], inout i: Int, idx: Int) raises -> List[Annotation]:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.form != "(":
        raise Error("expected '(' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var annotations = List[Annotation]()
    while True:
        if t.form == ")":
            i += 1
            return annotations
        if t.form == "=":
            annotations.append(Annotation(idx, List[String](), ""))
        elif t.form == ">":
            i += 1
            t = tokens[i]
            if t.type != word:
                raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
            annotations.append(Annotation(idx, List(t.form), ""))
        elif t.type == word:
            var path = List[String]()
            while True:
                if t.type != word:
                    raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
                path.append(t.form)
                i += 1
                t = tokens[i]
                if t.form == ".":
                    i += 1
                    t = tokens[i]
                elif t.form == "=":
                    break
                else:
                    raise Error("expected '=' or '.' at " + str(t.line) + ":" + str(t.column))
            i += 1
            t = tokens[i]
            if t.type != word:
                raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
            var value = t.form
            annotations.append(Annotation(idx, path, value))
        else:
            raise Error("expected '=', '>', ')' or identifier at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]

fn _parse_chart(tokens: List[Token], inout i: Int) raises -> Chart:
    var chart = Chart()
    while True:
        var edge = _parse_edge(tokens, i)
        if edge:
            chart.add(edge.value())
        else:
            break
    return chart

fn _parse_edge(tokens: List[Token], inout i: Int) raises -> Optional[Edge]:
    var t = tokens[i]
    if t.type == eof:
        return None
    if t.form != "-":
        raise Error("expected '-' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    if t.type != number:
        raise Error("expected number at " + str(t.line) + ":" + str(t.column))
    var start = atol(t.form)
    i += 1
    t = tokens[i]
    if t.form != "-":
        raise Error("expected '-' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    if t.type != word:
        raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
    var cat = t.form
    i += 1
    var avm = _parse_avm(tokens, i)
    t = tokens[i]
    if t.form != "-":
        raise Error("expected '-' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    if t.type != number:
        raise Error("expected number at " + str(t.line) + ":" + str(t.column))
    var end = atol(t.form)
    i += 1
    t = tokens[i]
    if t.form != "-":
        raise Error("expected '-' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    return Edge(start, end, cat, avm, 0, False, List[Arc[Edge]]())

fn _parse_avm(tokens: List[Token], inout i: Int) raises -> AVM:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.form != "[":
        raise Error("expected '[' at " + str(t.line) + ":" + str(t.column))
    i += 1
    t = tokens[i]
    var features = Dict[String, Variant[String, AVM]]()
    while True:
        if t.form == "]":
            i += 1
            return AVM(features)
        if t.type != word:
            raise Error("expected identifier  or ']' at " + str(t.line) + ":" + str(t.column))
        var key = t.form
        i += 1
        t = tokens[i]
        if t.form != ":":
            raise Error("expected ':' at " + str(t.line) + ":" + str(t.column))
        i += 1
        t = tokens[i]
        if t.type != string:
            raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
        var value = t.form
        features[key] = value
        i += 1
        t = tokens[i]
