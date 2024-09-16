from collections import List
from sys import ffi, external_call
from memory import memcpy
from os import getenv
from sys import argv, stderr, exit
from textkit import parse_json_object

var goapi = GoApi()

alias HttpCtx = UnsafePointer[Int]

@value
@register_passable("trivial")
struct Data:
    var ptr: UnsafePointer[UInt8]
    var len: Int64

fn handler1(ctx: HttpCtx):
    print("mojo: handler 1")
    goapi.check(ctx)

fn handler2(ctx: HttpCtx):
    print("mojo: handler 2")
    goapi.check(ctx)

fn handler3(ctx: HttpCtx):
    print("mojo: handler 3")
    goapi.check(ctx)
    var body = goapi.get_body(ctx)
    try:
        var obj = parse_json_object(body)
        var name = obj.must_get_string("name")
        goapi.write_response(ctx, "Hello, " + name + "!")
    except e:
        goapi.write_header(ctx, 400)
        goapi.write_response(ctx, "error: " + str(e))
    goapi.write_response(ctx, "\n")

struct GoApi:
    var golib_listen_and_serve: fn(Int64) -> None
    var golib_register_handler: fn(fn(HttpCtx) -> None, StringRef) -> None
    var golib_check: fn(HttpCtx) -> None
    var golib_get_body: fn(HttpCtx) -> Data
    var golib_free: fn(UnsafePointer[UInt8]) -> None
    var golib_write_response: fn(HttpCtx, UnsafePointer[UInt8], Int64) -> None
    var golib_write_header: fn(HttpCtx, Int64) -> None

    fn __init__(inout self):
        var h = ffi.DLHandle("./libhttpsrv.dylib")
        print("lib handle:", h.handle)
        self.golib_listen_and_serve = h.get_function[fn(Int64) -> None]("golib_listen_serve")
        self.golib_register_handler = h.get_function[fn(fn(HttpCtx) -> None, StringRef) -> None]("golib_register_handler")
        self.golib_check = h.get_function[fn(HttpCtx) -> None]("golib_check")
        self.golib_get_body = h.get_function[fn(HttpCtx) -> Data]("golib_get_body")
        self.golib_free = h.get_function[fn(UnsafePointer[UInt8]) -> None]("golib_free")
        self.golib_write_response = h.get_function[fn(HttpCtx, UnsafePointer[UInt8], Int64) -> None]("golib_write_response")
        self.golib_write_header = h.get_function[fn(HttpCtx, Int64) -> None]("golib_write_header")
    
    fn listen_and_serve(self, port: Int):
        self.golib_listen_and_serve(port)

    fn register_handler(self, path: String, handler: fn(HttpCtx) -> None):
        self.golib_register_handler(handler, path._strref_dangerous())
        path._strref_keepalive()
    
    fn check(self, ctx: HttpCtx):
        self.golib_check(ctx)
    
    fn get_body(self, ctx: HttpCtx) -> List[UInt8]:
        var data = self.golib_get_body(ctx)
        var size = int(data.len)
        if size == 0:
            return List[UInt8]()
        var bytes = UnsafePointer[UInt8].alloc(size)
        memcpy(bytes, data.ptr, size)
        self.golib_free(data.ptr)
        return List(unsafe_pointer=bytes, size=size, capacity=size)

    fn write_response(self, ctx: HttpCtx, data: String):
        self.write_response(ctx, bytes_from_string(data))

    fn write_response(self, ctx: HttpCtx, data: List[UInt8]):
        self.golib_write_response(ctx, get_list_data(data), len(data))

    fn write_header(self, ctx: HttpCtx, status: Int):
        self.golib_write_header(ctx, status)

fn main():
    goapi.register_handler("GET /handler1", handler1)
    goapi.register_handler("GET /handler2", handler2)
    goapi.register_handler("POST /handler3", handler3)
    try:
        var port = atol(getenv("PORT"))
        goapi.listen_and_serve(port)
    except e:
        print("error:", e, file=stderr)
        exit(1)

fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))

fn bytes_from_string(s: String) -> List[UInt8]:
    return s.as_bytes()

fn get_list_data(list: List[UInt8]) -> UnsafePointer[UInt8]:
    return list.data
