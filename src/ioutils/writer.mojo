from textkit import bytes_from_string

trait Writer(Movable):
    fn write_bytes(inout self, list: List[UInt8]) raises:
        ...

fn write_string[T: Writer](inout writer: T, string: String) raises:
    writer.write_bytes(bytes_from_string(string))
