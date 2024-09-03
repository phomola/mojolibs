from nlp.avm import AVM, AVP
from nlp.chart_parser import Chart, Edge, Grammar, Rule
from textkit import tokenise, Token, word, symbol, string, number, eol, eof
from sys import argv, stderr, exit
from pathlib import Path

fn main():
    var args = argv()
    if len(args) < 3:
        print("expecting two arguments: <grammar file> <chart file>", file=stderr)
        exit(1)
    var grammar_file = args[1]
    # var chart_file = args[2]
    try:
        var p = Path(grammar_file)
        if not p.exists():
            print("file not found:", grammar_file, file=stderr)
            exit(1)
        var grammar = parse_grammar(p.read_text())
        print(grammar)
        # try:
        #     var p = Path(chart_file)
        #     if not p.exists():
        #         print("file not found:", chart_file, file=stderr)
        #         exit(1)
        #     var chart = parse_chart(p.read_text())
        #     print(chart)
        # except e:
        #     print("failed to parse the chart:", str(e), file=stderr)
        #     exit(1)
    except e:
        print("failed to parse the grammar:", str(e), file=stderr)
        exit(1)

fn parse_grammar(input: String) raises -> Grammar:
    var tokens = tokenise(input, word_chars="_'")
    var i = 0
    return _parse_grammar(tokens, i)

fn _parse_grammar(tokens: List[Token], inout i: Int) raises -> Grammar:
    var t = tokens[i]
    var rules = List[Rule]()
    while t.type != eof:
        var rule = _parse_rule(tokens, i)
        rules.append(rule)
        t = tokens[i]
    return Grammar(rules)

fn _parse_rule(tokens: List[Token], inout i: Int) raises -> Rule:
    var t = tokens[i]
    if t.type == eof:
        raise Error("unexpected EOF")
    if t.type != word:
        raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
    var lhs = t.form
    i += 1
    t = tokens[i]
    if t.form != ">":
        raise Error("expected '>' at " + str(t.line) + ":" + str(t.column))
    var rhs = List[String]()
    while True:
        i += 1
        t = tokens[i]
        print("token:", t)
        if t.form == ".":
            i += 1
            fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
                return Optional(avms[0])
            return Rule(lhs, rhs, sameAvm)
        if t.type != word:
            raise Error("expected identifier at " + str(t.line) + ":" + str(t.column))
        rhs.append(t.form)

# fn example_english():
#     var chart = Chart()
#     chart.add(Edge(1, 2, "Det", AVM(List(AVP("def", str("def")))), 0))
#     chart.add(Edge(2, 3, "N", AVM(List(AVP("lemma", str("dog")))), 0))
#     chart.add(Edge(3, 4, "V", AVM(List(AVP("lemma", str("chase")))), 0))
#     chart.add(Edge(4, 5, "Det", AVM(List(AVP("def", str("indef")))), 0))
#     chart.add(Edge(5, 6, "N", AVM(List(AVP("lemma", str("cat")))), 0))
#     print(chart)
#     fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
#         return Optional(avms[0])
#     fn npDetNAvm(avms: List[AVM]) -> Optional[AVM]:
#         return avms[0].unify(avms[1])        
#     fn vpVNpAvm(avms: List[AVM]) -> Optional[AVM]:
#         return avms[0].unify(AVM(AVP("obj", avms[1])))
#     fn sNpVpAvm(avms: List[AVM]) -> Optional[AVM]:
#         return avms[1].unify(AVM(AVP("subj", avms[0])))
#     var grammar = Grammar(List(
#         Rule("NP", List(str("N")), sameAvm),
#         Rule("NP", List(str("Det"), str("N")), npDetNAvm),
#         Rule("VP", List(str("V")), sameAvm),
#         Rule("VP", List(str("V"), str("NP")), vpVNpAvm),
#         Rule("S", List(str("NP"), str("VP")), sNpVpAvm),
#     ))
#     print(grammar)
#     chart.parse(grammar)
#     print(chart)

