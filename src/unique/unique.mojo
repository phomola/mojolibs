from rc import RC

var strings = Dict[String, InternedString]()

@value
struct InternedString(EqualityComparable):
    var ptr: RC[String]

    fn __init__(inout self, val: String):
        if not strings:
            strings = Dict[String, InternedString]()    # without this, the unit test fails
        var so = strings.get(val)
        if so:
            self.ptr = so.value()[].ptr
        else:
            self.ptr = RC(val)
            strings[val] = self.ptr
    
    fn __eq__(self, istr: Self) -> Bool:
        return self.ptr.pc == istr.ptr.pc

    fn __ne__(self, istr: Self) -> Bool:
        return not (self == istr)

    fn __getitem__(self) -> ref[__lifetime_of(self)] String:
        return self.ptr[]
