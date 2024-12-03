from collections import List
from utils import StringRef
from memory import UnsafePointer, memcpy
from sys.ffi import c_char

fn string_from_bytes(b: List[Byte]) -> String:
    return StringRef(b.data.bitcast[c_char](), len(b))

fn string_from_bytes(b: List[c_char]) -> String:
    return StringRef(b.data, len(b))

fn string_from_bytes(b: List[Byte], l: Int) -> String:
    return StringRef(b.data.bitcast[c_char](), l)

fn string_from_bytes(b: List[c_char], l: Int) -> String:
    return StringRef(b.data, l)

fn stringref_from_bytes(b: List[Byte]) -> StringRef:
    return StringRef(b.data.bitcast[c_char](), len(b))

fn stringref_from_bytes(b: List[c_char]) -> StringRef:
    return StringRef(b.data, len(b))

fn stringref_from_bytes(b: List[Byte], l: Int) -> StringRef:
    return StringRef(b.data.bitcast[c_char](), l)

fn stringref_from_bytes(b: List[c_char], l: Int) -> StringRef:
    return StringRef(b.data, l)

fn bytes_from_string(s: String) -> List[Byte]:
    return s.as_bytes()

struct CStr:
    var ptr: UnsafePointer[c_char]

    fn __init__(inout self, s: String):
        var ptr = UnsafePointer[c_char].alloc(len(s) + 1)
        memcpy(ptr, s.unsafe_ptr().bitcast[c_char](), len(s))
        ptr[len(s)] = 0
        self.ptr = ptr

    fn __enter__(self) -> UnsafePointer[c_char]:
        return self.ptr

    fn __exit__(inout self):
        self.ptr.free()
        self.ptr = UnsafePointer[c_char]()

    fn __del__(owned self):
        if self.ptr:
            self.ptr.free()
