class RasterFormat(IntEnum):
    """Pixel format for raster images.

    .. attribute:: A8

       8-bit alpha-only coverage.

    .. attribute:: BGRA32

       32-bit BGRA color.

    Wraps `hb_raster_format_t
    <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-format-t>`_.
    """
    A8 = HB_RASTER_FORMAT_A8
    BGRA32 = HB_RASTER_FORMAT_BGRA32


class RasterExtents(NamedTuple):
    """Pixel-buffer extents for raster operations.

    Wraps `hb_raster_extents_t
    <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-extents-t>`_.
    """
    x_origin: int = 0
    """X coordinate of the left edge of the image in glyph space."""
    y_origin: int = 0
    """Y coordinate of the bottom edge of the image in glyph space."""
    width: int = 0
    """Width in pixels."""
    height: int = 0
    """Height in pixels."""
    stride: int = 0
    """Bytes per row; 0 means auto-calculate on input, filled on output."""


cdef class RasterImage:
    """An opaque raster image object holding a pixel buffer produced by
    :meth:`RasterDraw.render`. Use :attr:`buffer` and :attr:`extents` to
    access the pixels.

    Wraps `hb_raster_image_t
    <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-image-t>`_.
    """

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
        """Configures this image's format and extents together, resizing
        backing storage at most once. This function does not clear pixel
        contents.

        Passing ``None`` for ``extents`` clears extents and releases the
        backing allocation.

        :returns: ``True`` if configuration succeeds, ``False`` on
            allocation failure.

        Wraps `hb_raster_image_configure()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-image-configure>`_.
        """
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
        """Clears this image's pixels to zero while keeping current extents
        and format.

        Wraps `hb_raster_image_clear()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-image-clear>`_.
        """
        hb_raster_image_clear(self._hb_raster_image)

    @property
    def format(self) -> RasterFormat:
        """Fetches the pixel format of this image.

        :type: RasterFormat

        Wraps `hb_raster_image_get_format()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-image-get-format>`_.
        """
        return RasterFormat(hb_raster_image_get_format(self._hb_raster_image))

    @property
    def extents(self) -> RasterExtents:
        """Fetches the pixel-buffer extents of this image.

        :type: RasterExtents

        Wraps `hb_raster_image_get_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-image-get-extents>`_.
        """
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
        """Fetches the raw pixel buffer of this image. The buffer layout is
        described by :attr:`extents` and :attr:`format`. Rows are stored
        bottom-to-top.

        :type: bytes

        Wraps `hb_raster_image_get_buffer()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-image-get-buffer>`_.
        """
        cdef hb_raster_extents_t c_extents
        hb_raster_image_get_extents(self._hb_raster_image, &c_extents)
        cdef const uint8_t* buf = hb_raster_image_get_buffer(self._hb_raster_image)
        if buf is NULL:
            return b""
        cdef Py_ssize_t size = c_extents.height * c_extents.stride
        return buf[:size]


