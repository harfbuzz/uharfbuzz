import uharfbuzz as hb
from pathlib import Path
import sys
import platform
import pytest


TESTDATA = Path(__file__).parent / "data"
ADOBE_BLANK_TTF_PATH = TESTDATA / "AdobeBlank.subset.ttf"
OPEN_SANS_TTF_PATH = TESTDATA / "OpenSans.subset.ttf"
MUTATOR_SANS_TTF_PATH = TESTDATA / "MutatorSans-VF.subset.ttf"
SPARSE_FONT_TTF_PATH = TESTDATA / "SparseFont.ttf"
MATH_FONT_TTF_PATH = TESTDATA / "STIXTwoMath-Regular.ttf"


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
    blob = hb.Blob.from_file_path(ADOBE_BLANK_TTF_PATH)
    face = hb.Face(blob)
    font = hb.Font(face)
    return font


@pytest.fixture
def opensans():
    """Return a subset of OpenSans.ttf containing the following glyphs/characters:
    [
        {gid=0, name=".notdef"},
        {gid=1, name="A", code=0x41},
    ]
    """
    blob = hb.Blob(OPEN_SANS_TTF_PATH.read_bytes())
    face = hb.Face(blob)
    font = hb.Font(face)
    return font


@pytest.fixture
def mutatorsans():
    """Return a subset of MutatorSans-VF with a wdth and wght axis."""
    face = hb.Face(MUTATOR_SANS_TTF_PATH.read_bytes())
    font = hb.Font(face)
    return font


@pytest.fixture
def sparsefont():
    """Return a font that only has a few tables:
    GPOS, cmap, head, maxp and post"""
    face = hb.Face(SPARSE_FONT_TTF_PATH.read_bytes())
    font = hb.Font(face)
    return font


@pytest.fixture
def mathfont():
    """Return a subset of STIX Two Math font with only MATH, post, head, and maxp tables"""
    face = hb.Face(MATH_FONT_TTF_PATH.read_bytes())
    font = hb.Font(face)
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
        flags = [(g.flags) for g in buf.glyph_infos]
        assert all(0 == f for f in flags)
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

    def test_empty_buffer_props(self):
        buf = hb.Buffer()
        assert buf.script == None
        assert buf.language == None
        assert buf.direction == "invalid"

    def test_cluster_level(self):
        buf = hb.Buffer()

        assert buf.cluster_level == hb.BufferClusterLevel.DEFAULT

        buf.cluster_level = hb.BufferClusterLevel.MONOTONE_CHARACTERS
        assert buf.cluster_level == hb.BufferClusterLevel.MONOTONE_CHARACTERS

        buf.cluster_level = hb.BufferClusterLevel.MONOTONE_GRAPHEMES
        assert buf.cluster_level == hb.BufferClusterLevel.MONOTONE_GRAPHEMES

        buf.cluster_level = hb.BufferClusterLevel.CHARACTERS
        assert buf.cluster_level == hb.BufferClusterLevel.CHARACTERS

        buf.cluster_level = hb.BufferClusterLevel.DEFAULT
        assert buf.cluster_level == hb.BufferClusterLevel.DEFAULT

    def test_cluster_level_int(self):
        buf = hb.Buffer()

        assert buf.cluster_level == 0

        buf.cluster_level = 1
        assert buf.cluster_level == 1

        with pytest.raises(ValueError):
            # 5 is not a valid BufferClusterLevel
            buf.cluster_level = 5
        assert buf.cluster_level == 1

    def test_properties(self):
        buf = hb.Buffer()

        assert len(buf) == 0

        assert buf.flags == hb.BufferFlags.DEFAULT
        buf.flags = hb.BufferFlags.BOT | hb.BufferFlags.EOT
        assert buf.flags == hb.BufferFlags.BOT | hb.BufferFlags.EOT

        assert buf.content_type == hb.BufferContentType.INVALID
        buf.content_type = hb.BufferContentType.UNICODE
        assert buf.content_type == hb.BufferContentType.UNICODE

        assert buf.cluster_level == hb.BufferClusterLevel.DEFAULT
        buf.cluster_level = hb.BufferClusterLevel.CHARACTERS
        assert buf.cluster_level == hb.BufferClusterLevel.CHARACTERS

        assert buf.replacement_codepoint == hb.Buffer.DEFAULT_REPLACEMENT_CODEPOINT
        buf.replacement_codepoint = 0
        assert buf.replacement_codepoint == 0

        buf.add_str("ABC")
        assert len(buf) == 3
        buf.clear_contents()
        assert len(buf) == 0
        assert buf.flags == hb.BufferFlags.BOT | hb.BufferFlags.EOT
        buf.reset()
        assert buf.flags == hb.BufferFlags.DEFAULT


class TestBlob:
    def test_from_file_path_fail(self):
        with pytest.raises(hb.HarfBuzzError, match="Failed to open: DOES-NOT-EXIST"):
            blob = hb.Blob.from_file_path("DOES-NOT-EXIST")


