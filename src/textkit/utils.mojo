fn string_from_bytes(b: List[UInt8]) -> String:
    return str(StringRef(b.data, len(b)))
