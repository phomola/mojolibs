struct BytesReader(Reader):
    var data: List[UInt8]

    fn __init__(inout self, owned data: List[UInt8]):
        self.data = data^

    fn __moveinit__(inout self, owned reader: Self):
        self.data = reader.data^

    fn read_bytes(inout self, n: Int) raises -> List[UInt8]:
        if len(self.data) < n:
            var r = self.data^
            self.data = List[UInt8]()
            return r
        var r = self.data[:n]
        self.data = self.data[n:]
        return r
