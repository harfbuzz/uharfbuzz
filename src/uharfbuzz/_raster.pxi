class RasterFormat(IntEnum):
    A8 = HB_RASTER_FORMAT_A8
    BGRA32 = HB_RASTER_FORMAT_BGRA32


class RasterExtents(NamedTuple):
    x_origin: int = 0
    y_origin: int = 0
    width: int = 0
    height: int = 0
    stride: int = 0


cdef class RasterImage:
    cdef hb_raster_image_t* _hb_raster_image

    def __cinit__(self):
        self._hb_raster_image = NULL

    def __init__(self):
        self._hb_raster_image = hb_raster_image_create_or_fail()
        if self._hb_raster_image is NULL:
            raise MemoryError()

    def __dealloc__(self):
        hb_raster_image_destroy(self._hb_raster_image)

    @staticmethod
    cdef RasterImage from_ptr(hb_raster_image_t* hb_img):
        """Create RasterImage from a pointer, taking ownership of it."""
        cdef RasterImage wrapper = RasterImage.__new__(RasterImage)
        wrapper._hb_raster_image = hb_img
        return wrapper

    def configure(self, format: RasterFormat,
                  extents: RasterExtents | None = None) -> bool:
        cdef hb_raster_extents_t c_extents
        cdef hb_raster_extents_t* c_extents_ptr = NULL
        if extents is not None:
            c_extents.x_origin = extents.x_origin
            c_extents.y_origin = extents.y_origin
            c_extents.width = extents.width
            c_extents.height = extents.height
            c_extents.stride = extents.stride
            c_extents_ptr = &c_extents
        return hb_raster_image_configure(self._hb_raster_image, format, c_extents_ptr)

    def clear(self):
        hb_raster_image_clear(self._hb_raster_image)

    @property
    def format(self) -> RasterFormat:
        return RasterFormat(hb_raster_image_get_format(self._hb_raster_image))

    @property
    def extents(self) -> RasterExtents:
        cdef hb_raster_extents_t c_extents
        hb_raster_image_get_extents(self._hb_raster_image, &c_extents)
        return RasterExtents(
            x_origin=c_extents.x_origin,
            y_origin=c_extents.y_origin,
            width=c_extents.width,
            height=c_extents.height,
            stride=c_extents.stride,
        )

    @property
    def buffer(self) -> bytes:
        cdef hb_raster_extents_t c_extents
        hb_raster_image_get_extents(self._hb_raster_image, &c_extents)
        cdef const uint8_t* buf = hb_raster_image_get_buffer(self._hb_raster_image)
        if buf is NULL:
            return b""
        cdef Py_ssize_t size = c_extents.height * c_extents.stride
        return buf[:size]


cdef class RasterDraw:
    cdef hb_raster_draw_t* _hb_raster_draw

    def __cinit__(self):
        self._hb_raster_draw = hb_raster_draw_create_or_fail()
        if self._hb_raster_draw is NULL:
            raise MemoryError()

    def __dealloc__(self):
        hb_raster_draw_destroy(self._hb_raster_draw)

    @property
    def transform(self) -> Tuple[float, float, float, float, float, float]:
        cdef float xx, yx, xy, yy, dx, dy
        hb_raster_draw_get_transform(self._hb_raster_draw, &xx, &yx, &xy, &yy, &dx, &dy)
        return (xx, yx, xy, yy, dx, dy)

    @transform.setter
    def transform(self, value: Tuple[float, float, float, float, float, float]):
        xx, yx, xy, yy, dx, dy = value
        hb_raster_draw_set_transform(self._hb_raster_draw, xx, yx, xy, yy, dx, dy)

    @property
    def scale_factor(self) -> Tuple[float, float]:
        cdef float x, y
        hb_raster_draw_get_scale_factor(self._hb_raster_draw, &x, &y)
        return (x, y)

    @scale_factor.setter
    def scale_factor(self, value: Tuple[float, float]):
        x, y = value
        hb_raster_draw_set_scale_factor(self._hb_raster_draw, x, y)

    @property
    def extents(self) -> RasterExtents | None:
        cdef hb_raster_extents_t c_extents
        if not hb_raster_draw_get_extents(self._hb_raster_draw, &c_extents):
            return None
        return RasterExtents(
            x_origin=c_extents.x_origin,
            y_origin=c_extents.y_origin,
            width=c_extents.width,
            height=c_extents.height,
            stride=c_extents.stride,
        )

    @extents.setter
    def extents(self, value: RasterExtents):
        cdef hb_raster_extents_t c_extents
        c_extents.x_origin = value.x_origin
        c_extents.y_origin = value.y_origin
        c_extents.width = value.width
        c_extents.height = value.height
        c_extents.stride = value.stride
        hb_raster_draw_set_extents(self._hb_raster_draw, &c_extents)

    def set_glyph_extents(self, extents: GlyphExtents) -> bool:
        cdef hb_glyph_extents_t c_extents
        c_extents.x_bearing = extents.x_bearing
        c_extents.y_bearing = extents.y_bearing
        c_extents.width = extents.width
        c_extents.height = extents.height
        return hb_raster_draw_set_glyph_extents(self._hb_raster_draw, &c_extents)

    def draw_glyph(self, font: Font, glyph: int):
        hb_raster_draw_glyph(self._hb_raster_draw, font._hb_font, glyph)

    def draw_glyph_or_fail(self, font: Font, glyph: int) -> bool:
        return hb_raster_draw_glyph_or_fail(self._hb_raster_draw, font._hb_font, glyph)

    def render(self) -> RasterImage | None:
        cdef hb_raster_image_t* img = hb_raster_draw_render(self._hb_raster_draw)
        if img is NULL:
            return None
        return RasterImage.from_ptr(img)

    def clear(self):
        hb_raster_draw_clear(self._hb_raster_draw)

    def reset(self):
        hb_raster_draw_reset(self._hb_raster_draw)


