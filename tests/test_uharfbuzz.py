import uharfbuzz as hb


class TestBuffer:

    def test_init(self):
        buf = hb.Buffer()

    def test_create(self):
        buf = hb.Buffer.create()
