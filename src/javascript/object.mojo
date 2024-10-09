from memory import UnsafePointer
from textkit import CStr
from .jslib import JS, c_null

struct JSObject:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __init__(inout self, value: JSValue):
        self.ptr = value.ptr

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

    fn call(self, ctx: JSContext) raises -> JSValue:
        var args = UnsafePointer[UnsafePointer[NoneType]]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 0, args, c_null)
        if not value:
            raise Error("failed to call object as function")
        return JSValue(value)

    fn call(self, ctx: JSContext, arg1: JSValue) raises -> JSValue:
        var args = UnsafePointer[UnsafePointer[NoneType]].alloc(1)
        args[0] = arg1.ptr
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 1, args, c_null)
        args.free()
        if not value:
            raise Error("failed to call object as function")
        return JSValue(value)

    fn call(self, ctx: JSContext, arg1: JSValue, arg2: JSValue) raises -> JSValue:
        var args = UnsafePointer[UnsafePointer[NoneType]].alloc(2)
        args[0] = arg1.ptr
        args[1] = arg2.ptr
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 2, args, c_null)
        args.free()
        if not value:
            raise Error("failed to call object as function")
        return JSValue(value)
