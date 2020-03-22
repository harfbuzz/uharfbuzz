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

        buf.set_script_from_ot_tag("mym2")
        assert buf.script == "Mymr"

        buf.set_language_from_ot_tag("BGR")
        assert buf.language == "bg"


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
        # Glyph IDs 1, 2, 3, 4, 5 map to glyphs a, b, c, d, e.
        # The calt feature replaces c by a in the context e, d, c', b, a.
        # The kern feature kerns b, a by +100.
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

class TestGetBaseline:
    # The test font contains a BASE table with some test values
    def test_ot_layout_get_baseline_invalid_tag(self, blankfont):
        with pytest.raises(ValueError):
            # invalid baseline tag
            baseline = hb.ot_layout_get_baseline(blankfont, "xxxx", "LTR", "", "")

    @pytest.mark.parametrize(
        "baseline_tag, script_tag, direction, expected_value",
        [
            ("icfb", "grek", "LTR", None),  # BASE table doesn't contain grek script

            ("icfb", "latn", "LTR", -70),
            ("icft", "latn", "LTR", 830),
            ("romn", "latn", "LTR", 0),
            ("ideo", "latn", "LTR", -120),

            ("icfb", "kana", "LTR", -71),
            ("icft", "kana", "LTR", 831),
            ("romn", "kana", "LTR", 1),
            ("ideo", "kana", "LTR", -121),

            ("icfb", "latn", "TTB", 50),
            ("icft", "latn", "TTB", 950),
            ("romn", "latn", "TTB", 120),
            ("ideo", "latn", "TTB", 0),

            ("icfb", "kana", "TTB", 51),
            ("icft", "kana", "TTB", 951),
            ("romn", "kana", "TTB", 121),
            ("ideo", "kana", "TTB", 1),
        ]
    )
    def test_ot_layout_get_baseline(self, blankfont, baseline_tag, script_tag, direction, expected_value):
        value = hb.ot_layout_get_baseline(blankfont, baseline_tag, direction, script_tag, "")
        assert value == expected_value

class TestGetTags:
    def test_ot_layout_language_get_feature_tags(self, blankfont):
        tags = hb.ot_layout_language_get_feature_tags(blankfont.face, "GPOS")
        assert tags == ['kern']
        tags = hb.ot_layout_language_get_feature_tags(blankfont.face, "GSUB")
        assert tags == ['calt']

    def test_ot_layout_table_get_script_tags(self, blankfont):
        tags = hb.ot_layout_table_get_script_tags(blankfont.face, "GPOS")
        assert tags == ['DFLT']

    def test_ot_layout_script_get_language_tags(self, blankfont):
        tags = hb.ot_layout_script_get_language_tags(blankfont.face, "GPOS", 0)
        assert tags == []
