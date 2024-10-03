from testing import assert_equal, assert_true
from textkit import parse_csv

fn test_csv_parser() raises:
    var rows = parse_csv("""1,2,3
4,5,6
"7",8,"9"
10,"(11,""11"")",-12""")
    assert_equal(4, len(rows))
    assert_equal("1", rows[0][0])
    assert_equal("2", rows[0][1])
    assert_equal("3", rows[0][2])
    assert_equal("4", rows[1][0])
    assert_equal("5", rows[1][1])
    assert_equal("6", rows[1][2])
    assert_equal("7", rows[2][0])
    assert_equal("8", rows[2][1])
    assert_equal("9", rows[2][2])
    assert_equal("10", rows[3][0])
    assert_equal("(11,\"11\")", rows[3][1])
    assert_equal("-12", rows[3][2])
