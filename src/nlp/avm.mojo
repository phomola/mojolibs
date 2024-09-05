from utils import Variant
from collections import List, Dict, Optional

@value
struct AVP:
    var attr: String
    var value: Variant[String, AVM]

struct AVM(Stringable):
    var features: Dict[String, Variant[String, AVM]]

    fn __init__(inout self, owned features: Dict[String, Variant[String, AVM]]):
        self.features = features^

    fn __init__(inout self, pairs: List[AVP]):
        self.features = Dict[String, Variant[String, AVM]]()
        for pair in pairs:
            self.features[pair[].attr] = pair[].value

    fn __copyinit__(inout self, avm: AVM):
        self.features = avm.features

    fn __moveinit__(inout self, owned avm: AVM):
        self.features = avm.features^

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
                        return None
                elif val1.isa[AVM]() and val2[].isa[AVM]():
                    var avm1 = val1[AVM]
                    var avm2 = val2[][AVM]
                    var avm = avm1.unify(avm2)
                    if avm:
                        fs[key] = avm.value()[]
                    else:
                        return None
                else:
                    return None
            else:
                fs[key] = val1
        for it in avm2.features.items():
            var key = it[].key
            if not key in avm1.features:
                fs[key] = it[].value
        return AVM(fs)

