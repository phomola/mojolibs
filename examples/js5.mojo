from javascript import JSGlobalContext, JSContext, JSValue, JSObject, js_evaluate

fn js_cb1(ctx: JSContext, this: JSObject, args: List[JSValue]) raises -> JSValue:
    print("raising an exception")
    raise Error("exception from native JS callback")

fn main():
    var ctx = JSGlobalContext()
    var global_object = ctx.get_global_object()
    try:
        var f = JSObject(ctx, js_cb1)
        global_object.set_property(ctx, "my_func", f)
        
        _ = js_evaluate(ctx, """
            function test() {
                try {
                    my_func()
                    return 1
                } catch (e) {
                    return "error: " + e.message
                }
            }
        """)
        var value = global_object.get_property(ctx, "test").to_object(ctx).call(ctx)
        print(value.as_string(ctx))
    except e:
        print("error:", e)        
