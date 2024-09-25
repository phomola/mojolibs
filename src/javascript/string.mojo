from memory import UnsafePointer
from utils import StringRef
from textkit import CStr
from .jslib import JS, c_null

struct JSString(Stringable,Formattable):
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, string: String):
        with CStr(string) as c_ptr:
            self.ptr = JS.js_string_create_with_utf8_string(c_ptr)

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __copyinit__(inout self, other: JSString):
        self.ptr = JS.js_string_retain(other.ptr)        

    fn __moveinit__(inout self, owned other: JSString):
        self.ptr = other.ptr

    fn __del__(owned self):
        JS.js_string_release(self.ptr)

    fn __str__(self) -> String:
        var max_size = JS.js_string_get_maximum_utf8_cstring_size(self.ptr)
        var buffer = UnsafePointer[UInt8].alloc(max_size)
        _ = JS.js_string_get_utf8_cstring(self.ptr, buffer, max_size)
        var string: String = StringRef(buffer)
        buffer.free()
        return string

    fn format_to(self, inout writer: Formatter):
        writer.write(str(self))
