trait Reader:
    fn read_bytes(self, n: Int) raises -> List[UInt8]:
        ...

fn read_all[T: Reader](reader: T) raises -> List[UInt8]:
    var list = List[UInt8]()
    while True:
        var list2 = reader.read_bytes(1_024)
        if len(list2) == 0:
            return list
        list.extend(list2)
