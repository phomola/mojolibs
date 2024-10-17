from memory import UnsafePointer
from textkit import CStr
from .jslib import JS, c_null
from collections import InlineArray, Dict

var funcs = Dict[Int, fn(JSContext, JSObject, List[JSValue]) raises -> JSValue]()

fn js_func_cb(ctx: UnsafePointer[NoneType], f: UnsafePointer[NoneType], this: UnsafePointer[NoneType], argcount: Int, js_args: UnsafePointer[UnsafePointer[NoneType]], ex: UnsafePointer[UnsafePointer[NoneType]]) -> UnsafePointer[NoneType]:
    var f_opt = funcs.get(int(f))
    if f_opt:
        var f = f_opt.value()
        var args = List[JSValue](capacity=argcount)
        for i in range(argcount):
            args.append(JSValue(js_args[i]))
        try:
            var value = f(JSContext(ctx), JSObject(this), args)
            return value.ptr
        except e:
            ex[] = make_js_error(ctx, e).ptr
            return UnsafePointer[NoneType]()
    else:
        ex[] = make_js_error(ctx, "JS callback not found").ptr
        return UnsafePointer[NoneType]()

fn make_js_error(ctx: JSContext, error: Error) -> JSValue:
    var object = JSObject(ctx)
    object.set_property(ctx, "message", JSValue(ctx, str(error)))
    return object

struct JSObject:
    var ptr: UnsafePointer[NoneType]

    @staticmethod
    fn promise(ctx: JSContext) raises -> Tuple[JSObject, JSObject, JSObject]:
        var resolve = UnsafePointer[NoneType]()
        var reject = UnsafePointer[NoneType]()
        var ex = UnsafePointer[NoneType]()
        var promise = JS.js_object_make_deferred_promise(ctx.ptr, UnsafePointer.address_of(resolve), UnsafePointer.address_of(reject), UnsafePointer.address_of(ex))
        if not promise:
            raise Error("failed to create promise: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSObject(promise), JSObject(resolve), JSObject(reject)

    fn __init__(inout self, ctx: JSContext):
        self.ptr = JS.js_object_make(ctx.ptr, c_null, c_null)

    fn __init__(inout self, ptr: UnsafePointer[NoneType]):
        self.ptr = ptr

    fn __init__(inout self, value: JSValue):
        self.ptr = value.ptr

    fn __init__(inout self, ctx: JSContext, name: String, f: fn(JSContext, JSObject, List[JSValue]) raises -> JSValue):
        with CStr(name) as c_name:
            var js_name = JS.js_string_create_with_utf8_string(c_name)
            var jsf = JS.js_object_make_function_with_callback(ctx.ptr, js_name, js_func_cb)
            JS.js_string_release(js_name)
            funcs[int(jsf)] = f
            self.ptr = jsf

    fn __init__(inout self, ctx: JSContext, f: fn(JSContext, JSObject, List[JSValue]) raises -> JSValue):
        var jsf = JS.js_object_make_function_with_callback(ctx.ptr, UnsafePointer[NoneType](), js_func_cb)
        funcs[int(jsf)] = f
        self.ptr = jsf

    fn __copyinit__(inout self, other: JSObject):
        self.ptr = other.ptr

    fn __moveinit__(inout self, owned other: JSObject):
        self.ptr = other.ptr

    fn __del__(owned self):
        pass

    fn is_function(self, ctx: JSContext) -> Bool:
        return JS.js_object_is_function(ctx.ptr, self.ptr)

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
        var ex = UnsafePointer[NoneType]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 0, args, UnsafePointer.address_of(ex))
        if not value:
            raise Error("failed to call object as function: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSValue(value)

    fn call(self, ctx: JSContext, arg1: JSValue) raises -> JSValue:
        var ex = UnsafePointer[NoneType]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 1, UnsafePointer.address_of(arg1.ptr), UnsafePointer.address_of(ex))
        if not value:
            raise Error("failed to call object as function: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSValue(value)

    fn call(self, ctx: JSContext, arg1: JSValue, arg2: JSValue) raises -> JSValue:
        var args = InlineArray[size=2](arg1.ptr, arg2.ptr)
        var ex = UnsafePointer[NoneType]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 2, args.unsafe_ptr(), UnsafePointer.address_of(ex))
        if not value:
            raise Error("failed to call object as function: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSValue(value)

    fn call(self, ctx: JSContext, arg1: JSValue, arg2: JSValue, arg3: JSValue) raises -> JSValue:
        var args = InlineArray[size=3](arg1.ptr, arg2.ptr, arg3.ptr)
        var ex = UnsafePointer[NoneType]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 3, args.unsafe_ptr(), UnsafePointer.address_of(ex))
        if not value:
            raise Error("failed to call object as function: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSValue(value)

    fn call(self, ctx: JSContext, arg1: JSValue, arg2: JSValue, arg3: JSValue, arg4: JSValue) raises -> JSValue:
        var args = InlineArray[size=4](arg1.ptr, arg2.ptr, arg3.ptr, arg4.ptr)
        var ex = UnsafePointer[NoneType]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, c_null, 4, args.unsafe_ptr(), UnsafePointer.address_of(ex))
        if not value:
            raise Error("failed to call object as function: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSValue(value)

    fn method_call(self, ctx: JSContext, this: JSObject, arg1: JSValue) raises -> JSValue:
        var ex = UnsafePointer[NoneType]()
        var value = JS.js_object_call_as_function(ctx.ptr, self.ptr, this.ptr, 1, UnsafePointer.address_of(arg1.ptr), UnsafePointer.address_of(ex))
        if not value:
            raise Error("failed to call object as function: " + JSObject(ex).get_property(ctx, "message").as_string(ctx))
        return JSValue(value)

