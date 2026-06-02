class PaintCompositeMode(IntEnum):
    """The values of this enumeration describe the compositing modes that can
    be used when combining temporary redirected drawing with the backdrop.

    See the OpenType spec `COLR
    <https://learn.microsoft.com/en-us/typography/opentype/spec/colr>`_
    section for details.

    .. attribute:: CLEAR

       Clear destination layer (bounded).

    .. attribute:: SRC

       Replace destination layer (bounded).

    .. attribute:: DEST

       Ignore the source.

    .. attribute:: SRC_OVER

       Draw source layer on top of destination layer (bounded).

    .. attribute:: DEST_OVER

       Draw destination on top of source.

    .. attribute:: SRC_IN

       Draw source where there was destination content (unbounded).

    .. attribute:: DEST_IN

       Leave destination only where there was source content (unbounded).

    .. attribute:: SRC_OUT

       Draw source where there was no destination content (unbounded).

    .. attribute:: DEST_OUT

       Leave destination only where there was no source content.

    .. attribute:: SRC_ATOP

       Draw source on top of destination content and only there.

    .. attribute:: DEST_ATOP

       Leave destination on top of source content and only there (unbounded).

    .. attribute:: XOR

       Source and destination are shown where there is only one of them.

    .. attribute:: PLUS

       Source and destination layers are accumulated.

    .. attribute:: SCREEN

       Source and destination are complemented and multiplied. This causes
       the result to be at least as light as the lighter inputs.

    .. attribute:: OVERLAY

       Multiplies or screens, depending on the lightness of the destination
       color.

    .. attribute:: DARKEN

       Replaces the destination with the source if it is darker, otherwise
       keeps the source.

    .. attribute:: LIGHTEN

       Replaces the destination with the source if it is lighter, otherwise
       keeps the source.

    .. attribute:: COLOR_DODGE

       Brightens the destination color to reflect the source color.

    .. attribute:: COLOR_BURN

       Darkens the destination color to reflect the source color.

    .. attribute:: HARD_LIGHT

       Multiplies or screens, dependent on source color.

    .. attribute:: SOFT_LIGHT

       Darkens or lightens, dependent on source color.

    .. attribute:: DIFFERENCE

       Takes the difference of the source and destination color.

    .. attribute:: EXCLUSION

       Produces an effect similar to difference, but with lower contrast.

    .. attribute:: MULTIPLY

       Source and destination layers are multiplied. This causes the result
       to be at least as dark as the darker inputs.

    .. attribute:: HSL_HUE

       Creates a color with the hue of the source and the saturation and
       luminosity of the target.

    .. attribute:: HSL_SATURATION

       Creates a color with the saturation of the source and the hue and
       luminosity of the target. Painting with this mode onto a gray area
       produces no change.

    .. attribute:: HSL_COLOR

       Creates a color with the hue and saturation of the source and the
       luminosity of the target. This preserves the gray levels of the
       target and is useful for coloring monochrome images or tinting color
       images.

    .. attribute:: HSL_LUMINOSITY

       Creates a color with the luminosity of the source and the hue and
       saturation of the target. This produces an inverse effect to
       :attr:`HSL_COLOR`.

    Wraps `hb_paint_composite_mode_t
    <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-composite-mode-t>`_.
    """
    CLEAR = HB_PAINT_COMPOSITE_MODE_CLEAR
    SRC = HB_PAINT_COMPOSITE_MODE_SRC
    DEST = HB_PAINT_COMPOSITE_MODE_DEST
    SRC_OVER = HB_PAINT_COMPOSITE_MODE_SRC_OVER
    DEST_OVER = HB_PAINT_COMPOSITE_MODE_DEST_OVER
    SRC_IN = HB_PAINT_COMPOSITE_MODE_SRC_IN
    DEST_IN = HB_PAINT_COMPOSITE_MODE_DEST_IN
    SRC_OUT = HB_PAINT_COMPOSITE_MODE_SRC_OUT
    DEST_OUT = HB_PAINT_COMPOSITE_MODE_DEST_OUT
    SRC_ATOP = HB_PAINT_COMPOSITE_MODE_SRC_ATOP
    DEST_ATOP = HB_PAINT_COMPOSITE_MODE_DEST_ATOP
    XOR = HB_PAINT_COMPOSITE_MODE_XOR
    PLUS = HB_PAINT_COMPOSITE_MODE_PLUS
    SCREEN = HB_PAINT_COMPOSITE_MODE_SCREEN
    OVERLAY = HB_PAINT_COMPOSITE_MODE_OVERLAY
    DARKEN = HB_PAINT_COMPOSITE_MODE_DARKEN
    LIGHTEN = HB_PAINT_COMPOSITE_MODE_LIGHTEN
    COLOR_DODGE = HB_PAINT_COMPOSITE_MODE_COLOR_DODGE
    COLOR_BURN = HB_PAINT_COMPOSITE_MODE_COLOR_BURN
    HARD_LIGHT = HB_PAINT_COMPOSITE_MODE_HARD_LIGHT
    SOFT_LIGHT = HB_PAINT_COMPOSITE_MODE_SOFT_LIGHT
    DIFFERENCE = HB_PAINT_COMPOSITE_MODE_DIFFERENCE
    EXCLUSION = HB_PAINT_COMPOSITE_MODE_EXCLUSION
    MULTIPLY = HB_PAINT_COMPOSITE_MODE_MULTIPLY
    HSL_HUE = HB_PAINT_COMPOSITE_MODE_HSL_HUE
    HSL_SATURATION = HB_PAINT_COMPOSITE_MODE_HSL_SATURATION
    HSL_COLOR = HB_PAINT_COMPOSITE_MODE_HSL_COLOR
    HSL_LUMINOSITY = HB_PAINT_COMPOSITE_MODE_HSL_LUMINOSITY


