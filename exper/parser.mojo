from nlp import parse_grammar, parse_chart, AVM, AVP, Chart, Edge, Grammar, Rule
from sys import argv, stderr, exit
from pathlib import Path
from utils import Variant
from collections import List, Dict, Optional

fn main():
    var args = argv()
    if len(args) < 3:
        print("expecting two arguments: <grammar file> <chart file>", file=stderr)
        exit(1)
    var grammar_file = args[1]
    var chart_file = args[2]
    try:
        var p = Path(grammar_file)
        if not p.exists():
            print("file not found:", grammar_file, file=stderr)
            exit(1)
        var grammar = get_grammar(p.read_bytes())
        print("grammar:")
        print(grammar)

        p = Path(chart_file)
        if not p.exists():
            print("file not found:", chart_file, file=stderr)
            exit(1)
        var chart = get_chart(p.read_bytes())
        print("initial chart:")
        print(chart)
        
        chart.parse(grammar)
        print("final chart:")
        print(chart)
    except e:
        print(e, file=stderr)
        exit(1)        

fn get_grammar(code: List[UInt8]) raises -> Grammar:
    try:
        return parse_grammar(code)
    except e:
        raise Error("failed to parse grammar: " + str(e))

fn get_chart(code: List[UInt8]) raises -> Chart:
    try:
        return parse_chart(code)
    except e:
        raise Error("failed to parse chart: " + str(e))
