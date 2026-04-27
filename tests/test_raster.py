from pathlib import Path

import pytest

import uharfbuzz as hb


TESTDATA = Path(__file__).parent / "data"
OPENSANS_TTF = TESTDATA / "OpenSans.subset.ttf"
COLORV1_TTF = TESTDATA / "test_glyphs-glyf_colr_1.ttf"


@pytest.fixture
def font():
    blob = hb.Blob(OPENSANS_TTF.read_bytes())
    return hb.Font(hb.Face(blob))


@pytest.fixture
def colorv1font():
    blob = hb.Blob(COLORV1_TTF.read_bytes())
    return hb.Font(hb.Face(blob))


class TestRasterImage:
    def test_configure(self):
        img = hb.RasterImage()
        ok = img.configure(
            hb.RasterFormat.A8,
            hb.RasterExtents(width=16, height=16),
        )
        assert ok
        assert img.format is hb.RasterFormat.A8
        assert img.extents.width == 16
        assert img.extents.height == 16
        assert img.extents.stride >= 16
        assert len(img.buffer) == img.extents.height * img.extents.stride


class TestRasterDraw:
    def test_render_a8(self, font):
        gid = 1
        draw = hb.RasterDraw()
        draw.scale_factor = (1.0, 1.0)
        assert draw.set_glyph_extents(font.get_glyph_extents(gid))
        draw.draw_glyph(font, gid)
        image = draw.render()
        assert image.format is hb.RasterFormat.A8
        assert image.extents.width > 0
        assert image.extents.height > 0
        assert len(image.buffer) == image.extents.height * image.extents.stride
        assert any(b != 0 for b in image.buffer)

    def test_transform_roundtrip(self):
        draw = hb.RasterDraw()
        draw.transform = (2.0, 0.0, 0.0, 2.0, 10.0, 20.0)
        assert draw.transform == (2.0, 0.0, 0.0, 2.0, 10.0, 20.0)

    def test_scale_factor_roundtrip(self):
        draw = hb.RasterDraw()
        draw.scale_factor = (1.5, 2.5)
        assert draw.scale_factor == (1.5, 2.5)

    def test_extents_roundtrip(self):
        draw = hb.RasterDraw()
        assert draw.extents is None
        draw.extents = hb.RasterExtents(0, 0, 32, 32, 0)
        assert draw.extents is not None
        assert draw.extents.width == 32
        assert draw.extents.height == 32

    def test_clear_and_reset(self, font):
        gid = 1
        draw = hb.RasterDraw()
        draw.scale_factor = (1.0, 1.0)
        draw.set_glyph_extents(font.get_glyph_extents(gid))
        draw.draw_glyph(font, gid)
        draw.clear()
        draw.reset()
        image = draw.render()
        assert isinstance(image, hb.RasterImage)


class TestRasterPaint:
    def test_render_bgra32(self, colorv1font):
        gid = 10
        paint = hb.RasterPaint()
        paint.scale_factor = (1.0, 1.0)
        paint.set_glyph_extents(colorv1font.get_glyph_extents(gid))
        paint.paint_glyph(colorv1font, gid)
        image = paint.render()
        assert image.format is hb.RasterFormat.BGRA32
        assert image.extents.width > 0
        assert image.extents.height > 0
        assert len(image.buffer) == image.extents.height * image.extents.stride

    def test_foreground_roundtrip(self):
        paint = hb.RasterPaint()
        paint.foreground = hb.Color(red=10, green=20, blue=30, alpha=40)
        color = paint.foreground
        assert (color.red, color.green, color.blue, color.alpha) == (10, 20, 30, 40)

    def test_background_roundtrip(self):
        paint = hb.RasterPaint()
        paint.background = hb.Color(red=0, green=0, blue=0, alpha=255)
        color = paint.background
        assert color.alpha == 255

    def test_palette_roundtrip(self):
        paint = hb.RasterPaint()
        paint.palette = 2
        assert paint.palette == 2

    def test_custom_palette_color(self):
        paint = hb.RasterPaint()
        assert paint.set_custom_palette_color(0, hb.Color(255, 0, 0, 255))
        paint.clear_custom_palette_colors()