class ColorStop(NamedTuple):
    """Information about a color stop on a color line.

    Color lines typically have offsets ranging between 0 and 1, but that is
    not required.

    The ``is_foreground`` and ``color`` fields have the same semantics as in
    the color callback set by
    :meth:`PaintFuncs.set_color_func`.

    Note: despite ``color`` being unpremultiplied here, interpolation in
    gradients shall happen in premultiplied space. See the OpenType spec
    `COLR
    <https://learn.microsoft.com/en-us/typography/opentype/spec/colr>`_
    section for details.

    Wraps `hb_color_stop_t
    <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-color-stop-t>`_.
    """
    offset: float
    """The offset of the color stop."""
    is_foreground: bool
    """Whether the color is the foreground."""
    color: Color
    """The color, unpremultiplied."""


class PaintExtend(IntEnum):
    """The values of this enumeration determine how color values outside the
    minimum and maximum defined offset on a :class:`ColorLine` are
    determined.

    See the OpenType spec `COLR
    <https://learn.microsoft.com/en-us/typography/opentype/spec/colr>`_
    section for details.

    .. attribute:: PAD

       Outside the defined interval, the color of the closest color stop is
       used.

    .. attribute:: REPEAT

       The color line is repeated over repeated multiples of the defined
       interval.

    .. attribute:: REFLECT

       The color line is repeated over repeated intervals, as for the repeat
       mode. However, in each repeated interval, the ordering of color stops
       is the reverse of the adjacent interval.

    Wraps `hb_paint_extend_t
    <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-extend-t>`_.
    """
    PAD = HB_PAINT_EXTEND_PAD
    REPEAT = HB_PAINT_EXTEND_REPEAT
    REFLECT = HB_PAINT_EXTEND_REFLECT


