from sys import DLHandle
from memory import UnsafePointer

alias macosDylib = "/System/Library/Frameworks/JavaScriptCore.framework/JavaScriptCore"

var c_null = UnsafePointer[NoneType]()
var JS = _JS()

struct _JS:
    var lib: DLHandle
    var js_global_context_create: fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_global_context_retain: fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_global_context_release: fn(UnsafePointer[NoneType]) -> None
    var js_string_create_with_utf8_string: fn(UnsafePointer[UInt8]) -> UnsafePointer[NoneType]
    var js_string_retain: fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_string_release: fn(UnsafePointer[NoneType]) -> None
    var js_string_get_maximum_utf8_cstring_size: fn(UnsafePointer[NoneType]) -> Int
    var js_string_get_utf8_cstring: fn(UnsafePointer[NoneType], UnsafePointer[UInt8], Int) -> Int
    var js_evaluate_script: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_value_is_string: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_value_to_string_copy: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]

    fn __init__(inout self):
        self.lib = DLHandle(macosDylib)
        self.js_global_context_create = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSGlobalContextCreate")
        self.js_global_context_retain = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSGlobalContextRetain")
        self.js_global_context_release = self.lib.get_function[fn(UnsafePointer[NoneType]) -> None]("JSGlobalContextRelease")
        self.js_string_create_with_utf8_string = self.lib.get_function[fn(UnsafePointer[UInt8]) -> UnsafePointer[NoneType]]("JSStringCreateWithUTF8CString")
        self.js_string_retain = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSStringRetain")
        self.js_string_release = self.lib.get_function[fn(UnsafePointer[NoneType]) -> None]("JSStringRelease")
        self.js_string_get_maximum_utf8_cstring_size = self.lib.get_function[fn(UnsafePointer[NoneType]) -> Int]("JSStringGetMaximumUTF8CStringSize")
        self.js_string_get_utf8_cstring = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[UInt8], Int) -> Int]("JSStringGetUTF8CString")
        self.js_evaluate_script = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSEvaluateScript")
        self.js_value_is_string = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSValueIsString")
        self.js_value_to_string_copy = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSValueToStringCopy")
