package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"runtime/cgo"
	"strconv"
	"unsafe"
)

/*
#include <stdlib.h>

typedef struct {
	void* ptr;
	uint64_t len;
} data;

inline void c_invoke_callback(void* p, void* arg) {
	void (*cb)(void*) = p;
	cb(arg);
}
*/
import "C"

var (
	mux = new(http.ServeMux)
)

type reqData struct {
	req *http.Request
	rw  http.ResponseWriter
}

//export golib_free
func golib_free(p unsafe.Pointer) {
	C.free(p)
}

//export golib_check
func golib_check(hp unsafe.Pointer) {
	d := (*cgo.Handle)(hp).Value().(reqData)
	fmt.Println("check:", d.req.URL)
}

//export golib_get_body
func golib_get_body(hp unsafe.Pointer) C.data {
	d := (*cgo.Handle)(hp).Value().(reqData)
	b, err := io.ReadAll(d.req.Body)
	if err != nil {
		return C.data{}
	}
	cb := C.CBytes(b)
	return C.data{
		ptr: cb,
		len: C.uint64_t(len(b)),
	}
}

//export golib_write_response
func golib_write_response(hp unsafe.Pointer, p unsafe.Pointer, size C.int64_t) {
	d := (*cgo.Handle)(hp).Value().(reqData)
	d.rw.Write(C.GoBytes(p, C.int(size)))
}

//export golib_register_handler
func golib_register_handler(handler unsafe.Pointer, cpath *C.char) {
	path := C.GoString(cpath)
	fmt.Println("registering handler for", path)
	mux.HandleFunc(path, func(w http.ResponseWriter, req *http.Request) {
		h := cgo.NewHandle(reqData{
			req: req,
			rw:  w,
		})
		defer h.Delete()
		C.c_invoke_callback(handler, unsafe.Pointer(&h))
	})
}

//export golib_listen_serve
func golib_listen_serve(port C.int) {
	fmt.Println("listening on port", port)
	if err := http.ListenAndServe(":"+strconv.Itoa(int(port)), mux); err != http.ErrServerClosed {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func main() {}