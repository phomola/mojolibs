from sys import DLHandle, os_is_macos
from memory import UnsafePointer

alias macosDylib = "/System/Library/Frameworks/JavaScriptCore.framework/JavaScriptCore"
alias linuxSo = "libjavascriptcore.so"

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
    var js_value_is_null: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_value_is_undefined: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_value_is_string: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_value_is_number: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_value_is_object: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_value_to_string_copy: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_value_to_number: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Float64
    var js_value_to_object: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_value_make_number: fn(UnsafePointer[NoneType], Float64) -> UnsafePointer[NoneType]
    var js_value_make_string: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_value_protect: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None
    var js_value_unprotect: fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None
    var js_object_has_property: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool
    var js_object_get_property: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]
    var js_object_set_property: fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> None
    var js_context_get_global_object: fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]

    fn __init__(inout self):
        if os_is_macos():
            self.lib = DLHandle(macosDylib)
        else:
            self.lib = DLHandle(linuxSo)
        self.js_global_context_create = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSGlobalContextCreate")
        self.js_global_context_retain = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSGlobalContextRetain")
        self.js_global_context_release = self.lib.get_function[fn(UnsafePointer[NoneType]) -> None]("JSGlobalContextRelease")
        self.js_string_create_with_utf8_string = self.lib.get_function[fn(UnsafePointer[UInt8]) -> UnsafePointer[NoneType]]("JSStringCreateWithUTF8CString")
        self.js_string_retain = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSStringRetain")
        self.js_string_release = self.lib.get_function[fn(UnsafePointer[NoneType]) -> None]("JSStringRelease")
        self.js_string_get_maximum_utf8_cstring_size = self.lib.get_function[fn(UnsafePointer[NoneType]) -> Int]("JSStringGetMaximumUTF8CStringSize")
        self.js_string_get_utf8_cstring = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[UInt8], Int) -> Int]("JSStringGetUTF8CString")
        self.js_evaluate_script = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSEvaluateScript")
        self.js_value_is_null = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSValueIsNull")
        self.js_value_is_undefined = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSValueIsUndefined")
        self.js_value_is_string = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSValueIsString")
        self.js_value_is_number = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSValueIsNumber")
        self.js_value_is_object = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSValueIsObject")
        self.js_value_to_string_copy = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSValueToStringCopy")
        self.js_value_to_number = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Float64]("JSValueToNumber")
        self.js_value_to_object = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSValueToObject")
        self.js_value_make_number = self.lib.get_function[fn(UnsafePointer[NoneType], Float64) -> UnsafePointer[NoneType]]("JSValueMakeNumber")
        self.js_value_make_string = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSValueMakeString")
        self.js_value_protect = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None]("JSValueProtect")
        self.js_value_unprotect = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType]) -> None]("JSValueUnprotect")
        self.js_object_has_property = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> Bool]("JSObjectHasProperty")
        self.js_object_get_property = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSObjectGetProperty")
        self.js_object_set_property = self.lib.get_function[fn(UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], UnsafePointer[NoneType], Int, UnsafePointer[NoneType]) -> None]("JSObjectSetProperty")
        self.js_context_get_global_object = self.lib.get_function[fn(UnsafePointer[NoneType]) -> UnsafePointer[NoneType]]("JSContextGetGlobalObject")
