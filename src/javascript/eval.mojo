from memory import UnsafePointer
from .jslib import c_null
from .string import CStr

fn js_evaluate(ctx: JSContext, script: String) raises -> JSValue:
    with CStr(script) as c_script:
        var js_script = JS.js_string_create_with_utf8_string(c_script)
        var js_value = JS.js_evaluate_script(ctx.ptr, js_script, c_null, c_null, 1, c_null)
        JS.js_string_release(js_script)
        if not js_value:
            raise Error("JS evaluation failed")
        return JSValue(js_value)
