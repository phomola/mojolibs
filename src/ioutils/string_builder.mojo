from textkit import string_from_bytes

struct StringBuilder(Writer, Stringable):
    var buffer: List[UInt8]

    fn __init__(inout self):
        self.buffer = List[UInt8]()

    fn __moveinit__(inout self, owned sb: Self):
        self.buffer = sb.buffer^

    fn write_bytes(inout self, list: List[UInt8]) raises:
        self.buffer.extend(list)

    fn __str__(self) -> String:
        return string_from_bytes(self.buffer)
