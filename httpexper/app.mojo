from collections import List
from sys import ffi, external_call
from memory import memcpy

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
    var body = goapi.getBody(ctx)
    goapi.writeResponse(ctx, "Hello from Mojo!\n")
    goapi.writeResponse(ctx, string_from_bytes(body))
    goapi.writeResponse(ctx, "\n")

struct GoApi:
    var golib_listenServe: fn(Int) -> None
    var golib_registerHandler: fn(fn(HttpCtx) -> None, StringRef) -> None
    var golib_check: fn(HttpCtx) -> None
    var golib_getBody: fn(HttpCtx) -> Data
    var golib_free: fn(UnsafePointer[UInt8]) -> None
    var golib_writeResponse: fn(HttpCtx, UnsafePointer[UInt8], Int64) -> None

    fn __init__(inout self):
        var h = ffi.DLHandle("./libhttpsrv.dylib")
        print("lib handle:", h.handle)
        self.golib_listenServe = h.get_function[fn(Int) -> None]("golib_listen_serve")
        self.golib_registerHandler = h.get_function[fn(fn(HttpCtx) -> None, StringRef) -> None]("golib_register_handler")
        self.golib_check = h.get_function[fn(HttpCtx) -> None]("golib_check")
        self.golib_getBody = h.get_function[fn(HttpCtx) -> Data]("golib_get_body")
        self.golib_free = h.get_function[fn(UnsafePointer[UInt8]) -> None]("golib_free")
        self.golib_writeResponse = h.get_function[fn(HttpCtx, UnsafePointer[UInt8], Int64) -> None]("golib_write_response")
    
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
        var bytes = UnsafePointer[UInt8].alloc(size)
        memcpy(bytes, data.ptr, size)
        self.golib_free(data.ptr)
        var list = List[UInt8](unsafe_pointer=bytes, size=size, capacity=size)
        return list

    fn writeResponse(self, ctx: HttpCtx, data: String):
        self.writeResponse(ctx, bytes_from_string(data))

    fn writeResponse(self, ctx: HttpCtx, data: List[UInt8]):
        self.golib_writeResponse(ctx, get_list_data(data), len(data))

fn main():
    goapi.registerHandler("GET /handler1", handler1)
    goapi.registerHandler("GET /handler2", handler2)
    goapi.registerHandler("POST /handler3", handler3)
    goapi.listenServe(8080)

fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))

fn bytes_from_string(s: String) -> List[UInt8]:
    return s.as_bytes()

fn get_list_data(list: List[UInt8]) -> UnsafePointer[UInt8]:
    return list.data