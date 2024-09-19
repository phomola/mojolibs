from utils import Variant
from collections import List, Dict, Optional
from nlp.avm import AVM

@value
struct Tree:
    var root: String
    var children: Optional[List[Tree]]

    fn __str__(self) -> String:
        var s = self.root
        if self.children:
            s += "("
            var first = True
            for child in self.children.value():
                if first:
                    first = False
                else:
                    s += ","
                s += str(child[])
            s += ")"
        return s

@value
struct Edge(Stringable):
    var start: Int
    var end: Int
    var category: String
    var avm: AVM
    var level: Int
    var used: Bool
    var tree: Tree

    fn __str__(self) -> String:
        return "-" + str(self.start) + "- " + str(self.tree) + " " + str(self.avm) + " -" + str(self.end) + "-"

@value
struct Rule(Stringable):
    var lhs: String
    var rhs: List[String]
    var avmfn: fn(List[AVM]) escaping -> Optional[AVM]

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
                if not edge[].used:
                    s += str(edge[]) + "\n"
        return s

    fn __init__(inout self):
        self.edges = Dict[Int, List[Edge]]()
    
    fn add(inout self, edge: Edge):
        var edges_opt = self.edges.get(edge.start)
        if edges_opt:
            var edges = edges_opt.value()
            edges.append(edge)
            self.edges[edge.start] = edges # this shall be optimised in a future Mojo release
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
                                    edge1[].used = True
                                    var avm = avm_opt.value()
                                    var edge = Edge(edge1[].start, edge1[].end, rule[].lhs, avm, level + 1, False, Tree(rule[].lhs, List(edge1[].tree)))
                                    newEdges.append(edge)
                    elif rule[].rhs.size == 2:
                        var edges_opt = self.edges.get(edge1[].end)
                        if edges_opt:
                            for edge2 in edges_opt.value():
                                if edge1[].level == level or edge2[].level == level:
                                    if edge1[].category == rule[].rhs[0] and edge2[].category == rule[].rhs[1]:
                                        var avm_opt = rule[].avmfn(List(edge1[].avm, edge2[].avm))
                                        if avm_opt:
                                            edge1[].used = True
                                            edge2[].used = True
                                            var avm = avm_opt.value()
                                            var edge = Edge(edge1[].start, edge2[].end, rule[].lhs, avm, level + 1, False, Tree(rule[].lhs, List(edge1[].tree, edge2[].tree)))
                                            newEdges.append(edge)
                    else:
                        print("rule not supported: " + str(rule[]))
        for edge in newEdges:
            self.add(edge[])
        return newEdges.size > 0
