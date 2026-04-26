class PaintCompositeMode(IntEnum):
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
    offset: float
    is_foreground: bool
    color: Color


class PaintExtend(IntEnum):
    PAD = HB_PAINT_EXTEND_PAD
    REPEAT = HB_PAINT_EXTEND_REPEAT
    REFLECT = HB_PAINT_EXTEND_REFLECT


cdef class ColorLine:
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
        self._push_transform_func = func
        hb_paint_funcs_set_push_transform_func(
            self._hb_paintfuncs, _paint_push_transform_func, <void*>self, NULL)

    def set_pop_transform_func(self,
                               func: Callable[[
                                   object,  # paint_data
                               ], None]):
        self._pop_transform_func = func
        hb_paint_funcs_set_pop_transform_func(
            self._hb_paintfuncs, _paint_pop_transform_func, <void*>self, NULL)

    def set_color_glyph_func(self,
                             func: Callable[[
                                 int,  # gid
                                 object,  # paint_data
                             ], bool]):
        self._color_glyph_func = func
        hb_paint_funcs_set_color_glyph_func(
            self._hb_paintfuncs, _paint_color_glyph_func, <void*>self, NULL)

    def set_push_clip_glyph_func(self,
                                 func: Callable[[
                                     int,  # gid
                                     object,  # paint_data
                                 ], None]):
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
        self._push_clip_rectangle_func = func
        hb_paint_funcs_set_push_clip_rectangle_func(
            self._hb_paintfuncs, _paint_push_clip_rectangle_func, <void*>self, NULL)

    def set_pop_clip_func(self,
                          func: Callable[[
                              object,  # paint_data
                          ], None]):
        self._pop_clip_func = func
        hb_paint_funcs_set_pop_clip_func(
            self._hb_paintfuncs, _paint_pop_clip_func, <void*>self, NULL)

    def set_color_func(self,
                       func: Callable[[
                           Color,  # color
                           bool,  # is_foreground
                           object,  # paint_data
                       ], None]):
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
        self._sweep_gradient_func = func
        hb_paint_funcs_set_sweep_gradient_func(
            self._hb_paintfuncs, _paint_sweep_gradient_func, <void*>self, NULL)

    def set_push_group_func(self,
                            func: Callable[[
                                object,  # paint_data
                            ], None]):
        self._push_group_func = func
        hb_paint_funcs_set_push_group_func(
            self._hb_paintfuncs, _paint_push_group_func, <void*>self, NULL)

    def set_pop_group_func(self,
                           func: Callable[[
                               PaintCompositeMode,  # mode
                               object,  # paint_data
                           ], None]):
        self._pop_group_func = func
        hb_paint_funcs_set_pop_group_func(
            self._hb_paintfuncs, _paint_pop_group_func, <void*>self, NULL)

    def set_custom_palette_color_func(self,
                                      func: Callable[[
                                          int,  # color_index
                                          object,  # paint_data
                                      ], Color]):
        self._custom_palette_color_func = func
        hb_paint_funcs_set_custom_palette_color_func(
            self._hb_paintfuncs, _paint_custom_palette_color_func, <void*>self, NULL)
