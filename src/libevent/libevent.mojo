from sys import DLHandle
from memory import UnsafePointer
from utils import StringRef
from textkit import CStr

@value
struct Libevent:
    var lib: DLHandle
    var lib_pthreads: DLHandle
    var _evhttp_request_get_uri: fn(UnsafePointer[NoneType]) -> UnsafePointer[UInt8]
    var _evhttp_request_get_output_buffer: fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var _evbuffer_add: fn(UnsafePointer[NoneType], UnsafePointer[UInt8], Int) -> Int
    var _evhttp_send_reply: fn(UnsafePointer[NoneType], Int, UnsafePointer[UInt8], UnsafePointer[NoneType]) -> NoneType
    var _event_init: fn() -> UnsafePointer[NoneType]
    var _evhttp_start: fn(UnsafePointer[UInt8], Int) -> UnsafePointer[NoneType]
    var _evhttp_set_gencb: fn(UnsafePointer[NoneType], fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None, UnsafePointer[NoneType]) -> NoneType
    var _event_dispatch: fn() -> Int
    var _evthread_use_pthreads: fn() -> Int

    fn __init__(inout self):
        self.lib = DLHandle("libevent.dylib")
        self.lib_pthreads = DLHandle("libevent_pthreads.dylib")
        self._evhttp_request_get_uri = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[UInt8]]("evhttp_request_get_uri")
        self._evhttp_request_get_output_buffer = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("evhttp_request_get_output_buffer")
        self._evbuffer_add = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[UInt8], Int) -> Int]("evbuffer_add")
        self._evhttp_send_reply = self.lib.get_function[fn(UnsafePointer[NoneType], Int, UnsafePointer[UInt8], UnsafePointer[NoneType]) -> NoneType]("evhttp_send_reply")
        self._event_init = self.lib.get_function[fn() -> UnsafePointer[NoneType]]("event_init")
        self._evhttp_start = self.lib.get_function[fn(UnsafePointer[UInt8], Int) -> UnsafePointer[NoneType]]("evhttp_start")
        self._evhttp_set_gencb = self.lib.get_function[fn(UnsafePointer[NoneType], fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None, UnsafePointer[NoneType]) -> NoneType]("evhttp_set_gencb")
        self._event_dispatch = self.lib.get_function[fn() -> Int]("event_dispatch")
        self._evthread_use_pthreads = self.lib_pthreads.get_function[fn() -> Int]("evthread_use_pthreads")

    fn evhttp_request_get_uri(self, req: UnsafePointer[NoneType]) -> String:
        return StringRef(self._evhttp_request_get_uri(req))

    fn evhttp_request_get_output_buffer(self, req: UnsafePointer[NoneType]) -> UnsafePointer[NoneType]:
        return self._evhttp_request_get_output_buffer(req)

    fn evbuffer_add(self, buf: UnsafePointer[NoneType], data: String) -> Bool:
        return self._evbuffer_add(buf, data.unsafe_ptr(), len(data)) == 0

    fn evbuffer_add(self, buf: UnsafePointer[NoneType], data: List[UInt8]) -> Bool:
        return self._evbuffer_add(buf, data.unsafe_ptr(), len(data)) == 0

    fn evhttp_send_reply(self, req: UnsafePointer[NoneType], status: Int, reason: StringRef, buf: UnsafePointer[NoneType]):
        if reason == "":
            self._evhttp_send_reply(req, status, UnsafePointer[UInt8](), buf)
        else:
            with CStr(reason) as c_reason:
                self._evhttp_send_reply(req, status, c_reason, buf)

    fn event_init(self) -> UnsafePointer[NoneType]:
        return self._event_init()

    fn evhttp_start(self, addr: String, port: Int) -> UnsafePointer[NoneType]:
        with CStr(addr) as c_addr:
            return self._evhttp_start(c_addr, port)

    fn evhttp_set_gencb(self, server: UnsafePointer[NoneType], f: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None, arg: UnsafePointer[NoneType]):
        self._evhttp_set_gencb(server, f, arg)      

    fn event_dispatch(self) -> Bool:
        return self._event_dispatch() == 0

    fn evthread_use_pthreads(self) -> Bool:
        return self._evthread_use_pthreads() == 0

