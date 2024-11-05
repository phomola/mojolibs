from libevent import Libevent
from sys import argv, stderr, exit
from utils import StringRef
from javascript import JSGlobalContext, JSContext, JSValue, JSObject, js_evaluate
from memory import UnsafePointer
from dispatch import Semaphore

var libevent = Libevent()
var ctx = JSGlobalContext()
var sem = Semaphore(10)

fn request_handler(req: UnsafePointer[NoneType], arg: UnsafePointer[NoneType]):
    handler = JSObject(arg)
    uri = libevent.evhttp_request_get_uri(req)
    request = JSObject(ctx)
    request.set_property(ctx, "uri", JSValue(ctx, uri))
    var response_data: String
    var response_status: Int
    sem.wait()
    try:
        response = handler.call(ctx, request)
        response_data = response.as_json_string(ctx)
        response_status = 200
    except e:
        response_data = "handler exception: " + str(e)
        response_status = 500
    sem.signal()
    outbuf = libevent.evhttp_request_get_output_buffer(req)
    _ = libevent.evbuffer_add(outbuf, response_data)
    libevent.evhttp_send_reply(req, response_status, "", outbuf)

fn run_server() raises:
    file, port = get_file_and_port(argv())
    with open(file, "r") as file:
        code = file.read()
        _ = js_evaluate(ctx, code)
        global_object = ctx.get_global_object()
        if not global_object.has_property(ctx, "http_handler"):
            raise Error("function 'http_handler' not found")
        handler = global_object.get_property(ctx, "http_handler")
        if not libevent.event_init():
            print("failed to init event library", file=stderr)
            exit(1)
        server = libevent.evhttp_start("0.0.0.0", atol(port))
        if not server:
            print("failed to start server", file=stderr)
            exit(1)
        libevent.evhttp_set_gencb(server, request_handler, handler.get_pointer())
        handler.keep_alive()
        print("listening on port", port)
        if not libevent.event_dispatch():
            print("failed to run event loop", file=stderr)
            exit(1)

fn get_file_and_port(argv: VariadicList[StringRef]) raises -> Tuple[StringRef, StringRef]:
    if len(argv) != 3:
        raise Error("usage: jshttp <file> <port>")
    return argv[1], argv[2]

fn main():
    try:
        run_server()
    except e:
        print(e, file=stderr)
        exit(1)