cdef class ColorLine:
    """A struct containing color information for a gradient.

    Wraps `hb_color_line_t
    <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-color-line-t>`_.
    """

    cdef hb_color_line_t* _color_line

    def __cinit__(self):
        self._color_line = NULL

    @staticmethod
    cdef ColorLine from_ptr(hb_color_line_t* color_line):
        cdef ColorLine wrapper = ColorLine()
        wrapper._color_line = color_line
        return wrapper


    @property
    def color_stops(self) -> Sequence[ColorStop]:
        """Fetches a list of color stops from this color line.

        Note that due to variations being applied, the returned color stops
        may be out of order. It is the caller's responsibility to ensure
        that color stops are sorted by their offset before they are used.

        :type: Sequence[ColorStop]

        Wraps `hb_color_line_get_color_stops()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-color-line-get-color-stops>`_.
        """
        if self._color_line is NULL:
            return []
        cdef unsigned int stop_count = STATIC_ARRAY_SIZE
        cdef hb_color_stop_t stops_array[STATIC_ARRAY_SIZE]
        cdef list stops = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while stop_count == STATIC_ARRAY_SIZE:
            hb_color_line_get_color_stops(
                self._color_line, start_offset, &stop_count, stops_array)
            for i in range(stop_count):
                c_stop = stops_array[i]
                py_color = Color.from_int(c_stop.color)
                stop = ColorStop(c_stop.offset, <bint>c_stop.is_foreground, py_color)
                stops.append(stop)
            start_offset += stop_count
        return stops

    @property
    def extend(self) -> PaintExtend:
        """Fetches the extend mode of this color line.

        :type: PaintExtend

        Wraps `hb_color_line_get_extend()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-color-line-get-extend>`_.
        """
        if self._color_line is NULL:
            return None
        return PaintExtend(hb_color_line_get_extend(self._color_line))


cdef void _paint_push_transform_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        float xx,
        float yx,
        float xy,
        float yy,
        float dx,
        float dy,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_funcs._push_transform_func(xx, yx, xy, yy, dx, dy, <object>paint_data)


cdef void _paint_pop_transform_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_funcs._pop_transform_func(<object>paint_data)


cdef hb_bool_t _paint_color_glyph_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_codepoint_t glyph,
        hb_font_t *font,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    if py_funcs._color_glyph_func(glyph, <object>paint_data):
        return 1
    return 0


cdef void _paint_push_clip_glyph_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_codepoint_t glyph,
        hb_font_t *font,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_funcs._push_clip_glyph_func(glyph, <object>paint_data)


cdef void _paint_push_clip_rectangle_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        float xmin,
        float ymin,
        float xmax,
        float ymax,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_funcs._push_clip_rectangle_func(xmin, ymin, xmax, ymax, <object>paint_data)


cdef void _paint_pop_clip_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_funcs._pop_clip_func(<object>paint_data)


cdef void _paint_color_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_bool_t is_foreground,
        hb_color_t color,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_color: Color = Color.from_int(color)
    py_funcs._color_func(py_color, <bint>is_foreground, <object>paint_data)


cdef hb_bool_t _paint_image_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_blob_t *image,
        unsigned int width,
        unsigned int height,
        hb_tag_t format,
        float slant,
        hb_glyph_extents_t *extents,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_image = Blob.from_ptr(hb_blob_reference(image))
    py_format = hb_tag_to_string(format, NULL)
    py_extents = GlyphExtents(extents.x_bearing, extents.y_bearing, extents.width, extents.height)
    if py_funcs._image_func(py_image, width, height, py_format, slant, py_extents, <object>paint_data):
        return 1
    return 0


cdef void _paint_linear_gradient_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_color_line_t *color_line,
        float x0,
        float y0,
        float x1,
        float y1,
        float x2,
        float y2,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_color_line = ColorLine.from_ptr(color_line)
    py_funcs._linear_gradient_func(py_color_line, x0, y0, x1, y1, x2, y2, <object>paint_data)


cdef void _paint_radial_gradient_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_color_line_t *color_line,
        float x0,
        float y0,
        float r0,
        float x1,
        float y1,
        float r1,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_color_line = ColorLine.from_ptr(color_line)
    py_funcs._radial_gradient_func(py_color_line, x0, y0, r0, x1, y1, r1, <object>paint_data)


cdef void _paint_sweep_gradient_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_color_line_t *color_line,
        float x0,
        float y0,
        float start_angle,
        float end_angle,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_color_line = ColorLine.from_ptr(color_line)
    py_funcs._sweep_gradient_func(py_color_line, x0, y0, start_angle, end_angle, <object>paint_data)


cdef void _paint_push_group_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_funcs._push_group_func(<object>paint_data)


cdef void _paint_pop_group_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_paint_composite_mode_t mode,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_mode = PaintCompositeMode(mode)
    py_funcs._pop_group_func(py_mode, <object>paint_data)


