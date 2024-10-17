from javascript import JSGlobalContext, JSContext, JSValue, JSObject, js_evaluate

fn js_async(ctx: JSContext, this: JSObject, args: List[JSValue]) -> JSValue:
    try:
        promise, resolve, reject = JSObject.promise(ctx)
        _ = resolve.call(ctx, JSValue(ctx, "abcd"))
        return promise
    except e:
        print(e)
        return JSValue.undefined(ctx)

fn js_resolved(ctx: JSContext, this: JSObject, args: List[JSValue]) -> JSValue:
    try:
        print("promise resolved:", args[0].as_string(ctx))
    except e:
        print(e)
    return JSValue.undefined(ctx)

fn main():
    var ctx = JSGlobalContext()
    var global_object = ctx.get_global_object()
    try:
        var f = JSObject(ctx, js_async)
        global_object.set_property(ctx, "my_func", f)
        
        _ = js_evaluate(ctx, """
            async function main() { return await my_func() }
        """)

        var value = global_object.get_property(ctx, "main").to_object(ctx).call(ctx)
        var promise = value.to_object(ctx)
        value = promise.get_property(ctx, "then")
        var then = value.to_object(ctx)
        var g = JSObject(ctx, js_resolved)
        _ = then.method_call(ctx, promise, g)
    except e:
        print("error:", e)        
