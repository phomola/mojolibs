from memory import UnsafePointer
from .jslib import c_null

struct JSValue:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    # fn __copyinit__(inout self, other: JSContext):
    #     self.ptr = JS.js_global_context_retain(other.ptr)        

    # fn __moveinit__(inout self, owned other: JSContext):
    #     self.ptr = other.ptr

    # fn __del__(owned self):
    #     JS.js_global_context_release(self.ptr)

    fn is_string(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_string(ctx.ptr, self.ptr)

    fn to_string(self, ctx: JSContext) raises -> JSString:
        var js_string = JS.js_value_to_string_copy(ctx.ptr, self.ptr, c_null)
        if js_string == c_null:
            raise Error("JS string copy failed")
        return JSString(js_string)
