@value
struct Term(Hashable, EqualityComparable, Stringable, Writable):
    var functor: String
    var args: List[Term]

    fn __init__(inout self, functor: String):
        self.functor = functor
        self.args = List[Term]()

    fn __eq__(self, other: Self) -> Bool:
        if self.functor != other.functor:
            return False
        if len(self.args) != len(other.args):
            return False
        for i in range(len(self.args)):
            if self.args[i] != other.args[i]:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __hash__(self) -> UInt:
        return hash(self.functor)

    fn __str__(self) -> String:
        var s = self.functor
        if len(self.args) > 0:
            s += "("
            var first = True
            for arg in self.args:
                if first:
                    first = False
                else:
                    s += ", "
                s += str(arg[])
            s += ")"
        return s

    fn write_to[W: Writer](self, inout writer: W):
        writer.write(self.functor)
        if len(self.args) > 0:
            writer.write("(")
            var first = True
            for arg in self.args:
                if first:
                    first = False
                else:
                    writer.write(", ")
                arg[].write_to(writer)
            writer.write(")")
