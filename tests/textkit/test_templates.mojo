from textkit import Object, Attr, must_parse_template
from ioutils import StringBuilder
from testing import assert_equal, assert_true

fn test_template() raises:
    template = must_parse_template("Hello, {{ .name }}!")
    data = Object(Attr("name", str("world")))
    sb = StringBuilder()
    template.execute(data, sb)
    assert_equal("Hello, world!", str(sb))
