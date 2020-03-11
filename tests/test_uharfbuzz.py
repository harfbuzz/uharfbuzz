import uharfbuzz as hb
from pathlib import Path
import pytest


TESTDATA = Path(__file__).parent / "data"
ADOBE_BLANK_TTF = (TESTDATA / "AdobeBlank.subset.ttf").read_bytes()


@pytest.fixture
def blankfont():
    """Return a subset of AdobeBlank.ttf containing the following glyphs/characters:
    [
        {gid=0, name=".notdef"},
        {gid=1, name="a", code=0x61},
        {gid=2, name="b", code=0x62},
        {gid=3, name="c", code=0x63},
        {gid=4, name="d", code=0x64},
        {gid=5, name="e", code=0x65},
        {gid=6, name="ccedilla", code=0x62},
        {gid=7, name="uni0431", code=0x0431},  # CYRILLIC SMALL LETTER BE
        {gid=8, name="u1F4A9", code=0x1F4A9},  # PILE OF POO
    ]
    """
    face = hb.Face(ADOBE_BLANK_TTF)
    font = hb.Font(face)
    upem = face.upem
    font.scale = (upem, upem)
    hb.ot_font_set_funcs(font)
    return font


class TestBuffer:
    def test_init(self):
        buf = hb.Buffer()

    def test_create(self):
        buf = hb.Buffer.create()

    @pytest.mark.parametrize(
        "string, expected",
        [
            ("abcde", [(0x61, 0), (0x62, 1), (0x63, 2), (0x64, 3), (0x65, 4)]),
            ("abçde", [(0x61, 0), (0x62, 1), (0xE7, 2), (0x64, 3), (0x65, 4)]),
            ("aбcde", [(0x61, 0), (0x431, 1), (0x63, 2), (0x64, 3), (0x65, 4)]),
            ("abc💩e", [(0x61, 0), (0x62, 1), (0x63, 2), (0x1F4A9, 3), (0x65, 4)]),
        ],
        ids=["ascii", "latin1", "ucs2", "ucs4"],
    )
    def test_add_str(self, string, expected):
        buf = hb.Buffer()
        buf.add_str(string)
        infos = [(g.codepoint, g.cluster) for g in buf.glyph_infos]
        assert infos == expected

    def test_add_utf8(self):
        buf = hb.Buffer()
        buf.add_utf8("aбç💩e".encode("utf-8"))
        infos = [(g.codepoint, g.cluster) for g in buf.glyph_infos]
        assert infos == [(0x61, 0), (0x431, 1), (0xE7, 3), (0x1F4A9, 5), (0x65, 9)]

    def test_add_codepoints(self):
        buf = hb.Buffer()
        buf.add_codepoints([0x61, 0x431, 0xE7, 0x1F4A9, 0x65])
        infos = [(g.codepoint, g.cluster) for g in buf.glyph_infos]
        assert infos == [(0x61, 0), (0x431, 1), (0xE7, 2), (0x1F4A9, 3), (0x65, 4)]

    def test_guess_set_segment_properties(self):
        buf = hb.Buffer()
        buf.add_str("הארץ")

        buf.guess_segment_properties()

        assert buf.direction == "rtl"
        assert buf.script == "Hebr"
        # the guessed language seems to be locale specific
        # assert buf.language == "en-us"
        assert buf.language

        buf.direction = "ltr"
        assert buf.direction == "ltr"

        buf.script = "Latn"
        assert buf.script == "Latn"

        buf.language = "he-il"
        assert buf.language == "he-il"


class TestShape:
    @pytest.mark.parametrize(
        "string, expected",
        [
            ("abcde", [(1, 0), (2, 1), (3, 2), (4, 3), (5, 4)]),
            ("abçde", [(1, 0), (2, 1), (6, 2), (4, 3), (5, 4)]),
            ("aбcde", [(1, 0), (7, 1), (3, 2), (4, 3), (5, 4)]),
            ("abc💩e", [(1, 0), (2, 1), (3, 2), (8, 3), (5, 4)]),
        ],
        ids=["ascii", "latin1", "ucs2", "ucs4"],
    )
    def test_gid_and_cluster_no_features(self, blankfont, string, expected):
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf)
        infos = [(g.codepoint, g.cluster) for g in buf.glyph_infos]
        assert infos == expected


class TestCallbacks:
    def test_nominal_glyph_func(self, blankfont):
        string = "abcde"
        expected = [97, 98, 99, 100, 101]
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()

        def nominal_glyph_func(font, code_point, data):
            return code_point

        funcs = hb.FontFuncs.create()
        funcs.set_nominal_glyph_func(nominal_glyph_func, None)
        blankfont.funcs = funcs

        hb.shape(blankfont, buf)
        infos = [g.codepoint for g in buf.glyph_infos]
        assert infos == expected

    def test_glyph_h_advance_func(self, blankfont):
        string = "abcde"
        expected = [456, 456, 456, 456, 456]
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()

        def h_advance_func(font, gid, data):
            return 456

        funcs = hb.FontFuncs.create()
        funcs.set_glyph_h_advance_func(h_advance_func, None)
        blankfont.funcs = funcs

        hb.shape(blankfont, buf)
        infos = [pos.x_advance for pos in buf.glyph_positions]
        assert infos == expected

    def test_glyph_v_metrics_funcs(self, blankfont):
        string = "abcde"
        expected = [(456, -345, -567)] * 5
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        buf.direction = "TTB"

        def v_advance_func(font, gid, data):
            return 456

        def v_origin_func(font, gid, data):
            return (True, 345, 567)

        funcs = hb.FontFuncs.create()
        funcs.set_glyph_v_advance_func(v_advance_func, None)
        funcs.set_glyph_v_origin_func(v_origin_func, None)
        blankfont.funcs = funcs

        hb.shape(blankfont, buf)
        infos = [(pos.y_advance, pos.x_offset, pos.y_offset) for pos in buf.glyph_positions]
        assert infos == expected

    def test_message_func(self, blankfont):
        string = "edcba"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()

        messages = []
        infos_trace = []
        positions_trace = []

        def message(msg):
            messages.append(msg)
            infos_trace.append(buf.glyph_infos)
            positions_trace.append(buf.glyph_positions)

        buf.set_message_func(message)
        hb.shape(blankfont, buf)
        gids = [g.codepoint for g in buf.glyph_infos]
        assert gids == [5, 4, 1, 2, 1]
        pos = [g.x_advance for g in buf.glyph_positions]
        assert pos == [0, 0, 0, 100, 0]
        # messages: start GSUB lookup, end GSUB lookup, start GPOS lookup, end GPOS lookup
        assert messages == ['start lookup 0', 'end lookup 0', 'start lookup 0', 'end lookup 0']
        gids_trace = [[g.codepoint for g in infos] for infos in infos_trace]
        assert gids_trace == [[5, 4, 3, 2, 1], [5, 4, 1, 2, 1],
                              [5, 4, 1, 2, 1], [5, 4, 1, 2, 1]]
        advances_trace = [[g.x_advance for g in pos] for pos in positions_trace]
        assert advances_trace == [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0],
                                  [0, 0, 0, 0, 0], [0, 0, 0, 100, 0]]