class TestFace:
    def test_properties(self, blankfont):
        face = blankfont.face

        assert face.index == 0
        assert face.upem == 1000
        assert face.glyph_count == 9
        assert face.table_tags == [
            "BASE",
            "GPOS",
            "GSUB",
            "OS/2",
            "cmap",
            "cvt ",
            "fpgm",
            "gasp",
            "glyf",
            "head",
            "hhea",
            "hmtx",
            "loca",
            "maxp",
            "name",
            "post",
            "prep",
        ]

        assert face.unicodes == hb.Set(
            {0x61, 0x62, 0x63, 0x64, 0x65, 0xE7, 0x431, 0x1F4A9}
        )
        assert face.variation_selectors == hb.Set()
        assert face.variation_unicodes(1) == hb.Set()


class TestFont:
    def test_get_glyph_extents(self, opensans):
        # <TTGlyph name="A" xMin="0" yMin="0" xMax="1296" yMax="1468">
        extents = opensans.get_glyph_extents(1)
        assert (0, 1468, 1296, -1468) == extents
        assert 0 == extents.x_bearing
        assert 1468 == extents.y_bearing
        assert 1296 == extents.width
        assert -1468 == extents.height
        assert opensans.get_glyph_extents(1000) is None

    def test_get_font_extents(self, blankfont):
        extents = blankfont.get_font_extents("ltr")
        assert (880, -120, 0) == extents
        assert 880 == extents.ascender
        assert -120 == extents.descender
        assert 0 == extents.line_gap
        extents = blankfont.get_font_extents("ttb")
        assert (500, -500, 0) == extents
        assert 500 == extents.ascender
        assert -500 == extents.descender
        assert 0 == extents.line_gap

    def test_get_glyph_name(self, blankfont):
        glyph_name = blankfont.get_glyph_name(1)
        assert glyph_name == "a"
        glyph_name = blankfont.get_glyph_name(1000)
        assert glyph_name is None

    def test_get_nominal_glyph(self, blankfont):
        gid = blankfont.get_nominal_glyph(ord("a"))
        assert gid == 1
        gid = blankfont.get_nominal_glyph(ord("å"))
        assert gid is None

    def test_get_var_coords_normalized(self, mutatorsans):
        coords = mutatorsans.get_var_coords_normalized()
        assert coords == []
        mutatorsans.set_variations({"wght": 500})
        coords = mutatorsans.get_var_coords_normalized()
        assert coords == [0, 0.5]
        mutatorsans.set_variations({"wdth": 1000})
        coords = mutatorsans.get_var_coords_normalized()
        assert coords == [1.0, 0]
        mutatorsans.set_variations({"wdth": 250, "wght": 250})
        coords = mutatorsans.get_var_coords_normalized()
        assert coords == [0.25, 0.25]

    def test_set_var_coords_normalized(self, mutatorsans):
        expected_coords = [0.5, 0.25]
        mutatorsans.set_var_coords_normalized(expected_coords)
        coords = mutatorsans.get_var_coords_normalized()
        assert expected_coords == coords

        expected_coords = [0.5]
        mutatorsans.set_var_coords_normalized(expected_coords)
        coords = mutatorsans.get_var_coords_normalized()
        assert expected_coords == coords

        with pytest.raises(TypeError):
            mutatorsans.set_var_coords_normalized(["a"])

    def test_properties(self, blankfont):
        assert blankfont.scale == (1000, 1000)
        blankfont.scale = (1024, 1024)
        assert blankfont.scale == (1024, 1024)

        assert blankfont.ppem == (0, 0)
        blankfont.ppem = (16, 24)
        assert blankfont.ppem == (16, 24)

        assert blankfont.ptem == 0
        blankfont.ptem = 12.0
        assert blankfont.ptem == 12.0

        assert blankfont.synthetic_slant == 0
        blankfont.synthetic_slant = 0.2
        assert blankfont.synthetic_slant == pytest.approx(0.2)


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

    def test_shape_set_shaper(self, blankfont):
        string = "abcde"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, shapers=["fallback"])
        pos = [g.position for g in buf.glyph_positions]
        expected = [
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
        ]
        assert pos == expected

    @pytest.mark.skipif(sys.platform != "win32", reason="requires Windows")
    def test_shape_set_shaper_directwrite(self, blankfont):
        string = "abcde"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, shapers=["directwrite"])
        pos = [g.position for g in buf.glyph_positions]
        expected = [
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
        ]
        assert pos == expected

    @pytest.mark.xfail
    @pytest.mark.skipif(sys.platform != "win32", reason="requires Windows")
    def test_shape_set_shaper_uniscribe(self, blankfont):
        string = "abcde"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, shapers=["uniscribe"])
        pos = [g.position for g in buf.glyph_positions]
        expected = [
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
        ]
        assert pos == expected

    @pytest.mark.skipif(sys.platform != "darwin", reason="requires macOS")
    def test_shape_set_shaper_coretext(self, blankfont):
        string = "abcde"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, shapers=["coretext"])
        pos = [g.position for g in buf.glyph_positions]
        expected = [
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
            (0, 0, 0, 0),
        ]
        assert pos == expected

    @pytest.mark.parametrize(
        "string, expected",
        [
            ("abcde", ["a", "b", "c", "d", "e"]),
            ("abçde", ["a", "b", "ccedilla", "d", "e"]),
            ("aбcde", ["a", "uni0431", "c", "d", "e"]),
            ("abc💩e", ["a", "b", "c", "u1F4A9", "e"]),
        ],
        ids=["ascii", "latin1", "ucs2", "ucs4"],
    )
    def test_glyh_name_no_features(self, blankfont, string, expected):
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf)
        # font.get_glyph_name() returns None if the font does not contain glyph names
        # or if the glyph ID does not exist.
        glyph_names = [blankfont.get_glyph_name(g.codepoint) for g in buf.glyph_infos]
        assert glyph_names == expected
        assert blankfont.get_glyph_name(1000) is None
        # font.glyph_to_string() return "gidN" if the font does not contain glyph names
        # or if the glyph ID does not exist.
        glyph_names = [blankfont.glyph_to_string(g.codepoint) for g in buf.glyph_infos]
        assert glyph_names == expected
        assert blankfont.glyph_to_string(1000) == "gid1000"

    @pytest.mark.parametrize(
        "string, features, expected",
        [
            # The calt feature replaces c by a in the context e, d, c', b, a.
            ("edcbaedcba", {}, ["e", "d", "a", "b", "a", "e", "d", "a", "b", "a"]),
            (
                "edcbaedcba",
                {"calt[2]": False},
                ["e", "d", "c", "b", "a", "e", "d", "a", "b", "a"],
            ),
            (
                "edcbaedcba",
                {"calt": [(7, 8, False)]},
                ["e", "d", "a", "b", "a", "e", "d", "c", "b", "a"],
            ),
            (
                "edcbaedcba",
                {"calt": [(0, 10, False), (7, 8, True)]},
                ["e", "d", "c", "b", "a", "e", "d", "a", "b", "a"],
            ),
        ],
    )
    def test_features_slice(self, blankfont, string, features, expected):
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, features)

        glyph_names = [blankfont.glyph_to_string(g.codepoint) for g in buf.glyph_infos]
        assert glyph_names == expected


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
        funcs.set_nominal_glyph_func(nominal_glyph_func)
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
        funcs.set_glyph_h_advance_func(h_advance_func)
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
        funcs.set_glyph_v_advance_func(v_advance_func)
        funcs.set_glyph_v_origin_func(v_origin_func)
        blankfont.funcs = funcs

        hb.shape(blankfont, buf)
        infos = [
            (pos.y_advance, pos.x_offset, pos.y_offset) for pos in buf.glyph_positions
        ]
        assert infos == expected

    def test_font_extents_funcs(self, blankfont):
        def font_h_extents_func(font, data):
            return hb.FontExtents(123, -456, 789)

        def font_v_extents_func(font, data):
            return hb.FontExtents(987, -654, 321)

        funcs = hb.FontFuncs.create()
        funcs.set_font_h_extents_func(font_h_extents_func)
        funcs.set_font_v_extents_func(font_v_extents_func)
        blankfont.funcs = funcs
        assert (123, -456, 789) == blankfont.get_font_extents("ltr")
        assert (987, -654, 321) == blankfont.get_font_extents("ttb")

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
        expected_messages = [
            "start table GSUB script tag 'DFLT'",
            "start lookup 0 feature 'calt'",
            "recursing to lookup 1 at 2",
            "replacing glyph at 2 (single substitution)",
            "replaced glyph at 2 (single substitution)",
            "recursed to lookup 1",
            "end lookup 0 feature 'calt'",
            "end table GSUB script tag 'DFLT'",
            "start table GPOS script tag 'DFLT'",
            "start lookup 0 feature 'kern'",
            "try kerning glyphs at 3,4",
            "kerned glyphs at 3,4",
            "tried kerning glyphs at 3,4",
            "end lookup 0 feature 'kern'",
            "end table GPOS script tag 'DFLT'",
        ]
        assert messages == expected_messages
        gids_trace = [[g.codepoint for g in infos] for infos in infos_trace]
        assert gids_trace == [
            [5, 4, 3, 2, 1],
            [5, 4, 3, 2, 1],
            [5, 4, 3, 2, 1],
            [5, 4, 3, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
            [5, 4, 1, 2, 1],
        ]
        advances_trace = [[g.x_advance for g in pos] for pos in positions_trace if pos]
        assert advances_trace == [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 100, 0],
            [0, 0, 0, 100, 0],
            [0, 0, 0, 100, 0],
            [0, 0, 0, 100, 0],
        ]

    def test_message_func_return_false(self, blankfont):
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
            return False

        buf.set_message_func(message)
        hb.shape(blankfont, buf)
        gids = [g.codepoint for g in buf.glyph_infos]
        assert gids == [5, 4, 3, 2, 1]
        pos = [g.x_advance for g in buf.glyph_positions]
        assert pos == [0, 0, 0, 0, 0]
        expected_messages = [
            "start table GSUB script tag 'DFLT'",
            "start table GPOS script tag 'DFLT'",
        ]
        assert messages == expected_messages
        gids_trace = [[g.codepoint for g in infos] for infos in infos_trace]
        assert gids_trace == [[5, 4, 3, 2, 1], [5, 4, 3, 2, 1]]
        advances_trace = [[g.x_advance for g in pos] for pos in positions_trace if pos]
        assert advances_trace == [[0, 0, 0, 0, 0]]

    def test_message_func_crash(self, blankfont):
        string = "edcba"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        message_collector = MessageCollector()
        buf.set_message_func(message_collector.message)
        hb.shape(blankfont, buf)

    def test_draw_funcs(self, opensans):
        funcs = hb.DrawFuncs()
        container = []

        def move_to(x, y, c):
            c.append(f"M{x:g},{y:g}")

        def line_to(x, y, c):
            c.append(f"L{x:g},{y:g}")

        def cubic_to(c1x, c1y, c2x, c2y, x, y, c):
            c.append(f"C{c1x:g},{c1y:g} {c2x:g},{c2y:g} {x:g},{y:g}")

        def quadratic_to(c1x, c1y, x, y, c):
            c.append(f"Q{c1x:g},{c1y:g} {x:g},{y:g}")

        def close_path(c):
            c.append("Z")

        funcs.set_move_to_func(move_to, container)
        funcs.set_line_to_func(line_to, container)
        funcs.set_cubic_to_func(cubic_to, container)
        funcs.set_quadratic_to_func(quadratic_to, container)
        funcs.set_close_path_func(close_path, container)
        opensans.draw_glyph(funcs, 1)
        assert (
            "".join(container)
            == "M1120,0L938,465L352,465L172,0L0,0L578,1468L721,1468L1296,0L1120,0ZM885,618L715,1071Q682,1157 647,1282Q625,1186 584,1071L412,618L885,618Z"
        )

    def test_draw_funcs(self, opensans):
        funcs = hb.DrawFuncs()
        container = []

        def move_to(x, y, c):
            c.append(f"M{x:g},{y:g}")

        def line_to(x, y, c):
            c.append(f"L{x:g},{y:g}")

        def cubic_to(c1x, c1y, c2x, c2y, x, y, c):
            c.append(f"C{c1x:g},{c1y:g} {c2x:g},{c2y:g} {x:g},{y:g}")

        def quadratic_to(c1x, c1y, x, y, c):
            c.append(f"Q{c1x:g},{c1y:g} {x:g},{y:g}")

        def close_path(c):
            c.append("Z")

        funcs.set_move_to_func(move_to)
        funcs.set_line_to_func(line_to)
        funcs.set_cubic_to_func(cubic_to)
        funcs.set_quadratic_to_func(quadratic_to)
        funcs.set_close_path_func(close_path)
        opensans.draw_glyph(1, funcs, container)
        assert (
            "".join(container)
            == "M1120,0L938,465L352,465L172,0L0,0L578,1468L721,1468L1296,0L1120,0ZM885,618L715,1071Q682,1157 647,1282Q625,1186 584,1071L412,618L885,618Z"
        )

    @pytest.mark.xfail(
        platform.python_implementation() == "PyPy",
        reason="PyPy's ctypes has no 'pythonapi' attribute",
    )
    def test_draw_funcs_pycapsule(self, opensans):
        import ctypes
        import uharfbuzz._harfbuzz_test

        funcs = hb.DrawFuncs()

        PyCapsule_New = ctypes.pythonapi.PyCapsule_New
        PyCapsule_New.restype = ctypes.py_object
        PyCapsule_New.argtypes = (ctypes.c_void_p, ctypes.c_char_p, ctypes.c_void_p)

        def cap(x):
            return PyCapsule_New(x, None, None)

        lib = ctypes.cdll.LoadLibrary(uharfbuzz._harfbuzz_test.__file__)
        container = ctypes.create_string_buffer(1000)
        container_cap = cap(container)

        funcs.set_move_to_func(cap(lib._test_move_to))
        funcs.set_line_to_func(cap(lib._test_line_to))
        funcs.set_cubic_to_func(cap(lib._test_cubic_to))
        funcs.set_quadratic_to_func(cap(lib._test_quadratic_to))
        funcs.set_close_path_func(cap(lib._test_close_path))
        opensans.draw_glyph(1, funcs, container_cap)

        assert (
            container.value
            == b"M1120,0L938,465L352,465L172,0L0,0L578,1468L721,1468L1296,0L1120,0ZM885,618L715,1071Q682,1157 647,1282Q625,1186 584,1071L412,618L885,618Z"
        )

    def test_draw_pen(self, opensans):
        class TestPen:
            def __init__(self):
                self.value = []

            def moveTo(self, p0):
                self.value.append(("moveTo", (p0,)))

            def lineTo(self, p1):
                self.value.append(("lineTo", (p1,)))

            def qCurveTo(self, *points):
                self.value.append(("qCurveTo", points))

            def curveTo(self, *points):
                self.value.append(("curveTo", points))

            def closePath(self):
                self.value.append(("closePath", ()))

        pen = TestPen()
        opensans.draw_glyph_with_pen(1, pen)
        assert pen.value == [
            ("moveTo", ((1120, 0),)),
            ("lineTo", ((938, 465),)),
            ("lineTo", ((352, 465),)),
            ("lineTo", ((172, 0),)),
            ("lineTo", ((0, 0),)),
            ("lineTo", ((578, 1468),)),
            ("lineTo", ((721, 1468),)),
            ("lineTo", ((1296, 0),)),
            ("lineTo", ((1120, 0),)),
            ("closePath", ()),
            ("moveTo", ((885, 618),)),
            ("lineTo", ((715, 1071),)),
            ("qCurveTo", ((682, 1157), (647, 1282))),
            ("qCurveTo", ((625, 1186), (584, 1071))),
            ("lineTo", ((412, 618),)),
            ("lineTo", ((885, 618),)),
            ("closePath", ()),
        ]


