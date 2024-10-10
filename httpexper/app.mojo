from sys import stderr, exit
from textkit import parse_json_object
from http import http, HttpCtx, HttpRequest

fn handler1(ctx: HttpCtx):
    print("mojo: handler 1")
    var req = HttpRequest(ctx)
    req.check()
    req.write_response("handler 1")

fn handler2(ctx: HttpCtx):
    print("mojo: handler 2")
    var req = HttpRequest(ctx)
    req.check()
    req.write_response("handler 2")

fn handler3(ctx: HttpCtx):
    print("mojo: handler 3")
    var req = HttpRequest(ctx)
    http.check(ctx)
    var body = req.get_body()
    try:
        var obj = parse_json_object(body)
        var name = obj.must_get_string("name")
        req.write_response("Hello, " + name + "!")
    except e:
        req.write_header(400)
        req.write_response("error: " + str(e))
    req.write_response("\n")

fn main():
    http.register_handler("GET /handler1", handler1)
    http.register_handler("GET /handler2", handler2)
    http.register_handler("POST /handler3", handler3)
    try:
        http.run()
    except e:
        print("error:", e, file=stderr)
        exit(1)