cdef class RasterDraw:
    """An opaque outline rasterizer object. Accumulates glyph outlines via
    :class:`DrawFuncs` callbacks, then produces a :class:`RasterImage` with
    :meth:`render`.

    Wraps `hb_raster_draw_t
    <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-t>`_.
    """

    cdef hb_raster_draw_t* _hb_raster_draw

    def __cinit__(self):
        self._hb_raster_draw = hb_raster_draw_create_or_fail()
        if self._hb_raster_draw is NULL:
            raise MemoryError()

    def __dealloc__(self):
        hb_raster_draw_destroy(self._hb_raster_draw)

    @property
    def transform(self) -> Tuple[float, float, float, float, float, float]:
        """A 2×3 affine transform applied to all incoming draw coordinates
        before rasterization. The default is the identity.

        :type: tuple of (xx, yx, xy, yy, dx, dy)

        Wraps `hb_raster_draw_get_transform()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-get-transform>`_
        and `hb_raster_draw_set_transform()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-set-transform>`_.
        """
        cdef float xx, yx, xy, yy, dx, dy
        hb_raster_draw_get_transform(self._hb_raster_draw, &xx, &yx, &xy, &yy, &dx, &dy)
        return (xx, yx, xy, yy, dx, dy)

    @transform.setter
    def transform(self, value: Tuple[float, float, float, float, float, float]):
        xx, yx, xy, yy, dx, dy = value
        hb_raster_draw_set_transform(self._hb_raster_draw, xx, yx, xy, yy, dx, dy)

    @property
    def scale_factor(self) -> Tuple[float, float]:
        """Post-transform minification factors applied during rasterization.
        Factors larger than 1 shrink the output in pixels. The default is 1.

        :type: tuple of (x_scale_factor, y_scale_factor)

        Wraps `hb_raster_draw_get_scale_factor()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-get-scale-factor>`_
        and `hb_raster_draw_set_scale_factor()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-set-scale-factor>`_.
        """
        cdef float x, y
        hb_raster_draw_get_scale_factor(self._hb_raster_draw, &x, &y)
        return (x, y)

    @scale_factor.setter
    def scale_factor(self, value: Tuple[float, float]):
        x, y = value
        hb_raster_draw_set_scale_factor(self._hb_raster_draw, x, y)

    @property
    def extents(self) -> RasterExtents | None:
        """The output image extents. When set, :meth:`render` uses the given
        extents instead of auto-computing them from the accumulated
        geometry. ``None`` if no extents are configured.

        :type: RasterExtents | None

        Wraps `hb_raster_draw_get_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-get-extents>`_
        and `hb_raster_draw_set_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-set-extents>`_.
        """
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
        """Transforms ``extents`` with the rasterizer's current transform
        and sets the resulting pixel extents for the next render.

        This is equivalent to computing a transformed bounding box in pixel
        space and assigning it to :attr:`extents`.

        :returns: ``True`` if transformed extents are non-empty and set;
            ``False`` otherwise.

        Wraps `hb_raster_draw_set_glyph_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-set-glyph-extents>`_.
        """
        cdef hb_glyph_extents_t c_extents
        c_extents.x_bearing = extents.x_bearing
        c_extents.y_bearing = extents.y_bearing
        c_extents.width = extents.width
        c_extents.height = extents.height
        return hb_raster_draw_set_glyph_extents(self._hb_raster_draw, &c_extents)

    def draw_glyph(self, font: Font, glyph: int):
        """Draws one glyph into this rasterizer using the current transform.
        Equivalent to :meth:`draw_glyph_or_fail` with the return value
        ignored.

        Wraps `hb_raster_draw_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-glyph>`_.
        """
        hb_raster_draw_glyph(self._hb_raster_draw, font._hb_font, glyph)

    def draw_glyph_or_fail(self, font: Font, glyph: int) -> bool:
        """Convenience to draw one glyph.

        :returns: ``True`` if the glyph was drawn, ``False`` if the font has
            no outlines for ``glyph``.

        Wraps `hb_raster_draw_glyph_or_fail()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-glyph-or-fail>`_.
        """
        return hb_raster_draw_glyph_or_fail(self._hb_raster_draw, font._hb_font, glyph)

    def render(self) -> RasterImage | None:
        """Rasterizes the accumulated outline geometry into a new
        :class:`RasterImage`. After rendering, the accumulated edges are
        cleared so the rasterizer can be reused. Output format is always
        :attr:`RasterFormat.A8`.

        :returns: A rendered :class:`RasterImage`. Returns ``None`` on
            allocation/configuration failure. If no geometry was
            accumulated, returns an empty image.

        Wraps `hb_raster_draw_render()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-render>`_.
        """
        cdef hb_raster_image_t* img = hb_raster_draw_render(self._hb_raster_draw)
        if img is NULL:
            return None
        return RasterImage.from_ptr(img)

    def clear(self):
        """Discards accumulated geometry and extents so this rasterizer can
        be reused for another render. User configuration (transform, scale
        factors) is preserved. Call :meth:`reset` to also reset user
        configuration to defaults.

        Wraps `hb_raster_draw_clear()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-clear>`_.
        """
        hb_raster_draw_clear(self._hb_raster_draw)

    def reset(self):
        """Resets this rasterizer to its initial state, clearing all
        accumulated geometry, the transform, and fixed extents. The object
        can then be reused for a new glyph.

        Wraps `hb_raster_draw_reset()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-draw-reset>`_.
        """
        hb_raster_draw_reset(self._hb_raster_draw)


