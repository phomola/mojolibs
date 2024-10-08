from textkit import string_from_bytes, stringref_from_bytes
from utils import StringRef

struct StringBuilder(Writer, Stringable, Formattable):
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

    fn format_to(self, inout writer: Formatter):
        writer.write(self.as_string_ref())
    
    fn keep_alive(self):
        pass
