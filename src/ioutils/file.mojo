from sys import stderr

struct File(Reader):
    var handle: FileHandle

    fn __init__(inout self, owned handle: FileHandle):
        self.handle = handle^

    fn read(self, inout list: List[UInt8]) raises -> Int:
        list2 = self.handle.read_bytes(len(list))
        for i in range(len(list2)):
            list[i] = list2[i]
        return len(list2)

    fn __del__(owned self):
        try:
            self.close()
        except e:
            print("failed to close file handle", file=stderr)

    fn close(inout self) raises:
        self.handle.close()