cdef hb_bool_t _paint_custom_palette_color_func(
        hb_paint_funcs_t *funcs,
        void *paint_data,
        unsigned int color_index,
        hb_color_t *color,
        void *user_data) noexcept:
    py_funcs = <PaintFuncs>user_data
    py_color: Color = py_funcs._custom_palette_color_func(color_index, <object>paint_data)
    if py_color is not None:
        color[0] = py_color.to_int()
        return 1
    return 0


cdef class PaintFuncs:
    """Glyph paint callbacks.

    The callbacks assume that the caller maintains a stack of current
    transforms, clips and intermediate surfaces, as evidenced by the pairs
    of push/pop callbacks. The push/pop calls will be properly nested, so it
    is fine to store the different kinds of object on a single stack.

    Not all callbacks are required for all kinds of glyphs. For rendering
    COLRv0 or non-color outline glyphs, the gradient callbacks are not
    needed, and the composite callback only needs to handle simple alpha
    compositing (:attr:`PaintCompositeMode.SRC_OVER`).

    The paint-image callback is only needed for glyphs with image blobs in
    the ``CBDT``, ``sbix`` or ``SVG`` tables.

    The custom-palette-color callback is only necessary if you want to
    override colors from the font palette with custom colors.

    Wraps `hb_paint_funcs_t
    <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-t>`_.
    """

    cdef hb_paint_funcs_t* _hb_paintfuncs
    cdef object _push_transform_func
    cdef object _pop_transform_func
    cdef object _color_glyph_func
    cdef object _push_clip_glyph_func
    cdef object _push_clip_rectangle_func
    cdef object _pop_clip_func
    cdef object _color_func
    cdef object _image_func
    cdef object _linear_gradient_func
    cdef object _radial_gradient_func
    cdef object _sweep_gradient_func
    cdef object _push_group_func
    cdef object _pop_group_func
    cdef object _custom_palette_color_func

    def __cinit__(self):
        self._hb_paintfuncs = hb_paint_funcs_create()

    def __dealloc__(self):
        hb_paint_funcs_destroy(self._hb_paintfuncs)

    def set_push_transform_func(self,
                                func: Callable[[
                                    float,  # xx
                                    float,  # yx
                                    float,  # xy
                                    float,  # yy
                                    float,  # dx
                                    float,  # dy
                                    object,  # paint_data
                                ], None]):
        """Sets the push-transform callback on this :class:`PaintFuncs`.

        The callback applies a transform to subsequent paint calls. This
        transform is applied after the current transform, and remains in
        effect until a matching call to the pop-transform callback.

        Wraps `hb_paint_funcs_set_push_transform_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-push-transform-func>`_.
        """
        self._push_transform_func = func
        hb_paint_funcs_set_push_transform_func(
            self._hb_paintfuncs, _paint_push_transform_func, <void*>self, NULL)

    def set_pop_transform_func(self,
                               func: Callable[[
                                   object,  # paint_data
                               ], None]):
        """Sets the pop-transform callback on this :class:`PaintFuncs`.

        The callback undoes the effect of a prior call to the
        push-transform callback.

        Wraps `hb_paint_funcs_set_pop_transform_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-pop-transform-func>`_.
        """
        self._pop_transform_func = func
        hb_paint_funcs_set_pop_transform_func(
            self._hb_paintfuncs, _paint_pop_transform_func, <void*>self, NULL)

    def set_color_glyph_func(self,
                             func: Callable[[
                                 int,  # gid
                                 object,  # paint_data
                             ], bool]):
        """Sets the color-glyph callback on this :class:`PaintFuncs`.

        The callback renders a color glyph by glyph index. It should return
        ``True`` if the glyph was painted, ``False`` otherwise.

        Wraps `hb_paint_funcs_set_color_glyph_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-color-glyph-func>`_.
        """
        self._color_glyph_func = func
        hb_paint_funcs_set_color_glyph_func(
            self._hb_paintfuncs, _paint_color_glyph_func, <void*>self, NULL)

    def set_push_clip_glyph_func(self,
                                 func: Callable[[
                                     int,  # gid
                                     object,  # paint_data
                                 ], None]):
        """Sets the push-clip-glyph callback on this :class:`PaintFuncs`.

        The callback clips subsequent paint calls to the outline of a glyph.

        This clip is applied in addition to the current clip, and remains in
        effect until a matching call to the pop-clip callback.

        Wraps `hb_paint_funcs_set_push_clip_glyph_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-push-clip-glyph-func>`_.
        """
        self._push_clip_glyph_func = func
        hb_paint_funcs_set_push_clip_glyph_func(
            self._hb_paintfuncs, _paint_push_clip_glyph_func, <void*>self, NULL)

    def set_push_clip_rectangle_func(self,
                                     func: Callable[[
                                         float,  # xmin
                                         float,  # ymin
                                         float,  # xmax
                                         float,  # ymax
                                         object,  # paint_data
                                     ], None]):
        """Sets the push-clip-rectangle callback on this :class:`PaintFuncs`.

        The callback clips subsequent paint calls to a rectangle. The
        coordinates of the rectangle are interpreted according to the
        current transform.

        This clip is applied in addition to the current clip, and remains in
        effect until a matching call to the pop-clip callback.

        Wraps `hb_paint_funcs_set_push_clip_rectangle_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-push-clip-rectangle-func>`_.
        """
        self._push_clip_rectangle_func = func
        hb_paint_funcs_set_push_clip_rectangle_func(
            self._hb_paintfuncs, _paint_push_clip_rectangle_func, <void*>self, NULL)

    def set_pop_clip_func(self,
                          func: Callable[[
                              object,  # paint_data
                          ], None]):
        """Sets the pop-clip callback on this :class:`PaintFuncs`.

        The callback undoes the effect of a prior call to the
        push-clip-glyph or push-clip-rectangle callback.

        Wraps `hb_paint_funcs_set_pop_clip_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-pop-clip-func>`_.
        """
        self._pop_clip_func = func
        hb_paint_funcs_set_pop_clip_func(
            self._hb_paintfuncs, _paint_pop_clip_func, <void*>self, NULL)

    def set_color_func(self,
                       func: Callable[[
                           Color,  # color
                           bool,  # is_foreground
                           object,  # paint_data
                       ], None]):
        """Sets the color callback on this :class:`PaintFuncs`.

        The callback paints a color everywhere within the current clip.
        ``is_foreground`` indicates whether the color is the foreground.
        ``color`` is the color to use, unpremultiplied.

        Wraps `hb_paint_funcs_set_color_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-color-func>`_.
        """
        self._color_func = func
        hb_paint_funcs_set_color_func(
            self._hb_paintfuncs, _paint_color_func, <void*>self, NULL)

    def set_image_func(self,
                       func: Callable[[
                           Blob,  # image
                           int,  # width
                           int,  # height
                           str,  # format
                           float,  # slant
                           GlyphExtents,  # extents
                           object,  # paint_data
                       ], bool]):
        """Sets the paint-image callback on this :class:`PaintFuncs`.

        The callback paints a glyph image. It is called for glyphs with
        image blobs in the ``CBDT``, ``sbix`` or ``SVG`` tables. The
        ``format`` argument identifies the kind of data that is contained in
        ``image``. The image dimensions and glyph extents are provided if
        available, and should be used to size and position the image. The
        callback should return whether the operation was successful.

        Wraps `hb_paint_funcs_set_image_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-image-func>`_.
        """
        self._image_func = func
        hb_paint_funcs_set_image_func(
            self._hb_paintfuncs, _paint_image_func, <void*>self, NULL)

    def set_linear_gradient_func(self,
                                 func: Callable[[
                                    ColorLine,  # color_line
                                    float,  # x0
                                    float,  # y0
                                    float,  # x1
                                    float,  # y1
                                    float,  # x2
                                    float,  # y2
                                    object,  # paint_data
                                 ], None]):
        """Sets the linear-gradient callback on this :class:`PaintFuncs`.

        The callback paints a linear gradient everywhere within the current
        clip. The ``color_line`` object contains information about the
        colors of the gradient; it is only valid for the duration of the
        callback, you cannot keep it around. The coordinates of the points
        are interpreted according to the current transform.

        Wraps `hb_paint_funcs_set_linear_gradient_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-linear-gradient-func>`_.
        """
        self._linear_gradient_func = func
        hb_paint_funcs_set_linear_gradient_func(
            self._hb_paintfuncs, _paint_linear_gradient_func, <void*>self, NULL)

    def set_radial_gradient_func(self,
                                 func: Callable[[
                                    ColorLine,  # color_line
                                    float,  # x0
                                    float,  # y0
                                    float,  # r0
                                    float,  # x1
                                    float,  # y1
                                    float,  # r1
                                    object,  # paint_data
                                 ], None]):
        """Sets the radial-gradient callback on this :class:`PaintFuncs`.

        The callback paints a radial gradient everywhere within the current
        clip. The ``color_line`` object contains information about the
        colors of the gradient; it is only valid for the duration of the
        callback, you cannot keep it around. The coordinates of the points
        are interpreted according to the current transform.

        Wraps `hb_paint_funcs_set_radial_gradient_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-radial-gradient-func>`_.
        """
        self._radial_gradient_func = func
        hb_paint_funcs_set_radial_gradient_func(
            self._hb_paintfuncs, _paint_radial_gradient_func, <void*>self, NULL)

    def set_sweep_gradient_func(self,
                                func: Callable[[
                                    ColorLine,  # color_line
                                    float,  # x0
                                    float,  # y0
                                    float,  # start_angle
                                    float,  # end_angle
                                    object,  # paint_data
                                ], None]):
        """Sets the sweep-gradient callback on this :class:`PaintFuncs`.

        The callback paints a sweep gradient everywhere within the current
        clip. The ``color_line`` object contains information about the
        colors of the gradient; it is only valid for the duration of the
        callback, you cannot keep it around. The coordinates of the points
        are interpreted according to the current transform.

        Wraps `hb_paint_funcs_set_sweep_gradient_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-sweep-gradient-func>`_.
        """
        self._sweep_gradient_func = func
        hb_paint_funcs_set_sweep_gradient_func(
            self._hb_paintfuncs, _paint_sweep_gradient_func, <void*>self, NULL)

    def set_push_group_func(self,
                            func: Callable[[
                                object,  # paint_data
                            ], None]):
        """Sets the push-group callback on this :class:`PaintFuncs`.

        The callback uses an intermediate surface for subsequent paint
        calls. The drawing will be redirected to an intermediate surface
        until a matching call to the pop-group callback.

        Wraps `hb_paint_funcs_set_push_group_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-push-group-func>`_.
        """
        self._push_group_func = func
        hb_paint_funcs_set_push_group_func(
            self._hb_paintfuncs, _paint_push_group_func, <void*>self, NULL)

    def set_pop_group_func(self,
                           func: Callable[[
                               PaintCompositeMode,  # mode
                               object,  # paint_data
                           ], None]):
        """Sets the pop-group callback on this :class:`PaintFuncs`.

        The callback undoes the effect of a prior call to the push-group
        callback. It stops the redirection to the intermediate surface, and
        then composites it on the previous surface, using the compositing
        mode passed to the callback.

        Wraps `hb_paint_funcs_set_pop_group_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-pop-group-func>`_.
        """
        self._pop_group_func = func
        hb_paint_funcs_set_pop_group_func(
            self._hb_paintfuncs, _paint_pop_group_func, <void*>self, NULL)

    def set_custom_palette_color_func(self,
                                      func: Callable[[
                                          int,  # color_index
                                          object,  # paint_data
                                      ], Color]):
        """Sets the custom-palette-color callback on this :class:`PaintFuncs`.

        The callback fetches a custom palette override color for
        ``color_index``. Custom palette colors override colors from the
        font's selected color palette. It is not necessary to override all
        palette entries; return ``None`` for entries that should be taken
        from the font palette.

        Wraps `hb_paint_funcs_set_custom_palette_color_func()
        <https://harfbuzz.github.io/harfbuzz-hb-paint.html#hb-paint-funcs-set-custom-palette-color-func>`_.
        """
        self._custom_palette_color_func = func
        hb_paint_funcs_set_custom_palette_color_func(
            self._hb_paintfuncs, _paint_custom_palette_color_func, <void*>self, NULL)
