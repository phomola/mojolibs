from testing import assert_equal, assert_true
from textkit import parse_json_object, JSONObject, JSONArray, JSONNull, null

fn test_json_parser() raises:
    var obj = parse_json_object("""
    {
        "key1": true,
        "key2": false,
        "key3": "abcd",
        "key4": 1234,
        "key5": 12.34,
        "key6": {},
        "key7": [],
        "key8": [1, 2, 3],
        "key9": null,
        "key10": -1234,
        "key11": -12.34
    }
    """)
    assert_equal(11, len(obj.dict))
    assert_true(obj.dict.get("key1"))
    assert_true(obj.dict.get("key1").value().isa[Bool]())
    assert_equal(True, obj.dict.get("key1").value()[Bool])
    assert_true(obj.dict.get("key2"))
    assert_true(obj.dict.get("key2").value().isa[Bool]())
    assert_equal(False, obj.dict.get("key2").value()[Bool])
    assert_true(obj.dict.get("key3"))
    assert_true(obj.dict.get("key3").value().isa[String]())
    assert_equal("abcd", obj.dict.get("key3").value()[String])
    assert_true(obj.dict.get("key4"))
    assert_true(obj.dict.get("key4").value().isa[Int]())
    assert_equal(1234, obj.dict.get("key4").value()[Int])
    assert_true(obj.dict.get("key5"))
    assert_true(obj.dict.get("key5").value().isa[Float64]())
    assert_equal(12.34, obj.dict.get("key5").value()[Float64])
    assert_true(obj.dict.get("key6"))
    assert_true(obj.dict.get("key6").value().isa[JSONObject]())
    assert_equal(0, len(obj.dict.get("key6").value()[JSONObject].dict))
    assert_true(obj.dict.get("key7"))
    assert_true(obj.dict.get("key7").value().isa[JSONArray]())
    assert_equal(0, len(obj.dict.get("key7").value()[JSONArray].array))
    assert_true(obj.dict.get("key8"))
    assert_true(obj.dict.get("key8").value().isa[JSONArray]())
    assert_equal(3, len(obj.dict.get("key8").value()[JSONArray].array))
    assert_true(obj.dict.get("key9"))
    assert_true(obj.dict.get("key9").value().isa[JSONNull]())
    assert_equal(null, obj.dict.get("key9").value()[JSONNull])
    assert_true(obj.dict.get("key10"))
    assert_true(obj.dict.get("key10").value().isa[Int]())
    assert_equal(-1234, obj.dict.get("key10").value()[Int])
    assert_true(obj.dict.get("key11"))
    assert_true(obj.dict.get("key11").value().isa[Float64]())
    assert_equal(-12.34, obj.dict.get("key11").value()[Float64])
