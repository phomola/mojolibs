from memory import UnsafePointer
from textkit import CStr
from .jslib import JS, c_null

struct JSObject:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __copyinit__(inout self, other: JSObject):
        self.ptr = other.ptr

    fn __moveinit__(inout self, owned other: JSObject):
        self.ptr = other.ptr

    fn __del__(owned self):
        pass

    fn has_property(self, ctx: JSContext, name: String) -> Bool:
        with CStr(name) as c_name:
            var js_name = JS.js_string_create_with_utf8_string(c_name)
            var exists = JS.js_object_has_property(ctx.ptr, self.ptr, js_name)
            JS.js_string_release(js_name)
            return exists

    fn get_property(self, ctx: JSContext, name: String) -> JSValue:
        with CStr(name) as c_name:
            var js_name = JS.js_string_create_with_utf8_string(c_name)
            var value = JS.js_object_get_property(ctx.ptr, self.ptr, js_name)
            JS.js_string_release(js_name)
            return JSValue(value)

    fn set_property(self, ctx: JSContext, name: String, value: JSValue):
        with CStr(name) as c_name:
            var js_name = JS.js_string_create_with_utf8_string(c_name)
            JS.js_object_set_property(ctx.ptr, self.ptr, js_name, value.ptr, 0, c_null)
            JS.js_string_release(js_name)
