from textkit import Object, Attr, must_parse_template
from ioutils import StringBuilder

fn main() raises:
    template = must_parse_template("Hello, {{ .name }}!")
    data = Object(Attr("name", str("world")))
    sb = StringBuilder()
    template.execute(data, sb)
    print(sb)
