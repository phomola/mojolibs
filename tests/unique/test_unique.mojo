from testing import assert_equal, assert_true, assert_false
from unique import InternedString, init_global_vars

fn test_interned_string() raises:
    init_global_vars()
    var s1 = InternedString("a")
    var s2 = InternedString("b")
    var s3 = InternedString("a")
    assert_equal("a", s1[])
    assert_false(s1 == s2)
    assert_true(s1 == s3)
