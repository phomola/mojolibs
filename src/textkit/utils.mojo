from collections import List
from utils import StringRef
from memory import UnsafePointer, memcpy

fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))

fn string_from_bytes(b: List[UInt8], l: Int) -> String:
    return str(StringRef(b.data, l))

fn bytes_from_string(s: String) -> List[UInt8]:
    return s.as_bytes()

struct CStr:
    var ptr: UnsafePointer[UInt8]

    fn __init__(inout self, s: String):
        var ptr = UnsafePointer[UInt8].alloc(len(s) + 1)
        memcpy(ptr, s.unsafe_ptr(), len(s))
        ptr[len(s)] = 0
        self.ptr = ptr

    fn __enter__(self) -> UnsafePointer[UInt8]:
        return self.ptr

    fn __exit__(inout self):
        self.ptr.free()
        self.ptr = UnsafePointer[UInt8]()

    fn __del__(owned self):
        if self.ptr:
            self.ptr.free()
