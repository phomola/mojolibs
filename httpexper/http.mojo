from sys import ffi
from memory import memcpy, UnsafePointer
from os import getenv
from utils import StringRef
from ioutils import Writer

alias HttpCtx = UnsafePointer[NoneType]

var http = GoApi()

@value
struct HttpRequest:
    var ctx: HttpCtx

    fn get_body(self) -> List[UInt8]:
        return http.get_body(self.ctx)

    fn write_header(self, status: Int):
        http.write_header(self.ctx, status)

    fn write_response(self, data: String):
        http.write_response(self.ctx, data)

    fn write_response(self, data: List[UInt8]):
        http.write_response(self.ctx, data)

    fn check(self):
        http.check(self.ctx)

    fn response_writer(self) -> ResponseWriter:
        return ResponseWriter(self)

@value
struct ResponseWriter(Writer):
    var req: HttpRequest

    fn write_bytes(inout self, list: List[UInt8]) raises:
        self.req.write_response(list)

@value
@register_passable("trivial")
struct Data:
    var ptr: UnsafePointer[UInt8]
    var len: Int64

struct GoApi:
    var golib_listen_and_serve: fn(Int64) -> None
    var golib_register_handler: fn(StringRef, fn(HttpCtx) -> None) -> None
    var golib_check: fn(HttpCtx) -> None
    var golib_get_body: fn(HttpCtx) -> Data
    var golib_free: fn(UnsafePointer[UInt8]) -> None
    var golib_write_response: fn(HttpCtx, UnsafePointer[UInt8], Int64) -> None
    var golib_write_header: fn(HttpCtx, Int64) -> None

    fn __init__(inout self):
        var h = ffi.DLHandle(getenv("HTTP_LIB"))
        self.golib_listen_and_serve = h.get_function[fn(Int64) -> None]("golib_listen_serve")
        self.golib_register_handler = h.get_function[fn(StringRef, fn(HttpCtx) -> None) -> None]("golib_register_handler")
        self.golib_check = h.get_function[fn(HttpCtx) -> None]("golib_check")
        self.golib_get_body = h.get_function[fn(HttpCtx) -> Data]("golib_get_body")
        self.golib_free = h.get_function[fn(UnsafePointer[UInt8]) -> None]("golib_free")
        self.golib_write_response = h.get_function[fn(HttpCtx, UnsafePointer[UInt8], Int64) -> None]("golib_write_response")
        self.golib_write_header = h.get_function[fn(HttpCtx, Int64) -> None]("golib_write_header")
    
    fn listen_and_serve(self, port: Int):
        self.golib_listen_and_serve(port)

    fn run(self) raises:
        var port = atol(getenv("PORT"))
        self.listen_and_serve(port)

    fn register_handler(self, path: String, handler: fn(HttpCtx) -> None):
        self.golib_register_handler(path._strref_dangerous(), handler)
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

fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))

fn bytes_from_string(s: String) -> List[UInt8]:
    return s.as_bytes()

fn get_list_data(list: List[UInt8]) -> UnsafePointer[UInt8]:
    return list.data
