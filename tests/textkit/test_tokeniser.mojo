from testing import assert_equal, assert_true
from textkit import Tokeniser, Token, word, symbol, string, number, eol, eof, unquote, Span
from memory import UnsafePointer

fn test_unquote() raises:
    assert_equal("\"abcd", unquote("\\\"abcd"))
    assert_equal("abcd\"", unquote("abcd\\\""))
    assert_equal("ab\"cd", unquote("ab\\\"cd"))
    assert_equal("ab\\cd", unquote("ab\\\\cd"))
    assert_equal("ab\ncd", unquote("ab\\ncd"))

fn check_token(tokeniser: Tokeniser, type: Int, form: String, line: Int, column: Int, has_esc: Bool, token: Token) raises:
    var msg = String.format("actual: {} {}:{} '{}'", token.type, token.line, token.column, str(tokeniser.form(token)))
    assert_equal(type, token.type, msg=msg)
    assert_equal(form, tokeniser.form(token), msg=msg)
    assert_equal(line, token.line, msg=msg)
    assert_equal(column, token.column, msg=msg)
    assert_equal(has_esc, token.has_esc, msg=msg)

fn test_tokenise_with_unquote() raises:
    var tokeniser = Tokeniser("abcd \"ab\\\"cd\" .\n\n")
    var tokens = tokeniser.tokenise()
    assert_equal(4, len(tokens))
    check_token(tokeniser, word, "abcd", 1, 1, False, tokens[0])
    check_token(tokeniser, string, "ab\\\"cd", 1, 6, True, tokens[1])
    check_token(tokeniser, symbol, ".", 1, 15, False, tokens[2])
    check_token(tokeniser, eof, "", 3, 1, False, tokens[3])

# fn test_tokenise_without_eol() raises:    
#     var tokeniser = Tokeniser("""
#     {
#         "ab": 12,
#         "cd": [34, 56]
#     }
#     """, keep_eol = False)
#     var tokens = tokeniser.tokenise()
#     assert_equal(14, len(tokens))
#     assert_true(Token(symbol, "{", 2, 5, False) == tokens[0], msg="actual: " + str(tokens[0]))
#     assert_true(Token(string, "ab", 3, 9, False) == tokens[1], msg="actual: " + str(tokens[1]))
#     assert_true(Token(symbol, ":", 3, 13, False) == tokens[2], msg="actual: " + str(tokens[2]))
#     assert_true(Token(number, "12", 3, 15, False) == tokens[3], msg="actual: " + str(tokens[3]))
#     assert_true(Token(symbol, ",", 3, 17, False) == tokens[4], msg="actual: " + str(tokens[4]))
#     assert_true(Token(string, "cd", 4, 9, False) == tokens[5], msg="actual: " + str(tokens[5]))
#     assert_true(Token(symbol, ":", 4, 13, False) == tokens[6], msg="actual: " + str(tokens[6]))
#     assert_true(Token(symbol, "[", 4, 15, False) == tokens[7], msg="actual: " + str(tokens[7]))
#     assert_true(Token(number, "34", 4, 16, False) == tokens[8], msg="actual: " + str(tokens[8]))
#     assert_true(Token(symbol, ",", 4, 18, False) == tokens[9], msg="actual: " + str(tokens[9]))
#     assert_true(Token(number, "56", 4, 20, False) == tokens[10], msg="actual: " + str(tokens[10]))
#     assert_true(Token(symbol, "]", 4, 22, False) == tokens[11], msg="actual: " + str(tokens[11]))
#     assert_true(Token(symbol, "}", 5, 5, False) == tokens[12], msg="actual: " + str(tokens[12]))
#     assert_true(Token(eof, "", 6, 5, False) == tokens[13], msg="actual: " + str(tokens[13]))

# fn test_tokenise_with_eol() raises:
#     var tokeniser = Tokeniser("""
#     {
#         "ab": 12,
#         "cd": [34, 56]
#     }
#     """, keep_eol = True)
#     var tokens = tokeniser.tokenise()
#     assert_equal(19, len(tokens))
#     assert_true(Token(eol, "\n", 1, 1, False) == tokens[0], msg="actual: " + str(tokens[0]))
#     assert_true(Token(symbol, "{", 2, 5, False) == tokens[1], msg="actual: " + str(tokens[1]))
#     assert_true(Token(eol, "\n", 2, 6, False) == tokens[2], msg="actual: " + str(tokens[2]))
#     assert_true(Token(string, "ab", 3, 9, False) == tokens[3], msg="actual: " + str(tokens[3]))
#     assert_true(Token(symbol, ":", 3, 13, False) == tokens[4], msg="actual: " + str(tokens[4]))
#     assert_true(Token(number, "12", 3, 15, False) == tokens[5], msg="actual: " + str(tokens[5]))
#     assert_true(Token(symbol, ",", 3, 17, False) == tokens[6], msg="actual: " + str(tokens[6]))
#     assert_true(Token(eol, "\n", 3, 18, False) == tokens[7], msg="actual: " + str(tokens[7]))
#     assert_true(Token(string, "cd", 4, 9, False) == tokens[8], msg="actual: " + str(tokens[9]))
#     assert_true(Token(symbol, ":", 4, 13, False) == tokens[9], msg="actual: " + str(tokens[9]))
#     assert_true(Token(symbol, "[", 4, 15, False) == tokens[10], msg="actual: " + str(tokens[10]))
#     assert_true(Token(number, "34", 4, 16, False) == tokens[11], msg="actual: " + str(tokens[11]))
#     assert_true(Token(symbol, ",", 4, 18, False) == tokens[12], msg="actual: " + str(tokens[12]))
#     assert_true(Token(number, "56", 4, 20, False) == tokens[13], msg="actual: " + str(tokens[13]))
#     assert_true(Token(symbol, "]", 4, 22, False) == tokens[14], msg="actual: " + str(tokens[14]))
#     assert_true(Token(eol, "\n", 4, 23, False) == tokens[15], msg="actual: " + str(tokens[15]))
#     assert_true(Token(symbol, "}", 5, 5, False) == tokens[16], msg="actual: " + str(tokens[16]))
#     assert_true(Token(eol, "\n", 5, 6, False) == tokens[17], msg="actual: " + str(tokens[17]))
#     assert_true(Token(eof, "", 6, 5, False) == tokens[18], msg="actual: " + str(tokens[18]))
