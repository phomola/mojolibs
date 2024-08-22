from testing import assert_equal, assert_true
from textkit import tokenise, Token, symbol, string, number, eol, eof

fn test_tokenise_without_eol() raises:
    var tokens = tokenise("""
    {
        "ab": 12,
        "cd": [34, 56]
    }
    """, keep_eol = False)
    assert_equal(14, len(tokens))
    assert_true(Token(symbol, "{", 2, 5) == tokens[0], msg="actual: " + str(tokens[0]))
    assert_true(Token(string, "ab", 3, 9) == tokens[1], msg="actual: " + str(tokens[1]))
    assert_true(Token(symbol, ":", 3, 13) == tokens[2], msg="actual: " + str(tokens[2]))
    assert_true(Token(number, "12", 3, 15) == tokens[3], msg="actual: " + str(tokens[3]))
    assert_true(Token(symbol, ",", 3, 17) == tokens[4], msg="actual: " + str(tokens[4]))
    assert_true(Token(string, "cd", 4, 9) == tokens[5], msg="actual: " + str(tokens[5]))
    assert_true(Token(symbol, ":", 4, 13) == tokens[6], msg="actual: " + str(tokens[6]))
    assert_true(Token(symbol, "[", 4, 15) == tokens[7], msg="actual: " + str(tokens[7]))
    assert_true(Token(number, "34", 4, 16) == tokens[8], msg="actual: " + str(tokens[8]))
    assert_true(Token(symbol, ",", 4, 18) == tokens[9], msg="actual: " + str(tokens[9]))
    assert_true(Token(number, "56", 4, 20) == tokens[10], msg="actual: " + str(tokens[10]))
    assert_true(Token(symbol, "]", 4, 22) == tokens[11], msg="actual: " + str(tokens[11]))
    assert_true(Token(symbol, "}", 5, 5) == tokens[12], msg="actual: " + str(tokens[12]))
    assert_true(Token(eof, "", 6, 5) == tokens[13], msg="actual: " + str(tokens[13]))

fn test_tokenise_with_eol() raises:
    var tokens = tokenise("""
    {
        "ab": 12,
        "cd": [34, 56]
    }
    """, keep_eol = True)
    assert_equal(19, len(tokens))
    assert_true(Token(eol, "\n", 1, 1) == tokens[0], msg="actual: " + str(tokens[0]))
    assert_true(Token(symbol, "{", 2, 5) == tokens[1], msg="actual: " + str(tokens[1]))
    assert_true(Token(eol, "\n", 2, 6) == tokens[2], msg="actual: " + str(tokens[2]))
    assert_true(Token(string, "ab", 3, 9) == tokens[3], msg="actual: " + str(tokens[3]))
    assert_true(Token(symbol, ":", 3, 13) == tokens[4], msg="actual: " + str(tokens[4]))
    assert_true(Token(number, "12", 3, 15) == tokens[5], msg="actual: " + str(tokens[5]))
    assert_true(Token(symbol, ",", 3, 17) == tokens[6], msg="actual: " + str(tokens[6]))
    assert_true(Token(eol, "\n", 3, 18) == tokens[7], msg="actual: " + str(tokens[7]))
    assert_true(Token(string, "cd", 4, 9) == tokens[8], msg="actual: " + str(tokens[9]))
    assert_true(Token(symbol, ":", 4, 13) == tokens[9], msg="actual: " + str(tokens[9]))
    assert_true(Token(symbol, "[", 4, 15) == tokens[10], msg="actual: " + str(tokens[10]))
    assert_true(Token(number, "34", 4, 16) == tokens[11], msg="actual: " + str(tokens[11]))
    assert_true(Token(symbol, ",", 4, 18) == tokens[12], msg="actual: " + str(tokens[12]))
    assert_true(Token(number, "56", 4, 20) == tokens[13], msg="actual: " + str(tokens[13]))
    assert_true(Token(symbol, "]", 4, 22) == tokens[14], msg="actual: " + str(tokens[14]))
    assert_true(Token(eol, "\n", 4, 23) == tokens[15], msg="actual: " + str(tokens[15]))
    assert_true(Token(symbol, "}", 5, 5) == tokens[16], msg="actual: " + str(tokens[16]))
    assert_true(Token(eol, "\n", 5, 6) == tokens[17], msg="actual: " + str(tokens[17]))
    assert_true(Token(eof, "", 6, 5) == tokens[18], msg="actual: " + str(tokens[18]))
