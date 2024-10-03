from javascript import JSGlobalContext, JSContext, JSValue, js_evaluate

fn main():
    var ctx = JSGlobalContext()
    var global_object = ctx.get_global_object()
    global_object.set_property(ctx, "x", JSValue(ctx, 1234))
    global_object.set_property(ctx, "y", JSValue(ctx, "abcd"))
    try:
        var value = js_evaluate(ctx, """
            ({"a": x, "b": y})
        """)
        value.protect(ctx)
        if value.is_string(ctx):
            var string = value.to_string(ctx)
            print("got string:", string)
        elif value.is_number(ctx):
            var number = value.to_number(ctx)
            print("got number:", number)
        elif value.is_object(ctx):
            var object = value.to_object(ctx)
            print("got object")
            print("a =", object.get_property(ctx, "a").as_string(ctx))
            print("b =", object.get_property(ctx, "b").as_string(ctx))
            print("c =", object.get_property(ctx, "c").as_string(ctx))
        else:
            print("got value of unknown type")
        value.unprotect(ctx)
    except e:
        print(e)        
