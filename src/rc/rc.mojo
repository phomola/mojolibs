from os import Atomic

struct PointerCount[T: CollectionElement]:
    var val: T
    var count: Atomic[DType.int64]

    fn __init__(inout self, val: T):
        self.val = val
        self.count = 1

    # fn __del__(owned self):
    #     print("RC storage destruction")

struct RC[T: CollectionElement]:
    var pc: UnsafePointer[PointerCount[T]]

    fn __init__(inout self, val: T):
        self.pc = UnsafePointer[PointerCount[T]].alloc(1)
        self.pc[].val = val
        self.pc[].count = 1
    
    fn __copyinit__(inout self, ex: RC):
        self.pc = UnsafePointer[PointerCount[T]](address=int(ex.pc))
        self.pc[].count += 1
        
    fn __moveinit__(inout self, owned ex: RC):
        self.pc = UnsafePointer[PointerCount[T]](address=int(ex.pc))
        
    fn __del__(owned self):
        var old_count = self.pc[].count.fetch_sub(1)
        if old_count == 1:
            destroy_pointee(self.pc)
            self.pc.free()
    
    fn ref_count(self) -> Int64:
        return self.pc[].count.load()

    fn __getitem__(self) -> T:
        return self.pc[].val

    fn __setitem__(inout self, val: T):
        self.pc[].val = val