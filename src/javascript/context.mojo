from memory import UnsafePointer
from .jslib import c_null

struct JSContext:
    var ptr: UnsafePointer[NoneType]

    @staticmethod
    fn create_global() -> JSContext:
        return JSContext(JS.js_global_context_create(c_null))

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __copyinit__(inout self, other: JSContext):
        self.ptr = JS.js_global_context_retain(other.ptr)        

    fn __moveinit__(inout self, owned other: JSContext):
        self.ptr = other.ptr

    fn __del__(owned self):
        JS.js_global_context_release(self.ptr)
