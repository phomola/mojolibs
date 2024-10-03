fn copy_all[R: Reader, W: Writer](inout writer: W, inout reader: R) raises:
    while True:
        var list = reader.read_bytes(1_024)
        if len(list) == 0:
            return
        writer.write_bytes(list)
