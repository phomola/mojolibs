from memory import UnsafePointer
from .jslib import JS, c_null
from utils.numerics import isnan
from textkit import CStr

struct JSValue:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __init__(inout self, object: JSObject):
        self.ptr = object.ptr

    fn __init__(inout self, ctx: JSContext, number: Float64):
        self.ptr = JS.js_value_make_number(ctx.ptr, number)

    fn __init__(inout self, ctx: JSContext, string: String):
        with CStr(string) as c_string:
            var js_string = JS.js_string_create_with_utf8_string(c_string)
            self.ptr = JS.js_value_make_string(ctx.ptr, js_string)
            JS.js_string_release(js_string)

    fn __copyinit__(inout self, other: JSValue):
        self.ptr = other.ptr

    fn __moveinit__(inout self, owned other: JSValue):
        self.ptr = other.ptr

    fn __del__(owned self):
        pass

    fn as_string(self, ctx: JSContext) raises -> String:
        if self.is_undefined(ctx):
            return "undefined"
        if self.is_null(ctx):
            return "null"
        if self.is_string(ctx):
            return str(self.to_string(ctx))
        if self.is_number(ctx):
            return str(self.to_number(ctx))
        if self.is_object(ctx):
            return "object"
        return "???"

    fn protect(self, ctx: JSContext):
        JS.js_value_protect(ctx.ptr, self.ptr)

    fn unprotect(self, ctx: JSContext):
        JS.js_value_unprotect(ctx.ptr, self.ptr)

    fn keep_alive(self):
        pass

    fn is_null(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_null(ctx.ptr, self.ptr)

    fn is_undefined(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_undefined(ctx.ptr, self.ptr)

    fn is_string(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_string(ctx.ptr, self.ptr)

    fn is_number(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_number(ctx.ptr, self.ptr)

    fn is_object(self, ctx: JSContext) -> Bool:
        return JS.js_value_is_object(ctx.ptr, self.ptr)

    fn to_string(self, ctx: JSContext) raises -> JSString:
        var js_string = JS.js_value_to_string_copy(ctx.ptr, self.ptr, c_null)
        if not js_string:
            raise Error("JS string conversion failed")
        return JSString(js_string)

    fn to_number(self, ctx: JSContext) raises -> Float64:
        var number = JS.js_value_to_number(ctx.ptr, self.ptr, c_null)
        if isnan(number):
            raise Error("JS number conversion failed")
        return number

    fn to_object(self, ctx: JSContext) raises -> JSObject:
        var js_object = JS.js_value_to_object(ctx.ptr, self.ptr, c_null)
        if not js_object:
            raise Error("JS object conversion failed")
        return JSObject(js_object)
