struct PointerCount[T: CollectionElement]:
    var val: T
    var count: Int

    fn __init__(inout self, owned val: T):
        self.val = val^
        self.count = 1

    fn retain(inout self):
        self.count += 1

    fn release(inout self) -> Bool:
        self.count -= 1
        return self.count == 0

struct RC[T: CollectionElement]:
    var pc: UnsafePointer[PointerCount[T]]

    fn __init__(inout self, owned val: T):
        self.pc = UnsafePointer[PointerCount[T]].alloc(1)
        self.pc[].val = val^
        self.pc[].count = 1
    
    fn __copyinit__(inout self, ex: Self):
        self.pc = ex.pc
        self.pc[].retain()
        
    fn __moveinit__(inout self, owned ex: Self):
        self.pc = ex.pc
        
    fn __del__(owned self):
        if self.pc[].release():
            destroy_pointee(self.pc)
            self.pc.free()
    
    fn ref_count(self) -> Int64:
        return self.pc[].count

    fn __getitem__(self) -> ref[__lifetime_of(self)] T:
        return self.pc[].val

    fn set(inout self, val: T):
        self.pc[].val = val
