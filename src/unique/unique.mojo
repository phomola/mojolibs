from utils import Variant
from collections import List, Dict, Optional
from rc import RC
from collections import Dict

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
            strings[val] = InternedString(self.ptr)
    
    fn __eq__(self, istr: Self) -> Bool:
        return self.ptr.pc == istr.ptr.pc

    fn __ne__(self, istr: Self) -> Bool:
        return not (self == istr)

    fn __getitem__(self) -> ref [__origin_of(self.ptr)] String:
        return self.ptr[]
