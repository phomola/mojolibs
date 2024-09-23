from testing import assert_equal, assert_true, assert_false
from nlp.parser import parse_grammar, parse_chart

fn test_parse_chart() raises:
    grammar = parse_grammar("""
        S > NP (>subj) VP (= subj.case=nom).
        NP > N (=).
        NP > Det (=) N (=).
        VP > V (=).
        VP > V (= obj.case=acc) NP (>obj).
    """)
