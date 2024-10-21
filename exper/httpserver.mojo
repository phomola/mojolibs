from libevent import Libevent
from sys import stderr, exit
from memory import UnsafePointer

var libevent = Libevent()

fn handler(req: UnsafePointer[NoneType], arg: UnsafePointer[NoneType]):
    uri = libevent.evhttp_request_get_uri(req)
    print("request:", uri)
    outbuf = libevent.evhttp_request_get_output_buffer(req)
    output = "Hello, world!"
    if not libevent.evbuffer_add(outbuf, output):
        print("failed to write to buffer")
    libevent.evhttp_send_reply(req, 200, "", outbuf)

fn main():
    if not libevent.event_init():
        print("failed to init event", file=stderr)
        exit(1)
    if not libevent.evthread_use_pthreads():
        print("failed to use event pthreads", file=stderr)
        exit(1)
    port = 8080
    server = libevent.evhttp_start("0.0.0.0", port)
    if not server:
        print("failed to start server", file=stderr)
        exit(1)
    libevent.evhttp_set_gencb(server, handler, UnsafePointer[NoneType]())
    print("listening on port", port)
    if not libevent.event_dispatch():
        print("failed to dispatch event", file=stderr)
        exit(1)
