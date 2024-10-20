from textkit import string_from_bytes, stringref_from_bytes
from utils import StringRef

struct StringBuilder(IOWriter, Stringable, Writable):
    var buffer: List[UInt8]

    fn __init__(inout self):
        self.buffer = List[UInt8]()

    fn __moveinit__(inout self, owned sb: Self):
        self.buffer = sb.buffer^

    fn write_bytes(inout self, list: List[UInt8]) raises:
        self.buffer.extend(list)

    fn as_string_ref(self) -> StringRef:
        return stringref_from_bytes(self.buffer)

    fn __str__(self) -> String:
        return string_from_bytes(self.buffer)

    fn write_to[W: Writer](self, inout writer: W):
        writer.write(self.as_string_ref())
    
    fn keep_alive(self):
        pass
