from memory import UnsafePointer
from .jslib import JS, c_null

struct JSGlobalContext:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self):
        self.ptr = JS.js_global_context_create(c_null)

    fn __copyinit__(inout self, other: JSContext):
        self.ptr = JS.js_global_context_retain(other.ptr)        

    fn __moveinit__(inout self, owned other: JSContext):
        self.ptr = other.ptr
        other.ptr = UnsafePointer[NoneType]()

    fn __del__(owned self):
        if self.ptr:
            JS.js_global_context_release(self.ptr)

    fn get_global_object(self) -> JSObject:
        var js_object = JS.js_context_get_global_object(self.ptr)
        return JSObject(js_object)

struct JSContext:
    var ptr: UnsafePointer[NoneType]

    @implicit
    fn __init__(inout self, ctx: JSGlobalContext):
        self.ptr = ctx.ptr

    @implicit
    fn __init__(inout self, ctx: UnsafePointer[NoneType]):
        self.ptr = ctx
    
    fn get_global_object(self) -> JSObject:
        var js_object = JS.js_context_get_global_object(self.ptr)
        return JSObject(js_object)
