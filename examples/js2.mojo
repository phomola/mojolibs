from javascript import JSGlobalContext, JSContext, JSValue, JSObject, js_evaluate

fn main():
    var ctx = JSGlobalContext()
    var global_object = ctx.get_global_object()
    try:
        var value = js_evaluate(ctx, """
            function jsfunc0() { return "out: jsfunc0" }
            function jsfunc1(x) { return `out: jsfunc1: ${x}` }
            function jsfunc2(x, y) { return "out: jsfunc2: " + x + " " + y }
        """)

        value = global_object.get_property(ctx, "jsfunc0")
        var f = JSObject(value)
        value = f.call(ctx)
        print(value.as_string(ctx))

        value = global_object.get_property(ctx, "jsfunc1")
        f = JSObject(value)
        value = f.call(ctx, JSValue(ctx, "abcd"))
        print(value.as_string(ctx))

        value = global_object.get_property(ctx, "jsfunc2")
        f = JSObject(value)
        value = f.call(ctx, JSValue(ctx, "abcd"), JSValue(ctx, 1234))
        print(value.as_string(ctx))
    except e:
        print(e)        
