from collections import List
from utils import StringRef

fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))

fn bytes_from_string(s: String) -> List[UInt8]:
    return s.as_bytes()
