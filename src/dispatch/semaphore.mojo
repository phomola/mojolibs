from memory import UnsafePointer
from sys import external_call

alias DISPATCH_TIME_FOREVER: UInt64 = 18446744073709551615

struct Semaphore:
    var ptr: UnsafePointer[NoneType]

    fn __init__(inout self, value: Int):
        self.ptr = external_call["dispatch_semaphore_create", UnsafePointer[NoneType]](value)

    fn __copyinit__(inout self, other: Semaphore):
        external_call["dispatch_retain", NoneType](other.ptr)
        self.ptr = other.ptr

    fn __moveinit__(inout self, owned other: Semaphore):
        self.ptr = other.ptr

    fn __del__(owned self):
        external_call["dispatch_release", NoneType](self.ptr)

    fn wait(self):
        _ = external_call["dispatch_semaphore_wait", Int](self.ptr, DISPATCH_TIME_FOREVER)

    fn signal(self):
        _ = external_call["dispatch_semaphore_signal", Int](self.ptr)
