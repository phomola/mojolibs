from memory import UnsafePointer
from .jslib import JS, c_null
from textkit import CStr

fn js_evaluate(ctx: JSContext, script: String) raises -> JSValue:
    with CStr(script) as c_script:
        var js_script = JS.js_string_create_with_utf8_string(c_script)
        var ex = UnsafePointer[NoneType]()
        var js_value = JS.js_evaluate_script(ctx.ptr, js_script, c_null, c_null, 1, UnsafePointer.address_of(ex))
        JS.js_string_release(js_script)
        if not js_value:
            raise Error("JS evaluation failed: " + get_error_string(ctx, JSValue(ex)))
        return JSValue(js_value)

fn get_error_string(ctx: JSContext, ex: JSValue) -> String:
    try:
        if ex.is_object(ctx):
            obj = ex.to_object(ctx)
            if obj.has_property(ctx, "message"):
                return obj.get_property(ctx, "message").as_string(ctx)
            return ex.as_json_string(ctx)
        return ex.as_string(ctx)
    except e:
        return "failed to get error string: " + str(e)
