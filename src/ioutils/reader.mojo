trait Reader(Movable):
    fn read_bytes(inout self, n: Int) raises -> List[UInt8]:
        ...

alias buffer_size = 1_024

fn read_all[T: Reader](inout reader: T) raises -> List[UInt8]:
    var list = List[UInt8]()
    while True:
        var list2 = reader.read_bytes(buffer_size)
        if len(list2) == 0:
            return list
        list.extend(list2)

struct BufferedReader[T: Reader](Reader):
    var reader: T
    var buffer: List[UInt8]

    fn __init__(inout self, owned reader: T):
        self.reader = reader^
        self.buffer = List[UInt8]()

    fn __moveinit__(inout self, owned reader: Self):
        self.reader = reader.reader^
        self.buffer = reader.buffer^

    fn read_bytes(inout self, n: Int) raises -> List[UInt8]:
        if len(self.buffer) > 0:
            if len(self.buffer) <= n:
                var r = self.buffer^
                self.buffer = List[UInt8]()
                return r
            var r = self.buffer[:n]
            self.buffer = self.buffer[n:]
            return r
        self.buffer = self.reader.read_bytes(n if n > buffer_size else buffer_size)
        return self.read_bytes(n)

    fn read_until(inout self, ch: UInt8) raises -> Tuple[List[UInt8], Bool]:
        var list = List[UInt8]()
        if len(self.buffer) > 0:
            for i in range(len(self.buffer)):
                if self.buffer[i] == ch:
                    var r = self.buffer[:i+1]
                    self.buffer = self.buffer[i+1:]
                    return r, True
            list.extend(self.buffer^)
            self.buffer = List[UInt8]()
        while True:
            var list2 = self.reader.read_bytes(buffer_size)
            if len(list2) == 0:
                return list, False
            for i in range(len(list2)):
                if list2[i] == ch:
                    list.extend(list2[:i+1])
                    self.buffer = list2[i+1:]
                    return list, True
            list.extend(list2)
