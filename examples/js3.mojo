from javascript import JSGlobalContext, JSContext, JSValue, JSObject, js_evaluate

fn js_cb1(ctx: JSContext, this: JSObject, args: List[JSValue]) raises -> JSValue:
    return JSValue(ctx, args[0].to_number(ctx) + args[1].to_number(ctx))

fn main():
    var ctx = JSGlobalContext()
    var global_object = ctx.get_global_object()
    try:
        var f = JSObject(ctx, js_cb1)
        global_object.set_property(ctx, "my_func", f)
        
        var value = f.call(ctx, JSValue(ctx, 2), JSValue(ctx, 3))
        print(value.as_string(ctx))

        value = js_evaluate(ctx, """
            my_func(3, 4)
        """)
        print(value.as_string(ctx))
    except e:
        print(e)        
