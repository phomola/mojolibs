from collections import List
from sys import ffi, external_call
from memory import memcpy

var goapi = GoApi()

alias HttpCtx = UnsafePointer[Int]

fn handler1(ctx: HttpCtx):
    print("mojo: handler 1")
    goapi.check(ctx)

fn handler2(ctx: HttpCtx):
    print("mojo: handler 2")
    goapi.check(ctx)

fn handler3(ctx: HttpCtx):
    print("mojo: handler 3")
    goapi.check(ctx)
    var body = goapi.getBody(ctx)
    print("#", len(body))

@value
@register_passable("trivial")
struct Data:
    var ptr: UnsafePointer[UInt8]
    var len: Int64

struct GoApi:
    var golib_listenServe: fn(Int) -> None
    var golib_registerHandler: fn(fn(HttpCtx) -> None, StringRef) -> None
    var golib_check: fn(HttpCtx) -> None
    var golib_getBody: fn(HttpCtx) -> Data
    var golib_free: fn(UnsafePointer[UInt8]) -> None

    fn __init__(inout self):
        var h = ffi.DLHandle("./libhttpsrv.dylib")
        print("lib handle:", h.handle)
        self.golib_listenServe = h.get_function[fn(Int) -> None]("golib_listen_serve")
        self.golib_registerHandler = h.get_function[fn(fn(HttpCtx) -> None, StringRef) -> None]("golib_register_handler")
        self.golib_check = h.get_function[fn(HttpCtx) -> None]("golib_check")
        self.golib_getBody = h.get_function[fn(HttpCtx) -> Data]("golib_get_body")
        self.golib_free = h.get_function[fn(UnsafePointer[UInt8]) -> None]("golib_free")
    
    fn listenServe(self, port: Int):
        self.golib_listenServe(port)

    fn registerHandler(self, path: String, handler: fn(HttpCtx) -> None):
        self.golib_registerHandler(handler, path._strref_dangerous())
        path._strref_keepalive()
    
    fn check(self, ctx: HttpCtx):
        self.golib_check(ctx)
    
    fn getBody(self, ctx: HttpCtx) -> List[UInt8]:
        var data = self.golib_getBody(ctx)
        var size: Int = int(data.len)
        print("size:", size)
        var bytes = UnsafePointer[UInt8].alloc(size)
        print("alloced")
        memcpy(bytes, data.ptr, size)
        print("copied")
        #self.golib_free(data.ptr)
        var list = List[UInt8](unsafe_pointer=bytes, size=size, capacity=size)
        print("list len:", len(list))
        print(list[0], list[1])
        print(string_from_bytes(list))
        return list

fn main():
    goapi.registerHandler("GET /handler1", handler1)
    goapi.registerHandler("GET /handler2", handler2)
    goapi.registerHandler("POST /handler3", handler3)
    goapi.listenServe(8080)
    print("done")

fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))

fn bytes_from_string(s: String) -> List[UInt8]:
    return s.as_bytes()
