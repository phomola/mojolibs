from utils import Variant
from collections import List, Dict, Optional
from textkit.utils import string_from_bytes, bytes_from_string

alias comma = ord(",")
alias newline = ord("\n")
alias quote = ord("\"")

fn parse_csv(input: String) -> List[List[String]]:
    return parse_csv_bytes(bytes_from_string(input))

fn parse_csv_bytes(input: List[UInt8]) -> List[List[String]]:
    var rows = List[List[String]]()
    var i = 0
    var quoted = False
    var has_quotes = False
    var row = List[String]()
    var start = 0
    while i < len(input):
        var c = input[i]
        if not quoted:
            if c == comma:
                if start < i:
                    row.append(string_from_bytes(input[start:i]))
                i += 1
                start = i
            elif c == newline:
                if start < i:
                    row.append(string_from_bytes(input[start:i]))
                i += 1
                start = i
                rows.append(row)
                row = List[String]()
            elif c == quote:
                quoted = True
                has_quotes = False
                i += 1
                start = i
            else:
                i += 1
        else:
            if c == quote:
                if i+1 < len(input) and input[i+1] == quote:
                    i += 2
                    has_quotes = True
                else:
                    row.append(string_from_bytes(input[start:i]) if not has_quotes else string_from_bytes(input[start:i]).replace("\"\"", "\""))
                    quoted = False
                    i += 1
                    start = i
            else:
                i += 1
    if i > start:
        row.append(string_from_bytes(input[start:i]))
    if len(row) > 0:
        rows.append(row)
    return rows