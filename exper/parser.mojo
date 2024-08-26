from utils import Variant
from collections import List, Dict, Optional

@value
struct AVP:
    var attr: String
    var value: Variant[String, AVM]

@value
struct AVM(Stringable):
    var features: Dict[String, Variant[String, AVM]]

    fn __init__(inout self, pairs: List[AVP]):
        self.features = Dict[String, Variant[String, AVM]]()
        for pair in pairs:
            self.features[pair[].attr] = pair[].value

    fn __str__(self) -> String:
        var s: String = "[ "
        for it in self.features.items():
            var sval: String = ""
            var val = it[].value
            if val.isa[String]():
                sval = val[String]
            elif val.isa[AVM]():
                sval = str(val[AVM])
            s += it[].key + ":" + sval + " "
        return s + "]"
    
    fn unify(avm1, avm2: AVM) -> Optional[AVM]:
        var fs = Dict[String, Variant[String, AVM]]()
        for it in avm1.features.items():
            var key = it[].key
            var val1 = it[].value
            var val2_opt = avm2.features.get(key)
            if val2_opt:
                var val2 = val2_opt.value()
                if val1.isa[String]() and val2[].isa[String]():
                    var s1 = val1[String]
                    var s2 = val2[][String]
                    if s1 == s2:
                        fs[key] = s1
                    else:
                        return Optional[AVM](None)
                elif val1.isa[AVM]() and val2[].isa[AVM]():
                    var avm1 = val1[AVM]
                    var avm2 = val2[][AVM]
                    var avm = avm1.unify(avm2)
                    if avm:
                        fs[key] = avm.value()[]
                    else:
                        return Optional[AVM](None)
                else:
                    return Optional[AVM](None)
            else:
                fs[key] = val1
        for it in avm2.features.items():
            var key = it[].key
            if not key in avm1.features:
                fs[key] = it[].value
        return Optional(AVM(fs))

@value
struct Edge(Stringable):
    var start: Int
    var end: Int
    var category: String
    var avm: AVM
    var level: Int

    fn __str__(self) -> String:
        return "-" + str(self.start) + "- " + self.category + " " + str(self.avm) + " -" + str(self.end) + "-"

@value
struct Rule(Stringable):
    var lhs: String
    var rhs: List[String]
    var avmfn: fn(List[AVM]) -> Optional[AVM]

    fn __str__(self) -> String:
        var s: String = self.lhs + " ->"
        for sym in self.rhs:
            s += " " + sym[]
        return s

@value
struct Grammar(Stringable):
    var rules: List[Rule]

    fn __str__(self) -> String:
        var s: String = ""
        for rule in self.rules:
            s += str(rule[]) + "\n"
        return s

@value
struct Chart(Stringable):
    var edges: Dict[Int, List[Edge]]

    fn __str__(self) -> String:
        var s: String = ""
        for edges in self.edges.values():
            for edge in edges[]:
                s += str(edge[]) + "\n"
        return s

    fn __init__(inout self):
        self.edges = Dict[Int, List[Edge]]()
    
    fn add(inout self, edge: Edge):
        var edges_opt = self.edges.get(edge.start)
        if edges_opt:
            var edges = edges_opt.value()
            edges[].append(edge)
            self.edges[edge.start] = edges # this will be optimised in a future Mojo release
        else:
            self.edges[edge.start] = List(edge)
    
    fn parse(inout self, grammar: Grammar):
        var level = 0
        while True:
            var extended = self._parse(grammar, level)
            if not extended:
                return
            level += 1

    fn _parse(inout self, grammar: Grammar, level: Int) -> Bool:
        var newEdges = List[Edge]()
        for edges in self.edges.values():
            for edge1 in edges[]:
                for rule in grammar.rules:
                    if rule[].rhs.size == 1:
                        if edge1[].level == level:
                            if edge1[].category == rule[].rhs[0]:
                                var avm_opt = rule[].avmfn(List(edge1[].avm))
                                if avm_opt:
                                    var avm = avm_opt.value()
                                    var edge = Edge(edge1[].start, edge1[].end, rule[].lhs, avm[], level + 1)
                                    newEdges.append(edge)
                    elif rule[].rhs.size == 2:
                        var edges_opt = self.edges.get(edge1[].end)
                        if edges_opt:
                            for edge2 in edges_opt.value()[]:
                                if edge1[].level == level or edge2[].level == level:
                                    if edge1[].category == rule[].rhs[0] and edge2[].category == rule[].rhs[1]:
                                        var avm_opt = rule[].avmfn(List(edge1[].avm, edge2[].avm))
                                        if avm_opt:
                                            var avm = avm_opt.value()
                                            var edge = Edge(edge1[].start, edge2[].end, rule[].lhs, avm[], level + 1)
                                            newEdges.append(edge)
                    else:
                        print("rule not supported: " + str(rule[]))
        for edge in newEdges:
            self.add(edge[])
        return newEdges.size > 0

