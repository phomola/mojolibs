from utils import Variant
from collections import List, Dict, Optional
from rc import RC

var strings = Dict[String, InternedString]()

# without this, the unit test fails
fn init_global_vars():
    if not strings:
        strings = Dict[String, InternedString]()

@value
struct InternedString(EqualityComparable):
    var ptr: RC[String]

    fn __init__(inout self, val: String):
        var so = strings.get(val)
        if so:
            self.ptr = so.value().ptr
        else:
            self.ptr = RC(val)
            strings[val] = self.ptr
    
    fn __eq__(self, istr: Self) -> Bool:
        return self.ptr.pc == istr.ptr.pc

    fn __ne__(self, istr: Self) -> Bool:
        return not (self == istr)

    fn __getitem__(self) -> String:
        return self.ptr[]
