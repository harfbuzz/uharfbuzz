import uharfbuzz as hb
from pathlib import Path
import sys
import pytest


TESTDATA = Path(__file__).parent / "data"
ADOBE_BLANK_TTF_PATH = TESTDATA / "AdobeBlank.subset.ttf"
OPEN_SANS_TTF_PATH = TESTDATA / "OpenSans.subset.ttf"
MUTATOR_SANS_TTF_PATH = TESTDATA / "MutatorSans-VF.subset.ttf"
SPARSE_FONT_TTF_PATH = TESTDATA / "SparseFont.ttf"


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
        extents = blankfont.get_font_extents('ltr')
        assert (880, -120, 0) == extents
        assert 880 == extents.ascender
        assert -120 == extents.descender
        assert 0 == extents.line_gap
        extents = blankfont.get_font_extents('ttb')
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
        expected = [(0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0)]
        assert pos == expected

    @pytest.mark.skipif(sys.platform != "win32", reason="requires Windows")
    def test_shape_set_shaper_directwrite(self, blankfont):
        string = "abcde"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, shapers=["directwrite"])
        pos = [g.position for g in buf.glyph_positions]
        expected = [(0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0)]
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
        expected = [(0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0)]
        assert pos == expected

    @pytest.mark.skipif(sys.platform != "darwin", reason="requires macOS")
    def test_shape_set_shaper_coretext(self, blankfont):
        string = "abcde"
        buf = hb.Buffer()
        buf.add_str(string)
        buf.guess_segment_properties()
        hb.shape(blankfont, buf, shapers=["coretext"])
        pos = [g.position for g in buf.glyph_positions]
        expected = [(0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0)]
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
        assert blankfont.glyph_to_string(1000) == 'gid1000'

    @pytest.mark.parametrize(
        "string, features, expected",
        [
            # The calt feature replaces c by a in the context e, d, c', b, a.
            ("edcbaedcba", {}, ["e", "d", "a", "b", "a", "e", "d", "a", "b", "a"]),
            ("edcbaedcba", {"calt[2]": False}, ["e", "d", "c", "b", "a", "e", "d", "a", "b", "a"]),
            ("edcbaedcba", {"calt": [(7, 8, False)]}, ["e", "d", "a", "b", "a", "e", "d", "c", "b", "a"]),
            ("edcbaedcba", {"calt": [(0, 10, False), (7, 8, True)]}, ["e", "d", "c", "b", "a", "e", "d", "a", "b", "a"]),
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

    def test_font_extents_funcs(self, blankfont):
        def font_h_extents_func(font, data):
            return hb.FontExtents(123, -456, 789)

        def font_v_extents_func(font, data):
            return hb.FontExtents(987, -654, 321)

        funcs = hb.FontFuncs.create()
        funcs.set_font_h_extents_func(font_h_extents_func, None)
        funcs.set_font_v_extents_func(font_v_extents_func, None)
        blankfont.funcs = funcs
        assert (123, -456, 789) == blankfont.get_font_extents('ltr')
        assert (987, -654, 321) == blankfont.get_font_extents('ttb')

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
            'start table GSUB',
            'start lookup 0',
            'end lookup 0',
            'end table GSUB',
            'start table GPOS',
            'start lookup 0',
            'end lookup 0',
            'end table GPOS',
        ]
        assert messages == expected_messages
        gids_trace = [[g.codepoint for g in infos] for infos in infos_trace]
        assert gids_trace == [[5, 4, 3, 2, 1], [5, 4, 3, 2, 1], [5, 4, 1, 2, 1],
                              [5, 4, 1, 2, 1], [5, 4, 1, 2, 1], [5, 4, 1, 2, 1],
                              [5, 4, 1, 2, 1], [5, 4, 1, 2, 1]]
        advances_trace = [[g.x_advance for g in pos] for pos in positions_trace if pos]
        assert advances_trace == [[0, 0, 0, 0, 0], [0, 0, 0, 0, 0],
                                  [0, 0, 0, 100, 0], [0, 0, 0, 100, 0]]

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
            'start table GSUB',
            'start table GPOS',
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
        def move_to(x,y,c):
            c.append(f"M{x:g},{y:g}")
        def line_to(x,y,c):
            c.append(f"L{x:g},{y:g}")
        def cubic_to(c1x,c1y,c2x,c2y,x,y,c):
            c.append(f"C{c1x:g},{c1y:g} {c2x:g},{c2y:g} {x:g},{y:g}")
        def quadratic_to(c1x,c1y,x,y,c):
            c.append(f"Q{c1x:g},{c1y:g} {x:g},{y:g}")
        def close_path(c):
            c.append("Z")

        funcs.set_move_to_func(move_to, container)
        funcs.set_line_to_func(line_to, container)
        funcs.set_cubic_to_func(cubic_to, container)
        funcs.set_quadratic_to_func(quadratic_to, container)
        funcs.set_close_path_func(close_path, container)
        funcs.get_glyph_shape(opensans, 1)
        assert "".join(container) == "M1120,0L938,465L352,465L172,0L0,0L578,1468L721,1468L1296,0L1120,0ZM885,618L715,1071Q682,1157 647,1282Q625,1186 584,1071L412,618L885,618Z"

    def test_draw_funcs_deprecated(self, opensans):
        funcs = hb.DrawFuncs()
        container = []
        def move_to(x,y,c):
            c.append(f"M{x:g},{y:g}")
        def line_to(x,y,c):
            c.append(f"L{x:g},{y:g}")
        def cubic_to(c1x,c1y,c2x,c2y,x,y,c):
            c.append(f"C{c1x:g},{c1y:g} {c2x:g},{c2y:g} {x:g},{y:g}")
        def quadratic_to(c1x,c1y,x,y,c):
            c.append(f"Q{c1x:g},{c1y:g} {x:g},{y:g}")
        def close_path(c):
            c.append("Z")

        funcs.set_move_to_func(move_to)
        funcs.set_line_to_func(line_to)
        funcs.set_cubic_to_func(cubic_to)
        funcs.set_quadratic_to_func(quadratic_to)
        funcs.set_close_path_func(close_path)
        with pytest.warns(DeprecationWarning):
            funcs.draw_glyph(opensans, 1, container)
        assert "".join(container) == "M1120,0L938,465L352,465L172,0L0,0L578,1468L721,1468L1296,0L1120,0ZM885,618L715,1071Q682,1157 647,1282Q625,1186 584,1071L412,618L885,618Z"

    def test_draw_pen(self, opensans):
        class TestPen:
            def __init__(self):
                self.value = []
            def moveTo(self, p0):
                self.value.append(('moveTo', (p0,)))
            def lineTo(self, p1):
                self.value.append(('lineTo', (p1,)))
            def qCurveTo(self, *points):
                self.value.append(('qCurveTo', points))
            def curveTo(self, *points):
                self.value.append(('curveTo', points))
            def closePath(self):
                self.value.append(('closePath', ()))
        pen = TestPen()
        opensans.draw_glyph_with_pen(1, pen)
        assert pen.value == [('moveTo', ((1120, 0),)), ('lineTo', ((938, 465),)), ('lineTo', ((352, 465),)), ('lineTo', ((172, 0),)), ('lineTo', ((0, 0),)), ('lineTo', ((578, 1468),)), ('lineTo', ((721, 1468),)), ('lineTo', ((1296, 0),)), ('lineTo', ((1120, 0),)), ('closePath', ()), ('moveTo', ((885, 618),)), ('lineTo', ((715, 1071),)), ('qCurveTo', ((682, 1157), (647, 1282))), ('qCurveTo', ((625, 1186), (584, 1071))), ('lineTo', ((412, 618),)), ('lineTo', ((885, 618),)), ('closePath', ())]


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


def test_harfbuzz_version():
    v = hb.version_string()
    assert isinstance(v, str)


def test_uharfbuzz_version():
    v = hb.__version__
    assert isinstance(v, str)
    assert "unknown" not in v

def test_harfbuzz_repacker():
    table_data = [
                   bytes(b'\x00\x00\xff\xff\x00\x01\x00\x00'),
                   bytes(b'\x00\x00\x00\x00'),
                   bytes(b'\x00\x01latn\x00\x00'),
                   bytes(b'\x00\x00\x00\x01\x00\x01'),
                   bytes(b'\x00\x01test\x00\x00'),
                   bytes(b'\x00\x01\x00\x01\x00\x02'),
                   bytes(b'\x00\x01\x00\x00\x00\x01'),
                   bytes(b'\x00\x01\x00\x00\x00\x01\x00\x00'),
                   bytes(b'\x00\x01\x00\x01\x00\x01'),
                   bytes(b'\x00\x02\x00\x01\x00\x02\x00\x01\x00\x00'),
                   bytes(b'\x00\x01\x00\x00'),
                   bytes(b'\x00\x01\x00\x00\x00\x01\x00\x00'),
                   bytes(b'\x00\x05\x00\x00\x00\x01\x00\x00'),
                   bytes(b'\x00\x02\x00\x00\x00\x00'),
                   bytes(b'\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00'),
                 ]
    obj_list = [
                 ([], []),
                 ([(0,2,1)], []),
                 ([(6,2,2)], []),
                 ([], []),
                 ([(6,2,4)], []),
                 ([], []),
                 ([(2,2,6)], []),
                 ([(6,2,7)], []),
                 ([], []),
                 ([], []),
                 ([(2,2,10)], []),
                 ([(2,2,9), (6,2,11)], []),
                 ([(6,2,12)], []),
                 ([(2,2,8), (4,2,13)], []),
                 ([(4,2,3), (6,2,5), (8,2,14)], []),
               ]
    expected_data = bytes(b'\x00\x01\x00\x00\x00\n\x00\x12\x00\x1a\x00\x01latn\x00\x16\x00\x01test\x00\x12\x00\x02\x00\x10\x00\x18\x00\x1a\x00\x00\x00\x00\x00\x01\x00\x01\x00\x01\x00\x00\x00\x01\x00\x18\x00\x05\x00\x00\x00\x01\x00\x16\x00\x00\xff\xff\x00\x01\x00\x00\x00\x01\x00\x0e\x00\x01\x00\x01\x00\x0e\x00\x01\x00\x14\x00\x01\x00\x01\x00\x02\x00\x01\x00\x01\x00\x01\x00\x01\x00\x04\x00\x02\x00\x01\x00\x02\x00\x01\x00\x00')
    packed_data = hb.repack(table_data, obj_list)
    assert expected_data == packed_data

@pytest.mark.skipif(sys.platform != "darwin", reason="requires macOS")
def test_sparsefont_coretext(sparsefont):
    buf = hb.Buffer()
    buf.add_str("ABC")
    buf.guess_segment_properties()
    with pytest.raises(RuntimeError):
        hb.shape(sparsefont, buf, shapers=["coretext"])