# fn example_irish1():
#     var chart = Chart()
#     chart.add(Edge(1, 2, "I", AVM(List(AVP("lemma", str("ith")), AVP("tense", str("pres")))), 0))
#     chart.add(Edge(2, 3, "N", AVM(List(AVP("lemma", str("Seán")), AVP("case", str("nom")))), 0))
#     chart.add(Edge(3, 4, "N", AVM(List(AVP("lemma", str("feoil")), AVP("case", str("nom")))), 0))
#     print(chart)
#     fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
#         return Optional(avms[0])
#     fn vpNpAvm(avms: List[AVM]) -> Optional[AVM]:
#         var avmo = avms[0].unify(AVM(AVP("case", str("nom"))))
#         if avmo:
#             return Optional(AVM(AVP("obj", avmo.value()[])))
#         else:
#             return None
#     fn sNpVpAvm(avms: List[AVM]) -> Optional[AVM]:
#         var avmo = avms[0].unify(AVM(AVP("case", str("nom"))))
#         if avmo:
#             return avms[1].unify(AVM(AVP("subj", avmo.value()[])))
#         else:
#             return None
#     fn ipISAvm(avms: List[AVM]) -> Optional[AVM]:
#         return avms[0].unify(avms[1])        
#     var grammar = Grammar(List(
#         Rule("NP", List(str("N")), sameAvm),
#         Rule("VP", List(str("NP")), vpNpAvm),
#         Rule("S", List(str("NP"), str("VP")), sNpVpAvm),
#         Rule("IP", List(str("I"), str("S")), ipISAvm),
#     ))
#     print(grammar)
#     chart.parse(grammar)
#     print(chart)

# fn example_irish2():
#     var chart = Chart()
#     chart.add(Edge(1, 2, "I", AVM(List(AVP("aspect", str("progr")), AVP("tense", str("pres")))), 0))
#     chart.add(Edge(2, 3, "N", AVM(List(AVP("lemma", str("Seán")), AVP("case", str("nom")))), 0))
#     chart.add(Edge(3, 4, "P", AVM(List(AVP("prep", str("ag")))), 0))
#     chart.add(Edge(4, 5, "V", AVM(List(AVP("lemma", str("ith")))), 0))
#     chart.add(Edge(5, 6, "N", AVM(List(AVP("lemma", str("feoil")), AVP("case", str("gen")))), 0))
#     print(chart)
#     fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
#         return Optional(avms[0])
#     fn vbVNpAvm(avms: List[AVM]) -> Optional[AVM]:
#         var avmo = avms[1].unify(AVM(AVP("case", str("gen"))))
#         if avmo:
#             return avms[0].unify(AVM(AVP("obj", avmo.value()[])))
#         else:
#             return None
#     fn vpPVbAvm(avms: List[AVM]) -> Optional[AVM]:
#         var avmo = avms[0].unify(AVM(AVP("prep", str("ag"))))
#         if avmo:
#             return avms[1]
#         else:
#             return None
#     fn sNpVpAvm(avms: List[AVM]) -> Optional[AVM]:
#         var avmo = avms[0].unify(AVM(AVP("case", str("nom"))))
#         if avmo:
#             return avms[1].unify(AVM(AVP("subj", avmo.value()[])))
#         else:
#             return None
#     fn ipISAvm(avms: List[AVM]) -> Optional[AVM]:
#         return avms[0].unify(avms[1])        
#     var grammar = Grammar(List(
#         Rule("NP", List(str("N")), sameAvm),
#         Rule("V'", List(str("V"), str("NP")), vbVNpAvm),
#         Rule("VP", List(str("P"), str("V'")), vpPVbAvm),
#         Rule("S", List(str("NP"), str("VP")), sNpVpAvm),
#         Rule("IP", List(str("I"), str("S")), ipISAvm),
#     ))
#     print(grammar)
#     chart.parse(grammar)
#     print(chart)

# fn main():
#     example_english()
