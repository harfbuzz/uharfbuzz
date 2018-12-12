import uharfbuzz as hb


class TestBuffer:

    def test_init(self):
        buf = hb.Buffer()

    def test_create(self):
        buf = hb.Buffer.create()

    def test_add_str_ascii(self):
        buf = hb.Buffer()
        buf.add_str("abcde")

    def test_add_str_latin1(self):
        buf = hb.Buffer()
        buf.add_str("abçde")

    def test_add_str_ucs2(self):
        buf = hb.Buffer()
        buf.add_str("aбcde")

    def test_add_str_ucs4(self):
        buf = hb.Buffer()
        buf.add_str("abcd💩e")