class MessageCollector:
    def message(self, message):
        pass


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
        ],
    )
    def test_ot_layout_get_baseline(
        self, blankfont, baseline_tag, script_tag, direction, expected_value
    ):
        value = hb.ot_layout_get_baseline(
            blankfont, baseline_tag, direction, script_tag, ""
        )
        assert value == expected_value


class TestGetTags:
    def test_ot_layout_language_get_feature_tags(self, blankfont):
        tags = hb.ot_layout_language_get_feature_tags(blankfont.face, "GPOS")
        assert tags == ["kern"]
        tags = hb.ot_layout_language_get_feature_tags(blankfont.face, "GSUB")
        assert tags == ["calt"]

    def test_ot_layout_table_get_script_tags(self, blankfont):
        tags = hb.ot_layout_table_get_script_tags(blankfont.face, "GPOS")
        assert tags == ["DFLT"]

    def test_ot_layout_script_get_language_tags(self, blankfont):
        tags = hb.ot_layout_script_get_language_tags(blankfont.face, "GPOS", 0)
        assert tags == []


class TestOTMath:
    def test_ot_math_has_data(self, mathfont):
        assert hb.ot_math_has_data(mathfont.face)

    def test_ot_math_has_no_data(self, blankfont):
        assert hb.ot_math_has_data(blankfont.face) == False

    @pytest.mark.parametrize(
        "constant, expected",
        [
            (hb.OTMathConstant.SCRIPT_PERCENT_SCALE_DOWN, 70),
            (hb.OTMathConstant.SCRIPT_SCRIPT_PERCENT_SCALE_DOWN, 55),
            (hb.OTMathConstant.RADICAL_KERN_BEFORE_DEGREE, 65),
            (hb.OTMathConstant.RADICAL_KERN_AFTER_DEGREE, -335),
            (hb.OTMathConstant.RADICAL_DEGREE_BOTTOM_RAISE_PERCENT, 55),
        ],
    )
    def test_ot_math_get_constant(self, mathfont, constant, expected):
        assert hb.ot_math_get_constant(mathfont, constant) == expected

    def test_ot_math_get_constant_invalid(self, mathfont):
        with pytest.raises(ValueError):
            hb.ot_math_get_constant(mathfont, 1000)

    @pytest.mark.parametrize(
        "glyph, expected",
        [
            ("uni222B", 230),
            ("uni210B", 40),
            ("uni222B.dsp", 540),
            ("u1D435", 30),
            ("A", 0),
        ],
    )
    def test_ot_math_get_glyph_italics_correction(self, mathfont, glyph, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        assert hb.ot_math_get_glyph_italics_correction(mathfont, gid) == expected

    @pytest.mark.parametrize(
        "glyph, expected",
        [
            ("u1D435", 380),
            ("A", 360),
            ("parenleft", 250),
        ],
    )
    def test_ot_math_get_glyph_top_accent_attachment(self, mathfont, glyph, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        assert hb.ot_math_get_glyph_top_accent_attachment(mathfont, gid) == expected

    @pytest.mark.parametrize(
        "glyph, expected",
        [
            ("A", False),
            ("parenleft", True),
            ("parenright", True),
            ("bar", True),
            ("uni221A", True),
        ],
    )
    def test_ot_math_is_glyph_extended_shape(self, mathfont, glyph, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        assert hb.ot_math_is_glyph_extended_shape(mathfont.face, gid) == expected

    @pytest.mark.parametrize(
        "direction, expected",
        [
            ("LTR", 100),
            ("RTL", 100),
            ("TTB", 100),
            ("BTT", 100),
        ],
    )
    def test_ot_math_get_min_connector_overlap(self, mathfont, direction, expected):
        assert hb.ot_math_get_min_connector_overlap(mathfont, direction) == expected

    @pytest.mark.parametrize(
        "glyph, kern, height, expected",
        [
            ("A", hb.OTMathKern.TOP_RIGHT, 250, 0),
            ("A", hb.OTMathKern.TOP_RIGHT, 300, -18),
            ("A", hb.OTMathKern.TOP_RIGHT, 400, -66),
            ("F", hb.OTMathKern.BOTTOM_RIGHT, 0, -200),
            ("F", hb.OTMathKern.BOTTOM_RIGHT, 150, -44),
            ("F", hb.OTMathKern.BOTTOM_RIGHT, 300, 44),
            ("J", hb.OTMathKern.TOP_LEFT, 250, 64),
            ("J", hb.OTMathKern.TOP_LEFT, 300, -28),
            ("J", hb.OTMathKern.TOP_LEFT, 400, -28),
            ("M", hb.OTMathKern.BOTTOM_LEFT, 0, 40),
            ("M", hb.OTMathKern.BOTTOM_LEFT, 150, 40),
            ("M", hb.OTMathKern.BOTTOM_LEFT, 300, 40),
        ],
    )
    def test_ot_math_get_glyph_kerning(self, mathfont, glyph, kern, height, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        assert hb.ot_math_get_glyph_kerning(mathfont, gid, kern, height) == expected

    def test_ot_math_get_glyph_kerning_invalid(self, mathfont):
        gid = mathfont.get_glyph_from_name("A")
        with pytest.raises(ValueError):
            hb.ot_math_get_glyph_kerning(mathfont, gid, 1000, 100)

    @pytest.mark.parametrize(
        "glyph, kern, expected",
        [
            (
                "u1D434",
                hb.OTMathKern.TOP_RIGHT,
                [(213, 58), (350, -58), (0x7FFFFFFF, -70)],
            ),
            (
                "u1D435",
                hb.OTMathKern.BOTTOM_RIGHT,
                [(160, -50), (283, -12), (0x7FFFFFFF, 20)],
            ),
            (
                "u1D435",
                hb.OTMathKern.TOP_LEFT,
                [(176, 81), (0x7FFFFFFF, -50)],
            ),
            (
                "U",
                hb.OTMathKern.BOTTOM_LEFT,
                [(126, -80), (256, -60), (0x7FFFFFFF, 36)],
            ),
        ],
    )
    def test_ot_math_get_glyph_kernings(self, mathfont, glyph, kern, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        assert hb.ot_math_get_glyph_kernings(mathfont, gid, kern) == expected

    def test_ot_math_get_glyph_kernings_invalid(self, mathfont):
        gid = mathfont.get_glyph_from_name("A")
        with pytest.raises(ValueError):
            hb.ot_math_get_glyph_kernings(mathfont, gid, 1000)

    @pytest.mark.parametrize(
        "glyph, direction, expected",
        [
            (
                "parenleft",
                "TTB",
                [
                    ("parenleft", 933),
                    ("parenleft.s1", 1187),
                    ("parenleft.s2", 1427),
                    ("parenleft.s3", 1667),
                    ("parenleft.s4", 1907),
                    ("parenleft.s5", 2145),
                    ("parenleft.s6", 2385),
                    ("parenleft.s7", 2625),
                    ("parenleft.s8", 2865),
                    ("parenleft.s9", 3101),
                    ("parenleft.s10", 3341),
                    ("parenleft.s11", 3581),
                    ("parenleft.s12", 3821),
                ],
            ),
            ("parenleft", "LTR", []),
            ("uni2211", "TTB", [("uni2211", 1031), ("uni2211.s1", 1326)]),
            (
                "uni0302",
                "LTR",
                [
                    ("uni0302", 283),
                    ("circumflex.s1", 574),
                    ("circumflex.s2", 1003),
                    ("circumflex.s3", 1496),
                    ("circumflex.s4", 1932),
                    ("circumflex.s5", 2385),
                ],
            ),
            ("uni0302", "TTB", []),
        ],
    )
    def test_ot_math_get_glyph_variants(self, mathfont, glyph, direction, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        variants = hb.ot_math_get_glyph_variants(mathfont, gid, direction)
        result = [(mathfont.get_glyph_name(v.glyph), v.advance) for v in variants]
        assert result == expected

    @pytest.mark.parametrize(
        "glyph, direction, expected",
        [
            (
                "parenleft",
                "TTB",
                (
                    [
                        ("uni239D", 0, 250, 1273, 0),
                        ("uni239C", 1000, 1000, 1252, hb.OTMathGlyphPartFlags.EXTENDER),
                        ("uni239B", 250, 0, 1273, 0),
                    ],
                    0,
                ),
            ),
            ("parenleft", "LTR", ([], 0)),
            (
                "uni222B",
                "TTB",
                (
                    [
                        ("uni2321", 0, 800, 1896, 0),
                        (
                            "integral.x",
                            600,
                            600,
                            1251,
                            hb.OTMathGlyphPartFlags.EXTENDER,
                        ),
                        ("uni2320", 800, 0, 1630, 0),
                    ],
                    80,
                ),
            ),
            (
                "uni23DE",
                "LTR",
                (
                    [
                        ("uni23DE.l", 0, 300, 957, 0),
                        ("uni23B4.x", 600, 600, 751, hb.OTMathGlyphPartFlags.EXTENDER),
                        ("uni23DE.m", 300, 300, 943, 0),
                        ("uni23B4.x", 600, 600, 751, hb.OTMathGlyphPartFlags.EXTENDER),
                        ("uni23DE.r", 300, 0, 957, 0),
                    ],
                    0,
                ),
            ),
            ("uni0302", "TTB", ([], 0)),
        ],
    )
    def test_ot_math_get_glyph_assembly(self, mathfont, glyph, direction, expected):
        gid = mathfont.get_glyph_from_name(glyph)
        assembly, italics_correction = hb.ot_math_get_glyph_assembly(
            mathfont, gid, direction
        )
        result = [
            (
                mathfont.get_glyph_name(v.glyph),
                v.start_connector_length,
                v.end_connector_length,
                v.full_advance,
                v.flags,
            )
            for v in assembly
        ]
        assert (result, italics_correction) == expected


def test_harfbuzz_version():
    v = hb.version_string()
    assert isinstance(v, str)


def test_uharfbuzz_version():
    v = hb.__version__
    assert isinstance(v, str)
    assert "unknown" not in v


def test_create_sub_font():
    blob = hb.Blob.from_file_path(ADOBE_BLANK_TTF_PATH)
    face = hb.Face(blob)
    font = hb.Font(face)
    font2 = hb.Font(font)
    assert font is not font2
    assert font.face is font2.face


def test_harfbuzz_repacker():
    table_data = [
        bytes(b"\x00\x00\xff\xff\x00\x01\x00\x00"),
        bytes(b"\x00\x00\x00\x00"),
        bytes(b"\x00\x01latn\x00\x00"),
        bytes(b"\x00\x00\x00\x01\x00\x01"),
        bytes(b"\x00\x01test\x00\x00"),
        bytes(b"\x00\x01\x00\x01\x00\x02"),
        bytes(b"\x00\x01\x00\x00\x00\x01"),
        bytes(b"\x00\x01\x00\x00\x00\x01\x00\x00"),
        bytes(b"\x00\x01\x00\x01\x00\x01"),
        bytes(b"\x00\x02\x00\x01\x00\x02\x00\x01\x00\x00"),
        bytes(b"\x00\x01\x00\x00"),
        bytes(b"\x00\x01\x00\x00\x00\x01\x00\x00"),
        bytes(b"\x00\x05\x00\x00\x00\x01\x00\x00"),
        bytes(b"\x00\x02\x00\x00\x00\x00"),
        bytes(b"\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00"),
    ]
    obj_list = [
        ([], []),
        ([(0, 2, 1)], []),
        ([(6, 2, 2)], []),
        ([], []),
        ([(6, 2, 4)], []),
        ([], []),
        ([(2, 2, 6)], []),
        ([(6, 2, 7)], []),
        ([], []),
        ([], []),
        ([(2, 2, 10)], []),
        ([(2, 2, 9), (6, 2, 11)], []),
        ([(6, 2, 12)], []),
        ([(2, 2, 8), (4, 2, 13)], []),
        ([(4, 2, 3), (6, 2, 5), (8, 2, 14)], []),
    ]
    expected_data = bytes(
        b'\x00\x01\x00\x00\x00\x10\x00\x18\x00\n\x00\x02\x00\x1a\x00"\x00\x01latn\x00\x10\x00\x01test\x00\x1c\x00\x1a\x00\x00\x00\x01\x00\x00\x00\x01\x00\x1e\x00\x05\x00\x00\x00\x01\x00\x1c\x00\x00\x00\x01\x00\x01\x00\x00\xff\xff\x00\x01\x00\x00\x00\x01\x00\x0e\x00\x01\x00\x01\x00\x12\x00\x01\x00\x0e\x00\x01\x00\x01\x00\x02\x00\x01\x00\n\x00\x01\x00\x01\x00\x01\x00\x02\x00\x01\x00\x02\x00\x01\x00\x00'
    )
    packed_data = hb.repack(table_data, obj_list)
    assert expected_data == packed_data


@pytest.mark.skipif(sys.platform != "darwin", reason="requires macOS")
def test_sparsefont_coretext(sparsefont):
    buf = hb.Buffer()
    buf.add_str("ABC")
    buf.guess_segment_properties()
    with pytest.raises(RuntimeError):
        hb.shape(sparsefont, buf, shapers=["coretext"])


def test_set():
    s1 = hb.Set()
    s2 = hb.Set({1, 3, 4})
    s3 = hb.Set([1, 3, 4])

    assert s1 != None
    assert s1 != False
    assert not s1
    assert s2
    assert s1 != s2
    assert not s1 == s2
    assert not s2 != s3
    assert s2 == s3

    s1.add(1)
    s1.add_range(3, 4)
    assert s1 == s2

    assert -1 not in s1
    assert 1 in s1
    s1.remove(1)
    assert 1 not in s1

    assert list(s1) == [3, 4]

    s1 &= hb.Set({3, 4, 5})
    assert list(s1) == [3, 4]
    s1 -= hb.Set({3})
    assert list(s1) == [4]
    s1 ^= hb.Set({5})
    assert list(s1) == [4, 5]
    s1 |= {8}  # Update accepts set() as well

    assert list(s1) == [4, 5, 8]
    assert len(s1) == 3

    assert s1.min == 4
    assert s1.max == 8

    assert repr(s1) == "Set({4, 5, 8})"
    s1.invert()
    assert repr(s1) == "Set({...})"

    iter(iter(hb.Set({})))


def test_map():
    m1 = hb.Map()
    m2 = hb.Map({1: 2, 3: 4})
    m3 = hb.Map({1: 2, 3: 4})

    assert m1 != None
    assert m1 != False
    assert not m1
    assert m2
    assert m1 != m2
    assert not m1 == m2
    assert not m2 != m3
    assert m2 == m3
    m1[1] = 2
    assert m1[1] == 2
    assert m1 != m2
    m1[3] = 4
    assert m1 == m2

    assert -1 not in m2
    assert 1 in m1
    del m1[1]
    assert 1 not in m1
    assert len(m1) == 1

    assert set(m2.items()) == {(1, 2), (3, 4)}
    assert set(m2.keys()) == {1, 3}
    assert set(m2) == {1, 3}
    assert set(m2.values()) == {2, 4}

    m4 = hb.Map(m3)
    m5 = hb.Map()
    m5.update(m4)

    assert len(m4) == len(m5) == 2
    m5.update({10: 11})
    assert len(m5) == 3

    assert repr(m5) == "Map({1: 2, 3: 4, 10: 11})"

    iter(iter(hb.Map({})))


def test_subset(blankfont):
    for planned in (False, True):
        assert blankfont.get_nominal_glyph(ord("a")) == 1
        assert blankfont.get_nominal_glyph(ord("b")) == 2
        assert blankfont.get_nominal_glyph(ord("c")) == 3
        assert blankfont.get_nominal_glyph(ord("d")) == 4
        assert blankfont.get_nominal_glyph(ord("e")) == 5

        inp = hb.SubsetInput()
        inp.sets(hb.SubsetInputSets.UNICODE).set({ord("b")})
        s = inp.sets(hb.SubsetInputSets.LAYOUT_FEATURE_TAG)
        s.clear()
        s.invert()
        inp.layout_script_tag_set.invert()
        inp.unicode_set.update(ord(c) for c in "cd")
        inp.unicode_set.add(ord("e"))

        if not planned:
            face = hb.subset(blankfont.face, inp)
        else:
            plan = hb.SubsetPlan(blankfont.face, inp)
            face = plan.execute()

        assert face is not None
        font = hb.Font(face)

        assert font.get_nominal_glyph(ord("a")) is None
        assert font.get_nominal_glyph(ord("b")) == 1
        assert font.get_nominal_glyph(ord("c")) == 2
        assert font.get_nominal_glyph(ord("d")) == 3
        assert font.get_nominal_glyph(ord("e")) == 4

        blob = face.blob
        assert blob
        assert len(blob) > 100
        face = hb.Face(blob)
        font = hb.Font(face)

        assert font.get_nominal_glyph(ord("a")) is None
        assert font.get_nominal_glyph(ord("b")) == 1
        assert font.get_nominal_glyph(ord("c")) == 2
        assert font.get_nominal_glyph(ord("d")) == 3
        assert font.get_nominal_glyph(ord("e")) == 4

        if planned:
            mapping = plan.old_to_new_glyph_mapping
            reverse = plan.new_to_old_glyph_mapping
            assert 1 not in mapping
            assert mapping[2] == 1
            assert mapping[3] == 2
            assert reverse[mapping[2]] == 2
            assert reverse[mapping[3]] == 3
            assert len(reverse) == 5
            cmap = plan.unicode_to_old_glyph_mapping
            assert cmap[ord("b")] == 2