cdef class RasterPaint:
    cdef hb_raster_paint_t* _hb_raster_paint

    def __cinit__(self):
        self._hb_raster_paint = hb_raster_paint_create_or_fail()
        if self._hb_raster_paint is NULL:
            raise MemoryError()

    def __dealloc__(self):
        hb_raster_paint_destroy(self._hb_raster_paint)

    @property
    def transform(self) -> Tuple[float, float, float, float, float, float]:
        cdef float xx, yx, xy, yy, dx, dy
        hb_raster_paint_get_transform(self._hb_raster_paint, &xx, &yx, &xy, &yy, &dx, &dy)
        return (xx, yx, xy, yy, dx, dy)

    @transform.setter
    def transform(self, value: Tuple[float, float, float, float, float, float]):
        xx, yx, xy, yy, dx, dy = value
        hb_raster_paint_set_transform(self._hb_raster_paint, xx, yx, xy, yy, dx, dy)

    @property
    def scale_factor(self) -> Tuple[float, float]:
        cdef float x, y
        hb_raster_paint_get_scale_factor(self._hb_raster_paint, &x, &y)
        return (x, y)

    @scale_factor.setter
    def scale_factor(self, value: Tuple[float, float]):
        x, y = value
        hb_raster_paint_set_scale_factor(self._hb_raster_paint, x, y)

    @property
    def extents(self) -> RasterExtents | None:
        cdef hb_raster_extents_t c_extents
        if not hb_raster_paint_get_extents(self._hb_raster_paint, &c_extents):
            return None
        return RasterExtents(
            x_origin=c_extents.x_origin,
            y_origin=c_extents.y_origin,
            width=c_extents.width,
            height=c_extents.height,
            stride=c_extents.stride,
        )

    @extents.setter
    def extents(self, value: RasterExtents):
        cdef hb_raster_extents_t c_extents
        c_extents.x_origin = value.x_origin
        c_extents.y_origin = value.y_origin
        c_extents.width = value.width
        c_extents.height = value.height
        c_extents.stride = value.stride
        hb_raster_paint_set_extents(self._hb_raster_paint, &c_extents)

    def set_glyph_extents(self, extents: GlyphExtents) -> bool:
        cdef hb_glyph_extents_t c_extents
        c_extents.x_bearing = extents.x_bearing
        c_extents.y_bearing = extents.y_bearing
        c_extents.width = extents.width
        c_extents.height = extents.height
        return hb_raster_paint_set_glyph_extents(self._hb_raster_paint, &c_extents)

    @property
    def foreground(self) -> Color:
        return Color.from_int(hb_raster_paint_get_foreground(self._hb_raster_paint))

    @foreground.setter
    def foreground(self, value: Color):
        hb_raster_paint_set_foreground(self._hb_raster_paint, value.to_int())

    @property
    def background(self) -> Color:
        return Color.from_int(hb_raster_paint_get_background(self._hb_raster_paint))

    @background.setter
    def background(self, value: Color):
        hb_raster_paint_set_background(self._hb_raster_paint, value.to_int())

    @property
    def palette(self) -> int:
        return hb_raster_paint_get_palette(self._hb_raster_paint)

    @palette.setter
    def palette(self, value: int):
        hb_raster_paint_set_palette(self._hb_raster_paint, value)

    def set_custom_palette_color(self, color_index: int, color: Color) -> bool:
        return hb_raster_paint_set_custom_palette_color(
            self._hb_raster_paint, color_index, color.to_int())

    def clear_custom_palette_colors(self):
        hb_raster_paint_clear_custom_palette_colors(self._hb_raster_paint)

    def paint_glyph(self, font: Font, glyph: int):
        hb_raster_paint_glyph(self._hb_raster_paint, font._hb_font, glyph)

    def paint_glyph_or_fail(self, font: Font, glyph: int) -> bool:
        return hb_raster_paint_glyph_or_fail(self._hb_raster_paint, font._hb_font, glyph)

    def render(self) -> RasterImage | None:
        cdef hb_raster_image_t* img = hb_raster_paint_render(self._hb_raster_paint)
        if img is NULL:
            return None
        return RasterImage.from_ptr(img)

    def clear(self):
        hb_raster_paint_clear(self._hb_raster_paint)

    def reset(self):
        hb_raster_paint_reset(self._hb_raster_paint)
