trait Reader:
    fn read(self, inout list: List[UInt8]) raises -> Int:
        ...
