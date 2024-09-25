from memory import UnsafePointer
from .jslib import c_null

struct JSValue:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __copyinit__(inout self, other: JSValue):
        self.ptr = other.ptr

    fn __moveinit__(inout self, owned other: JSValue):
        self.ptr = other.ptr

    fn __del__(owned self):
        pass

    fn protect(self, ctx: JSContext):
        JS.js_value_protect(ctx.ptr, self.ptr)

    fn unprotect(self, ctx: JSContext):
        JS.js_value_unprotect(ctx.ptr, self.ptr)

    fn is_string(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_string(ctx.ptr, self.ptr)

    fn to_string(self, ctx: JSContext) raises -> JSString:
        var js_string = JS.js_value_to_string_copy(ctx.ptr, self.ptr, c_null)
        if not js_string:
            raise Error("JS string copy failed")
        return JSString(js_string)
