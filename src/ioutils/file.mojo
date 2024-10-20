from sys import stderr

struct File(Reader, IOWriter, Closer):
    var handle: FileHandle

    fn __init__(inout self, owned handle: FileHandle):
        self.handle = handle^

    fn __moveinit__(inout self, owned file: File):
        self.handle = file.handle^

    fn __del__(owned self):
        try:
            self.close()
        except e:
            print("failed to close file handle", file=stderr)

    fn close(inout self) raises:
        self.handle.close()

    fn read_bytes(inout self, n: Int) raises -> List[UInt8]:
        return self.handle.read_bytes(n)

    fn write_bytes(inout self, list: List[UInt8]) raises:
        self.handle.write(list)