fn example_english():
    var chart = Chart()
    chart.add(Edge(1, 2, "Det", AVM(List(AVP("def", str("def")))), 0))
    chart.add(Edge(2, 3, "N", AVM(List(AVP("lemma", str("dog")))), 0))
    chart.add(Edge(3, 4, "V", AVM(List(AVP("lemma", str("chase")))), 0))
    chart.add(Edge(4, 5, "Det", AVM(List(AVP("def", str("indef")))), 0))
    chart.add(Edge(5, 6, "N", AVM(List(AVP("lemma", str("cat")))), 0))
    print(chart)
    fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
        return Optional(avms[0])
    fn npDetNAvm(avms: List[AVM]) -> Optional[AVM]:
        return avms[0].unify(avms[1])        
    fn vpVNpAvm(avms: List[AVM]) -> Optional[AVM]:
        return avms[0].unify(AVM(AVP("obj", avms[1])))
    fn sNpVpAvm(avms: List[AVM]) -> Optional[AVM]:
        return avms[1].unify(AVM(AVP("subj", avms[0])))
    var grammar = Grammar(List(
        Rule("NP", List(str("N")), sameAvm),
        Rule("NP", List(str("Det"), str("N")), npDetNAvm),
        Rule("VP", List(str("V")), sameAvm),
        Rule("VP", List(str("V"), str("NP")), vpVNpAvm),
        Rule("S", List(str("NP"), str("VP")), sNpVpAvm),
    ))
    print(grammar)
    chart.parse(grammar)
    print(chart)

fn example_irish1():
    var chart = Chart()
    chart.add(Edge(1, 2, "I", AVM(List(AVP("lemma", str("ith")), AVP("tense", str("pres")))), 0))
    chart.add(Edge(2, 3, "N", AVM(List(AVP("lemma", str("Seán")), AVP("case", str("nom")))), 0))
    chart.add(Edge(3, 4, "N", AVM(List(AVP("lemma", str("feoil")), AVP("case", str("nom")))), 0))
    print(chart)
    fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
        return Optional(avms[0])
    fn vpNpAvm(avms: List[AVM]) -> Optional[AVM]:
        var avmo = avms[0].unify(AVM(AVP("case", str("nom"))))
        if avmo:
            return Optional(AVM(AVP("obj", avmo.value()[])))
        else:
            return Optional[AVM](None)
    fn sNpVpAvm(avms: List[AVM]) -> Optional[AVM]:
        var avmo = avms[0].unify(AVM(AVP("case", str("nom"))))
        if avmo:
            return avms[1].unify(AVM(AVP("subj", avmo.value()[])))
        else:
            return Optional[AVM](None)
    fn ipISAvm(avms: List[AVM]) -> Optional[AVM]:
        return avms[0].unify(avms[1])        
    var grammar = Grammar(List(
        Rule("NP", List(str("N")), sameAvm),
        Rule("VP", List(str("NP")), vpNpAvm),
        Rule("S", List(str("NP"), str("VP")), sNpVpAvm),
        Rule("IP", List(str("I"), str("S")), ipISAvm),
    ))
    print(grammar)
    chart.parse(grammar)
    print(chart)

fn example_irish2():
    var chart = Chart()
    chart.add(Edge(1, 2, "I", AVM(List(AVP("aspect", str("progr")), AVP("tense", str("pres")))), 0))
    chart.add(Edge(2, 3, "N", AVM(List(AVP("lemma", str("Seán")), AVP("case", str("nom")))), 0))
    chart.add(Edge(3, 4, "P", AVM(List(AVP("prep", str("ag")))), 0))
    chart.add(Edge(4, 5, "V", AVM(List(AVP("lemma", str("ith")))), 0))
    chart.add(Edge(5, 6, "N", AVM(List(AVP("lemma", str("feoil")), AVP("case", str("gen")))), 0))
    print(chart)
    fn sameAvm(avms: List[AVM]) -> Optional[AVM]:
        return Optional(avms[0])
    fn vbVNpAvm(avms: List[AVM]) -> Optional[AVM]:
        var avmo = avms[1].unify(AVM(AVP("case", str("gen"))))
        if avmo:
            return avms[0].unify(AVM(AVP("obj", avmo.value()[])))
        else:
            return Optional[AVM](None)
    fn vpPVbAvm(avms: List[AVM]) -> Optional[AVM]:
        var avmo = avms[0].unify(AVM(AVP("prep", str("ag"))))
        if avmo:
            return avms[1]
        else:
            return Optional[AVM](None)
    fn sNpVpAvm(avms: List[AVM]) -> Optional[AVM]:
        var avmo = avms[0].unify(AVM(AVP("case", str("nom"))))
        if avmo:
            return avms[1].unify(AVM(AVP("subj", avmo.value()[])))
        else:
            return Optional[AVM](None)
    fn ipISAvm(avms: List[AVM]) -> Optional[AVM]:
        return avms[0].unify(avms[1])        
    var grammar = Grammar(List(
        Rule("NP", List(str("N")), sameAvm),
        Rule("V'", List(str("V"), str("NP")), vbVNpAvm),
        Rule("VP", List(str("P"), str("V'")), vpPVbAvm),
        Rule("S", List(str("NP"), str("VP")), sNpVpAvm),
        Rule("IP", List(str("I"), str("S")), ipISAvm),
    ))
    print(grammar)
    chart.parse(grammar)
    print(chart)

fn main():
    # example_english()
    example_irish1()