cdef class RasterPaint:
    """An opaque color-glyph paint context. Implements :class:`PaintFuncs`
    callbacks that render COLRv0/v1 color glyphs into a
    :attr:`RasterFormat.BGRA32` :class:`RasterImage`.

    Wraps `hb_raster_paint_t
    <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-t>`_.
    """

    cdef hb_raster_paint_t* _hb_raster_paint

    def __cinit__(self):
        self._hb_raster_paint = hb_raster_paint_create_or_fail()
        if self._hb_raster_paint is NULL:
            raise MemoryError()

    def __dealloc__(self):
        hb_raster_paint_destroy(self._hb_raster_paint)

    @property
    def transform(self) -> Tuple[float, float, float, float, float, float]:
        """The base 2×3 affine transform that maps from glyph-space
        coordinates to pixel-space coordinates.

        :type: tuple of (xx, yx, xy, yy, dx, dy)

        Wraps `hb_raster_paint_get_transform()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-get-transform>`_
        and `hb_raster_paint_set_transform()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-transform>`_.
        """
        cdef float xx, yx, xy, yy, dx, dy
        hb_raster_paint_get_transform(self._hb_raster_paint, &xx, &yx, &xy, &yy, &dx, &dy)
        return (xx, yx, xy, yy, dx, dy)

    @transform.setter
    def transform(self, value: Tuple[float, float, float, float, float, float]):
        xx, yx, xy, yy, dx, dy = value
        hb_raster_paint_set_transform(self._hb_raster_paint, xx, yx, xy, yy, dx, dy)

    @property
    def scale_factor(self) -> Tuple[float, float]:
        """Post-transform minification factors applied during painting.
        Factors larger than 1 shrink the output in pixels. The default is 1.

        :type: tuple of (x_scale_factor, y_scale_factor)

        Wraps `hb_raster_paint_get_scale_factor()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-get-scale-factor>`_
        and `hb_raster_paint_set_scale_factor()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-scale-factor>`_.
        """
        cdef float x, y
        hb_raster_paint_get_scale_factor(self._hb_raster_paint, &x, &y)
        return (x, y)

    @scale_factor.setter
    def scale_factor(self, value: Tuple[float, float]):
        x, y = value
        hb_raster_paint_set_scale_factor(self._hb_raster_paint, x, y)

    @property
    def extents(self) -> RasterExtents | None:
        """The output image extents (pixel rectangle). Must be set before
        painting; otherwise :meth:`render` returns ``None``. ``None`` if no
        extents are configured.

        :type: RasterExtents | None

        Wraps `hb_raster_paint_get_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-get-extents>`_
        and `hb_raster_paint_set_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-extents>`_.
        """
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
        """Transforms ``extents`` with the paint context's base transform
        and sets the resulting output image extents.

        This is equivalent to computing a transformed bounding box in pixel
        space and assigning it to :attr:`extents`.

        :returns: ``True`` if transformed extents are non-empty and set;
            ``False`` otherwise.

        Wraps `hb_raster_paint_set_glyph_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-glyph-extents>`_.
        """
        cdef hb_glyph_extents_t c_extents
        c_extents.x_bearing = extents.x_bearing
        c_extents.y_bearing = extents.y_bearing
        c_extents.width = extents.width
        c_extents.height = extents.height
        return hb_raster_paint_set_glyph_extents(self._hb_raster_paint, &c_extents)

    @property
    def foreground(self) -> Color:
        """The foreground color used when paint callbacks request it (e.g.
        ``is_foreground`` in color stops or solid fills). Defaults to
        opaque black if none was set.

        :type: Color

        Wraps `hb_raster_paint_get_foreground()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-get-foreground>`_
        and `hb_raster_paint_set_foreground()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-foreground>`_.
        """
        return Color.from_int(hb_raster_paint_get_foreground(self._hb_raster_paint))

    @foreground.setter
    def foreground(self, value: Color):
        hb_raster_paint_set_foreground(self._hb_raster_paint, value.to_int())

    @property
    def background(self) -> Color:
        """The background color. If set to a non-transparent value, the
        rendered image is pre-filled with this color before glyph content
        is composited on top. Default is transparent.

        :type: Color

        Wraps `hb_raster_paint_get_background()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-get-background>`_
        and `hb_raster_paint_set_background()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-background>`_.
        """
        return Color.from_int(hb_raster_paint_get_background(self._hb_raster_paint))

    @background.setter
    def background(self, value: Color):
        hb_raster_paint_set_background(self._hb_raster_paint, value.to_int())

    @property
    def palette(self) -> int:
        """Selects which font palette is used when paint callbacks look up
        indexed colors. Default is palette 0.

        :type: int

        Wraps `hb_raster_paint_get_palette()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-get-palette>`_
        and `hb_raster_paint_set_palette()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-palette>`_.
        """
        return hb_raster_paint_get_palette(self._hb_raster_paint)

    @palette.setter
    def palette(self, value: int):
        hb_raster_paint_set_palette(self._hb_raster_paint, value)

    def set_custom_palette_color(self, color_index: int, color: Color) -> bool:
        """Overrides one font palette color entry for subsequent paint
        operations. Overrides are keyed by ``color_index`` and persist on
        this paint context until cleared (or replaced for the same index).

        These overrides are consulted by paint operations that resolve
        ``CPAL`` entries.

        :returns: ``True`` if the override was set; ``False`` on allocation
            failure.

        Wraps `hb_raster_paint_set_custom_palette_color()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-set-custom-palette-color>`_.
        """
        return hb_raster_paint_set_custom_palette_color(
            self._hb_raster_paint, color_index, color.to_int())

    def clear_custom_palette_colors(self):
        """Clears all custom palette color overrides previously set on this
        paint context.

        After this call, palette lookups use the selected font palette
        without custom override entries.

        Wraps `hb_raster_paint_clear_custom_palette_colors()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-clear-custom-palette-colors>`_.
        """
        hb_raster_paint_clear_custom_palette_colors(self._hb_raster_paint)

    def paint_glyph(self, font: Font, glyph: int):
        """Paints one glyph into this paint context. Unlike
        :meth:`paint_glyph_or_fail`, glyphs with no color paint data fall
        back to a synthesized foreground-colored outline, so any glyph with
        an outline or bitmap image produces output.

        Wraps `hb_raster_paint_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-glyph>`_.
        """
        hb_raster_paint_glyph(self._hb_raster_paint, font._hb_font, glyph)

    def paint_glyph_or_fail(self, font: Font, glyph: int) -> bool:
        """Convenience to paint one color glyph.

        :returns: ``True`` if painting succeeded, ``False`` otherwise.

        Wraps `hb_raster_paint_glyph_or_fail()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-glyph-or-fail>`_.
        """
        return hb_raster_paint_glyph_or_fail(self._hb_raster_paint, font._hb_font, glyph)

    def render(self) -> RasterImage | None:
        """Extracts the rendered image after painting has completed. The
        paint context's surface stack is consumed and the result returned
        as a new :class:`RasterImage`. Output format is always
        :attr:`RasterFormat.BGRA32`.

        :attr:`extents` or :meth:`set_glyph_extents` must be called before
        painting; otherwise this function returns ``None``. Internal
        drawing state is cleared here so the same object can be reused
        without client-side clearing.

        :returns: A rendered :class:`RasterImage`. Returns ``None`` if
            extents were not set or if allocation/configuration fails. If
            extents were set but nothing was painted, returns an empty
            image.

        Wraps `hb_raster_paint_render()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-render>`_.
        """
        cdef hb_raster_image_t* img = hb_raster_paint_render(self._hb_raster_paint)
        if img is NULL:
            return None
        return RasterImage.from_ptr(img)

    def clear(self):
        """Discards accumulated paint output so this paint context can be
        reused for another render. User configuration (base transform,
        scale factors, foreground, custom palette colors) is preserved.
        Call :meth:`reset` to also reset user configuration to defaults.

        Wraps `hb_raster_paint_clear()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-clear>`_.
        """
        hb_raster_paint_clear(self._hb_raster_paint)

    def reset(self):
        """Resets this paint context to its initial state, clearing all
        configuration while preserving internal image caches.

        Wraps `hb_raster_paint_reset()
        <https://harfbuzz.github.io/harfbuzz-hb-raster.html#hb-raster-paint-reset>`_.
        """
        hb_raster_paint_reset(self._hb_raster_paint)
