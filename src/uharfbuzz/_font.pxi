class GlyphExtents(NamedTuple):
    x_bearing: int
    y_bearing: int
    width: int
    height: int


class FontExtents(NamedTuple):
    ascender: int
    descender: int
    line_gap: int


class OTMathConstant(IntEnum):
    SCRIPT_PERCENT_SCALE_DOWN = HB_OT_MATH_CONSTANT_SCRIPT_PERCENT_SCALE_DOWN
    SCRIPT_SCRIPT_PERCENT_SCALE_DOWN = HB_OT_MATH_CONSTANT_SCRIPT_SCRIPT_PERCENT_SCALE_DOWN
    DELIMITED_SUB_FORMULA_MIN_HEIGHT = HB_OT_MATH_CONSTANT_DELIMITED_SUB_FORMULA_MIN_HEIGHT
    DISPLAY_OPERATOR_MIN_HEIGHT = HB_OT_MATH_CONSTANT_DISPLAY_OPERATOR_MIN_HEIGHT
    MATH_LEADING = HB_OT_MATH_CONSTANT_MATH_LEADING
    AXIS_HEIGHT = HB_OT_MATH_CONSTANT_AXIS_HEIGHT
    ACCENT_BASE_HEIGHT = HB_OT_MATH_CONSTANT_ACCENT_BASE_HEIGHT
    FLATTENED_ACCENT_BASE_HEIGHT = HB_OT_MATH_CONSTANT_FLATTENED_ACCENT_BASE_HEIGHT
    SUBSCRIPT_SHIFT_DOWN = HB_OT_MATH_CONSTANT_SUBSCRIPT_SHIFT_DOWN
    SUBSCRIPT_TOP_MAX = HB_OT_MATH_CONSTANT_SUBSCRIPT_TOP_MAX
    SUBSCRIPT_BASELINE_DROP_MIN = HB_OT_MATH_CONSTANT_SUBSCRIPT_BASELINE_DROP_MIN
    SUPERSCRIPT_SHIFT_UP = HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP
    SUPERSCRIPT_SHIFT_UP_CRAMPED = HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP_CRAMPED
    SUPERSCRIPT_BOTTOM_MIN = HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MIN
    SUPERSCRIPT_BASELINE_DROP_MAX = HB_OT_MATH_CONSTANT_SUPERSCRIPT_BASELINE_DROP_MAX
    SUB_SUPERSCRIPT_GAP_MIN = HB_OT_MATH_CONSTANT_SUB_SUPERSCRIPT_GAP_MIN
    SUPERSCRIPT_BOTTOM_MAX_WITH_SUBSCRIPT = HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MAX_WITH_SUBSCRIPT
    SPACE_AFTER_SCRIPT = HB_OT_MATH_CONSTANT_SPACE_AFTER_SCRIPT
    UPPER_LIMIT_GAP_MIN = HB_OT_MATH_CONSTANT_UPPER_LIMIT_GAP_MIN
    UPPER_LIMIT_BASELINE_RISE_MIN = HB_OT_MATH_CONSTANT_UPPER_LIMIT_BASELINE_RISE_MIN
    LOWER_LIMIT_GAP_MIN = HB_OT_MATH_CONSTANT_LOWER_LIMIT_GAP_MIN
    LOWER_LIMIT_BASELINE_DROP_MIN = HB_OT_MATH_CONSTANT_LOWER_LIMIT_BASELINE_DROP_MIN
    STACK_TOP_SHIFT_UP = HB_OT_MATH_CONSTANT_STACK_TOP_SHIFT_UP
    STACK_TOP_DISPLAY_STYLE_SHIFT_UP = HB_OT_MATH_CONSTANT_STACK_TOP_DISPLAY_STYLE_SHIFT_UP
    STACK_BOTTOM_SHIFT_DOWN = HB_OT_MATH_CONSTANT_STACK_BOTTOM_SHIFT_DOWN
    STACK_BOTTOM_DISPLAY_STYLE_SHIFT_DOWN = HB_OT_MATH_CONSTANT_STACK_BOTTOM_DISPLAY_STYLE_SHIFT_DOWN
    STACK_GAP_MIN = HB_OT_MATH_CONSTANT_STACK_GAP_MIN
    STACK_DISPLAY_STYLE_GAP_MIN = HB_OT_MATH_CONSTANT_STACK_DISPLAY_STYLE_GAP_MIN
    STRETCH_STACK_TOP_SHIFT_UP = HB_OT_MATH_CONSTANT_STRETCH_STACK_TOP_SHIFT_UP
    STRETCH_STACK_BOTTOM_SHIFT_DOWN = HB_OT_MATH_CONSTANT_STRETCH_STACK_BOTTOM_SHIFT_DOWN
    STRETCH_STACK_GAP_ABOVE_MIN = HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_ABOVE_MIN
    STRETCH_STACK_GAP_BELOW_MIN = HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_BELOW_MIN
    FRACTION_NUMERATOR_SHIFT_UP = HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_SHIFT_UP
    FRACTION_NUMERATOR_DISPLAY_STYLE_SHIFT_UP = HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_DISPLAY_STYLE_SHIFT_UP
    FRACTION_DENOMINATOR_SHIFT_DOWN = HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_SHIFT_DOWN
    FRACTION_DENOMINATOR_DISPLAY_STYLE_SHIFT_DOWN = HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_DISPLAY_STYLE_SHIFT_DOWN
    FRACTION_NUMERATOR_GAP_MIN = HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_GAP_MIN
    FRACTION_NUM_DISPLAY_STYLE_GAP_MIN = HB_OT_MATH_CONSTANT_FRACTION_NUM_DISPLAY_STYLE_GAP_MIN
    FRACTION_RULE_THICKNESS = HB_OT_MATH_CONSTANT_FRACTION_RULE_THICKNESS
    FRACTION_DENOMINATOR_GAP_MIN = HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_GAP_MIN
    FRACTION_DENOM_DISPLAY_STYLE_GAP_MIN = HB_OT_MATH_CONSTANT_FRACTION_DENOM_DISPLAY_STYLE_GAP_MIN
    SKEWED_FRACTION_HORIZONTAL_GAP = HB_OT_MATH_CONSTANT_SKEWED_FRACTION_HORIZONTAL_GAP
    SKEWED_FRACTION_VERTICAL_GAP = HB_OT_MATH_CONSTANT_SKEWED_FRACTION_VERTICAL_GAP
    OVERBAR_VERTICAL_GAP = HB_OT_MATH_CONSTANT_OVERBAR_VERTICAL_GAP
    OVERBAR_RULE_THICKNESS = HB_OT_MATH_CONSTANT_OVERBAR_RULE_THICKNESS
    OVERBAR_EXTRA_ASCENDER = HB_OT_MATH_CONSTANT_OVERBAR_EXTRA_ASCENDER
    UNDERBAR_VERTICAL_GAP = HB_OT_MATH_CONSTANT_UNDERBAR_VERTICAL_GAP
    UNDERBAR_RULE_THICKNESS = HB_OT_MATH_CONSTANT_UNDERBAR_RULE_THICKNESS
    UNDERBAR_EXTRA_DESCENDER = HB_OT_MATH_CONSTANT_UNDERBAR_EXTRA_DESCENDER
    RADICAL_VERTICAL_GAP = HB_OT_MATH_CONSTANT_RADICAL_VERTICAL_GAP
    RADICAL_DISPLAY_STYLE_VERTICAL_GAP = HB_OT_MATH_CONSTANT_RADICAL_DISPLAY_STYLE_VERTICAL_GAP
    RADICAL_RULE_THICKNESS = HB_OT_MATH_CONSTANT_RADICAL_RULE_THICKNESS
    RADICAL_EXTRA_ASCENDER = HB_OT_MATH_CONSTANT_RADICAL_EXTRA_ASCENDER
    RADICAL_KERN_BEFORE_DEGREE = HB_OT_MATH_CONSTANT_RADICAL_KERN_BEFORE_DEGREE
    RADICAL_KERN_AFTER_DEGREE = HB_OT_MATH_CONSTANT_RADICAL_KERN_AFTER_DEGREE
    RADICAL_DEGREE_BOTTOM_RAISE_PERCENT = HB_OT_MATH_CONSTANT_RADICAL_DEGREE_BOTTOM_RAISE_PERCENT


class OTMathKernEntry(NamedTuple):
    max_correction_height: int
    kern_value: int


class OTMathKern(IntEnum):
    TOP_RIGHT = HB_OT_MATH_KERN_TOP_RIGHT
    TOP_LEFT = HB_OT_MATH_KERN_TOP_LEFT
    BOTTOM_RIGHT = HB_OT_MATH_KERN_BOTTOM_RIGHT
    BOTTOM_LEFT = HB_OT_MATH_KERN_BOTTOM_LEFT


class OTMathGlyphVariant(NamedTuple):
    glyph: int
    advance: int


class OTMathGlyphPartFlags(IntFlag):
    EXTENDER = HB_OT_MATH_GLYPH_PART_FLAG_EXTENDER


class OTMathGlyphPart(NamedTuple):
    glyph: int
    start_connector_length: int
    end_connector_length: int
    full_advance: int
    flags: OTMathGlyphPartFlags


class OTMetricsTag(IntEnum):
    HORIZONTAL_ASCENDER = HB_OT_METRICS_TAG_HORIZONTAL_ASCENDER
    HORIZONTAL_DESCENDER = HB_OT_METRICS_TAG_HORIZONTAL_DESCENDER
    HORIZONTAL_LINE_GAP = HB_OT_METRICS_TAG_HORIZONTAL_LINE_GAP
    HORIZONTAL_CLIPPING_ASCENT = HB_OT_METRICS_TAG_HORIZONTAL_CLIPPING_ASCENT
    HORIZONTAL_CLIPPING_DESCENT = HB_OT_METRICS_TAG_HORIZONTAL_CLIPPING_DESCENT
    VERTICAL_ASCENDER = HB_OT_METRICS_TAG_VERTICAL_ASCENDER
    VERTICAL_DESCENDER = HB_OT_METRICS_TAG_VERTICAL_DESCENDER
    VERTICAL_LINE_GAP = HB_OT_METRICS_TAG_VERTICAL_LINE_GAP
    HORIZONTAL_CARET_RISE = HB_OT_METRICS_TAG_HORIZONTAL_CARET_RISE
    HORIZONTAL_CARET_RUN = HB_OT_METRICS_TAG_HORIZONTAL_CARET_RUN
    HORIZONTAL_CARET_OFFSET = HB_OT_METRICS_TAG_HORIZONTAL_CARET_OFFSET
    VERTICAL_CARET_RISE = HB_OT_METRICS_TAG_VERTICAL_CARET_RISE
    VERTICAL_CARET_RUN = HB_OT_METRICS_TAG_VERTICAL_CARET_RUN
    VERTICAL_CARET_OFFSET = HB_OT_METRICS_TAG_VERTICAL_CARET_OFFSET
    X_HEIGHT = HB_OT_METRICS_TAG_X_HEIGHT
    CAP_HEIGHT = HB_OT_METRICS_TAG_CAP_HEIGHT
    SUBSCRIPT_EM_X_SIZE = HB_OT_METRICS_TAG_SUBSCRIPT_EM_X_SIZE
    SUBSCRIPT_EM_Y_SIZE = HB_OT_METRICS_TAG_SUBSCRIPT_EM_Y_SIZE
    SUBSCRIPT_EM_X_OFFSET = HB_OT_METRICS_TAG_SUBSCRIPT_EM_X_OFFSET
    SUBSCRIPT_EM_Y_OFFSET = HB_OT_METRICS_TAG_SUBSCRIPT_EM_Y_OFFSET
    SUPERSCRIPT_EM_X_SIZE = HB_OT_METRICS_TAG_SUPERSCRIPT_EM_X_SIZE
    SUPERSCRIPT_EM_Y_SIZE = HB_OT_METRICS_TAG_SUPERSCRIPT_EM_Y_SIZE
    SUPERSCRIPT_EM_X_OFFSET = HB_OT_METRICS_TAG_SUPERSCRIPT_EM_X_OFFSET
    SUPERSCRIPT_EM_Y_OFFSET = HB_OT_METRICS_TAG_SUPERSCRIPT_EM_Y_OFFSET
    STRIKEOUT_SIZE = HB_OT_METRICS_TAG_STRIKEOUT_SIZE
    STRIKEOUT_OFFSET = HB_OT_METRICS_TAG_STRIKEOUT_OFFSET
    UNDERLINE_SIZE = HB_OT_METRICS_TAG_UNDERLINE_SIZE
    UNDERLINE_OFFSET = HB_OT_METRICS_TAG_UNDERLINE_OFFSET

class StyleTag(IntEnum):
    ITALIC = HB_STYLE_TAG_ITALIC
    OPTICAL_SIZE = HB_STYLE_TAG_OPTICAL_SIZE
    SLANT_ANGLE = HB_STYLE_TAG_SLANT_ANGLE
    SLANT_RATIO = HB_STYLE_TAG_SLANT_RATIO
    WIDTH = HB_STYLE_TAG_WIDTH
    WEIGHT = HB_STYLE_TAG_WEIGHT

cdef class Font:
    cdef hb_font_t* _hb_font
    # GC bookkeeping
    cdef Face _face
    cdef FontFuncs _ffuncs

    def __cinit__(self, face_or_font: Union[Face, Font] = None):
        if face_or_font is not None:
            if isinstance(face_or_font, Font):
                self.__create_sub_font(face_or_font)
                return
            self.__create(face_or_font)
        else:
            self._hb_font = hb_font_get_empty()
            self._face = Face()

    cdef __create(self, Face face):
        self._hb_font = hb_font_create(face._hb_face)
        self._face = face

    cdef __create_sub_font(self, Font font):
        self._hb_font = hb_font_create_sub_font(font._hb_font)
        self._face = font._face

    def __dealloc__(self):
        hb_font_destroy(self._hb_font)
        self._face = self._ffuncs = None

    @staticmethod
    cdef Font from_ptr(hb_font_t* hb_font):
        """Create Font from a pointer taking ownership of a it."""

        cdef Font wrapper = Font.__new__(Font)
        wrapper._hb_font = hb_font
        wrapper._face = Face.from_ptr(hb_face_reference(hb_font_get_face(hb_font)))
        return wrapper

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls, face: Face) -> Font:
        cdef Font inst = cls(face)
        return inst

    @property
    def face(self) -> Face:
        return self._face

    @property
    def funcs(self) -> FontFuncs:
        return self._ffuncs

    @funcs.setter
    def funcs(self, ffuncs: FontFuncs):
        hb_font_set_funcs(
            self._hb_font, ffuncs._hb_ffuncs, <void*>self, NULL)
        self._ffuncs = ffuncs

    @property
    def scale(self) -> Tuple[int, int]:
        cdef int x, y
        hb_font_get_scale(self._hb_font, &x, &y)
        return (x, y)

    @scale.setter
    def scale(self, value: Tuple[int, int]):
        x, y = value
        hb_font_set_scale(self._hb_font, x, y)

    @property
    def ppem(self) -> Tuple[int, int]:
        cdef unsigned int x, y
        hb_font_get_ppem(self._hb_font, &x, &y)
        return (x, y)

    @ppem.setter
    def ppem(self, value: Tuple[int, int]):
        x, y = value
        hb_font_set_ppem(self._hb_font, x, y)

    @property
    def ptem(self) -> float:
        return hb_font_get_ptem(self._hb_font)

    @ptem.setter
    def ptem(self, value: float):
        hb_font_set_ptem(self._hb_font, value)

    @property
    def synthetic_slant(self) -> float:
        return hb_font_get_synthetic_slant(self._hb_font)

    @synthetic_slant.setter
    def synthetic_slant(self, value: float):
        hb_font_set_synthetic_slant(self._hb_font, value)

    @property
    def synthetic_bold(self) -> Tuple[float, float, bool]:
        cdef float x_embolden
        cdef float y_embolden
        cdef hb_bool_t in_place
        hb_font_get_synthetic_bold(self._hb_font, &x_embolden, &y_embolden, &in_place)
        return (x_embolden, y_embolden, bool(in_place))

    @synthetic_bold.setter
    def synthetic_bold(self, value: float|tuple[float]|tuple[float,float]|tuple[float,float,bool]):
        cdef float x_embolden
        cdef float y_embolden
        cdef hb_bool_t in_place = False
        if isinstance(value, tuple):
            if len(value) == 1:
                x_embolden = y_embolden = value[0]
            elif len(value) == 2:
                x_embolden, y_embolden = value
            else:
                x_embolden, y_embolden, in_place = value
        else:
            x_embolden = y_embolden = value
        hb_font_set_synthetic_bold(self._hb_font, x_embolden, y_embolden, in_place)

    @property
    def var_named_instance(self) -> int:
        return hb_font_get_var_named_instance(self._hb_font)

    @var_named_instance.setter
    def var_named_instance(self, value: int):
        hb_font_set_var_named_instance(self._hb_font, value)

    def set_variations(self, variations: Dict[str, float]):
        cdef unsigned int size
        cdef hb_variation_t* hb_variations
        cdef bytes packed
        cdef hb_variation_t variation
        size = len(variations)
        hb_variations = <hb_variation_t*>malloc(size * sizeof(hb_variation_t))
        if not hb_variations:
            raise MemoryError()

        try:
            for i, (name, value) in enumerate(variations.items()):
                packed = name.encode()
                variation.tag = hb_tag_from_string(packed, -1)
                variation.value = value
                hb_variations[i] = variation
            hb_font_set_variations(self._hb_font, hb_variations, size)
        finally:
            free(hb_variations)

    def set_variation(self, name: str, value: float):
        packed = name.encode()
        cdef hb_tag_t tag = hb_tag_from_string(packed, -1)
        hb_font_set_variation(self._hb_font, tag, value)

    def get_glyph_name(self, gid: int) -> str | None:
        cdef char name[64]
        cdef bytes packed
        success = hb_font_get_glyph_name(self._hb_font, gid, name, 64)
        if success:
            packed = name
            return packed.decode()
        else:
            return None

    def get_glyph_from_name(self, name: str) -> int | None:
        cdef hb_codepoint_t gid
        cdef bytes packed
        packed = name.encode()
        success = hb_font_get_glyph_from_name(self._hb_font, <char*>packed, len(packed), &gid)
        return gid if success else None

    def get_glyph_extents(self, gid: int) -> GlyphExtents:
        cdef hb_glyph_extents_t extents
        success = hb_font_get_glyph_extents(self._hb_font, gid, &extents)
        if success:
            return GlyphExtents(
                extents.x_bearing,
                extents.y_bearing,
                extents.width,
                extents.height,
            )
        else:
            return None

    def get_glyph_h_advance(self, gid: int) -> int:
        return hb_font_get_glyph_h_advance(self._hb_font, gid)

    def get_glyph_v_advance(self, gid: int) -> int:
        return hb_font_get_glyph_v_advance(self._hb_font, gid)

    def get_glyph_h_origin(self, gid: int) -> Tuple[int, int] | None:
        cdef hb_position_t x, y
        success = hb_font_get_glyph_h_origin(self._hb_font, gid, &x, &y)
        return (x, y) if success else None

    def get_glyph_v_origin(self, gid: int) -> Tuple[int, int] | None:
        cdef hb_position_t x, y
        success = hb_font_get_glyph_v_origin(self._hb_font, gid, &x, &y)
        return (x, y) if success else None

    def get_font_extents(self, direction: str) -> FontExtents:
        cdef hb_font_extents_t extents
        cdef hb_direction_t hb_direction
        cdef bytes packed
        packed = direction.encode()
        hb_direction = hb_direction_from_string(<char*>packed, -1)
        hb_font_get_extents_for_direction(
            self._hb_font, hb_direction, &extents
        )
        return FontExtents(
            extents.ascender,
            extents.descender,
            extents.line_gap
        )

    def get_variation_glyph(self, unicode: int, variation_selector: int) -> int | None:
        cdef hb_codepoint_t gid
        success = hb_font_get_variation_glyph(self._hb_font, unicode, variation_selector, &gid)
        return gid if success else None

    def get_nominal_glyph(self, unicode: int) -> int:
        cdef hb_codepoint_t gid
        success = hb_font_get_nominal_glyph(self._hb_font, unicode, &gid)
        return gid if success else None

    def get_var_coords_normalized(self) -> List[float]:
        cdef unsigned int length
        cdef const int *coords
        coords = hb_font_get_var_coords_normalized(self._hb_font, &length)
        # Convert from 2.14 fixed to float: divide by 1 << 14
        return [coords[i] / 0x4000 for i in range(length)]

    def set_var_coords_normalized(self, coords: List[float]):
        cdef unsigned int length
        cdef int *coords_2dot14
        length = len(coords)
        coords_2dot14 = <int *>malloc(length * sizeof(int))
        if coords_2dot14 is NULL:
            raise MemoryError()
        try:
            for i in range(length):
                # Convert from float to 2.14 fixed: multiply by 1 << 14
                coords_2dot14[i] = round(coords[i] * 0x4000)
            hb_font_set_var_coords_normalized(self._hb_font, coords_2dot14, length)
        finally:
            free(coords_2dot14)

    def get_var_coords_design(self):
        cdef unsigned int length
        cdef const float *coords
        coords = hb_font_get_var_coords_design(self._hb_font, &length)
        return [coords[i] for i in range(length)]

    def set_var_coords_design(self, coords: List[float]):
        cdef unsigned int length
        cdef cython.float *c_coords
        length = len(coords)
        c_coords = <cython.float*>malloc(length * sizeof(cython.float))
        if c_coords is NULL:
            raise MemoryError()
        try:
            for i in range(length):
                c_coords[i] = coords[i]
            hb_font_set_var_coords_design(self._hb_font, c_coords, length)
        finally:
            free(c_coords)

    def glyph_to_string(self, gid: int) -> str:
        cdef char name[64]
        cdef bytes packed
        hb_font_glyph_to_string(self._hb_font, gid, name, 64)
        packed = name
        return packed.decode()

    def glyph_from_string(self, string: str) -> int:
        cdef hb_codepoint_t gid
        cdef bytes packed
        packed = string.encode()
        success = hb_font_glyph_from_string(self._hb_font, <char*>packed, len(packed), &gid)
        return gid if success else None

    def draw_glyph(self, gid: int, draw_funcs: DrawFuncs, draw_state: object = None):
        cdef void *draw_state_p = <void *>draw_state
        if PyCapsule_IsValid(draw_state, NULL):
            draw_state_p = <void *>PyCapsule_GetPointer(draw_state, NULL)
        hb_font_draw_glyph(self._hb_font, gid, draw_funcs._hb_drawfuncs, draw_state_p);

    def paint_glyph(self, gid: int,
                    paint_funcs: PaintFuncs,
                    paint_state: object = None,
                    palette_index: int = 0,
                    foreground: Color | None = None):
        cdef void *paint_state_p = <void *>paint_state
        cdef hb_color_t c_foreground = 0x000000FF
        if foreground is not None:
            c_foreground = foreground.to_int()
        hb_font_paint_glyph(self._hb_font,
                            gid,
                            paint_funcs._hb_paintfuncs,
                            paint_state_p,
                            palette_index,
                            c_foreground)

    def draw_glyph_with_pen(self, gid: int, pen):
        global drawfuncs
        if drawfuncs == NULL:
            drawfuncs = hb_draw_funcs_create()
            hb_draw_funcs_set_move_to_func(drawfuncs, _pen_move_to_func, NULL, NULL)
            hb_draw_funcs_set_line_to_func(drawfuncs, _pen_line_to_func, NULL, NULL)
            hb_draw_funcs_set_cubic_to_func(drawfuncs, _pen_cubic_to_func, NULL, NULL)
            hb_draw_funcs_set_quadratic_to_func(drawfuncs, _pen_quadratic_to_func, NULL, NULL)
            hb_draw_funcs_set_close_path_func(drawfuncs, _pen_close_path_func, NULL, NULL)

        # Keep local copy so they are not GC'ed before the call completes
        moveTo = pen.moveTo
        lineTo = pen.lineTo
        curveTo = pen.curveTo
        qCurveTo = pen.qCurveTo
        closePath = pen.closePath

        cdef _pen_methods methods
        methods.moveTo = <void*>moveTo
        methods.lineTo = <void*>lineTo
        methods.curveTo = <void*>curveTo
        methods.qCurveTo = <void*>qCurveTo
        methods.closePath = <void*>closePath

        hb_font_draw_glyph(self._hb_font, gid, drawfuncs, <void*>&methods)

    # math
    def get_math_constant(self, constant: OTMathConstant) -> int:
        if constant >= len(OTMathConstant):
            raise ValueError("invalid constant")
        return hb_ot_math_get_constant(self._hb_font, constant)

    def get_math_glyph_italics_correction(self, glyph: int) -> int:
        return hb_ot_math_get_glyph_italics_correction(self._hb_font, glyph)

    def get_math_glyph_top_accent_attachment(self, glyph: int) -> int:
        return hb_ot_math_get_glyph_top_accent_attachment(self._hb_font, glyph)

    def get_math_min_connector_overlap(self, direction: str) -> int:
        cdef bytes packed = direction.encode()
        cdef char* cstr = packed
        cdef hb_direction_t hb_direction = hb_direction_from_string(cstr, -1)
        return hb_ot_math_get_min_connector_overlap(self._hb_font, hb_direction)

    def get_math_glyph_kerning(self, glyph: int, kern: OTMathKern, correction_height: int) -> int:
        if kern >= len(OTMathKern):
            raise ValueError("invalid kern")
        return hb_ot_math_get_glyph_kerning(self._hb_font, glyph, kern, correction_height)

    def get_math_glyph_kernings(self, glyph: int, kern: OTMathKern) -> List[OTMathKernEntry]:
        if kern >= len(OTMathKern):
            raise ValueError("invalid kern")
        cdef unsigned int count = STATIC_ARRAY_SIZE
        cdef hb_ot_math_kern_entry_t kerns_array[STATIC_ARRAY_SIZE]
        cdef list kerns = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while count == STATIC_ARRAY_SIZE:
            hb_ot_math_get_glyph_kernings(self._hb_font, glyph, kern, start_offset,
                &count, kerns_array)
            for i in range(count):
                kerns.append(OTMathKernEntry(kerns_array[i].max_correction_height, kerns_array[i].kern_value))
            start_offset += count
        return kerns

    def get_math_glyph_variants(self, glyph: int, direction: str) -> List[OTMathGlyphVariant]:
        cdef bytes packed = direction.encode()
        cdef char* cstr = packed
        cdef hb_direction_t hb_direction = hb_direction_from_string(cstr, -1)
        cdef unsigned int count = STATIC_ARRAY_SIZE
        cdef hb_ot_math_glyph_variant_t variants_array[STATIC_ARRAY_SIZE]
        cdef list variants = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while count == STATIC_ARRAY_SIZE:
            hb_ot_math_get_glyph_variants(self._hb_font, glyph, hb_direction, start_offset,
                &count, variants_array)
            for i in range(count):
                variants.append(OTMathGlyphVariant(variants_array[i].glyph, variants_array[i].advance))
            start_offset += count
        return variants

    def get_math_glyph_assembly(self, glyph: int, direction: str) -> Tuple[List[OTMathGlyphPart], int]:
        cdef bytes packed = direction.encode()
        cdef char* cstr = packed
        cdef hb_direction_t hb_direction = hb_direction_from_string(cstr, -1)
        cdef unsigned int count = STATIC_ARRAY_SIZE
        cdef hb_ot_math_glyph_part_t assembly_array[STATIC_ARRAY_SIZE]
        cdef list assembly = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        cdef hb_position_t italics_correction = 0
        while count == STATIC_ARRAY_SIZE:
            hb_ot_math_get_glyph_assembly(self._hb_font,
                glyph, hb_direction, start_offset,
                &count, assembly_array, &italics_correction)
            for i in range(count):
                assembly.append(
                    OTMathGlyphPart(assembly_array[i].glyph, assembly_array[i].start_connector_length,
                        assembly_array[i].end_connector_length, assembly_array[i].full_advance,
                        OTMathGlyphPartFlags(assembly_array[i].flags)))
            start_offset += count
        return assembly, italics_correction

    # metrics
    def get_metric_position(self, tag: OTMetricsTag) -> int:
        cdef hb_position_t position
        if hb_ot_metrics_get_position(self._hb_font, tag, &position):
            return position
        return None

    def get_metric_position_with_fallback(font, tag: OTMetricsTag) -> int:
        cdef hb_position_t position
        hb_ot_metrics_get_position_with_fallback(font._hb_font, tag, &position)
        return position

    def get_metric_variation(self, tag: OTMetricsTag) -> float:
        return hb_ot_metrics_get_variation(self._hb_font, tag)

    def get_metric_x_variation(self, tag: OTMetricsTag) -> int:
        return hb_ot_metrics_get_x_variation(self._hb_font, tag)

    def get_metric_y_variation(self, tag: OTMetricsTag) -> int:
        return hb_ot_metrics_get_y_variation(self._hb_font, tag)

    # color
    def get_glyph_color_png(self, glyph: int) -> Blob:
        cdef hb_blob_t* blob
        blob = hb_ot_color_glyph_reference_png(self._hb_font, glyph)
        return Blob.from_ptr(blob)

    #layout
    def get_layout_baseline(self,
                           baseline_tag: str,
                           direction: str,
                           script_tag: str,
                           language_tag: str) -> int:
        cdef hb_ot_layout_baseline_tag_t hb_baseline_tag
        cdef hb_direction_t hb_direction
        cdef hb_tag_t hb_script_tag
        cdef hb_tag_t hb_language_tag
        cdef hb_position_t hb_position
        cdef hb_bool_t success
        cdef bytes packed

        if baseline_tag == "romn":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_ROMAN
        elif baseline_tag == "hang":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_HANGING
        elif baseline_tag == "icfb":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_BOTTOM_OR_LEFT
        elif baseline_tag == "icft":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_TOP_OR_RIGHT
        elif baseline_tag == "ideo":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_BOTTOM_OR_LEFT
        elif baseline_tag == "idtp":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_TOP_OR_RIGHT
        elif baseline_tag == "math":
            hb_baseline_tag = HB_OT_LAYOUT_BASELINE_TAG_MATH
        else:
            raise ValueError(f"invalid baseline tag '{baseline_tag}'")
        packed = direction.encode()
        hb_direction = hb_direction_from_string(<char*>packed, -1)
        packed = script_tag.encode()
        hb_script_tag = hb_tag_from_string(<char*>packed, -1)
        packed = language_tag.encode()
        hb_language_tag = hb_tag_from_string(<char*>packed, -1)
        success = hb_ot_layout_get_baseline(self._hb_font,
                                            hb_baseline_tag,
                                            hb_direction,
                                            hb_script_tag,
                                            hb_language_tag,
                                            &hb_position)
        if success:
            return hb_position
        else:
            return None

    # style
    def get_style_value(self, tag: StyleTag) -> float:
        return hb_style_get_value(self._hb_font, tag)

cdef struct _pen_methods:
    void *moveTo
    void *lineTo
    void *curveTo
    void *qCurveTo
    void *closePath

cdef hb_draw_funcs_t* drawfuncs = NULL

cdef void _pen_move_to_func(hb_draw_funcs_t *dfuncs,
                            void *draw_data,
                            hb_draw_state_t *st,
                            float to_x,
                            float to_y,
                            void *user_data) noexcept:
    (<object>((<_pen_methods*>draw_data).moveTo))((to_x, to_y))

cdef void _pen_line_to_func(hb_draw_funcs_t *dfuncs,
                            void *draw_data,
                            hb_draw_state_t *st,
                            float to_x,
                            float to_y,
                            void *user_data) noexcept:
    (<object>((<_pen_methods*>draw_data).lineTo))((to_x, to_y))

cdef void _pen_close_path_func(hb_draw_funcs_t *dfuncs,
                               void *draw_data,
                               hb_draw_state_t *st,
                               void *user_data) noexcept:
    (<object>((<_pen_methods*>draw_data).closePath))()

cdef void _pen_quadratic_to_func(hb_draw_funcs_t *dfuncs,
                                 void *draw_data,
                                 hb_draw_state_t *st,
                                 float c1_x,
                                 float c1_y,
                                 float to_x,
                                 float to_y,
                                 void *user_data) noexcept:
    (<object>((<_pen_methods*>draw_data).qCurveTo))((c1_x, c1_y), (to_x, to_y))

cdef void _pen_cubic_to_func(hb_draw_funcs_t *dfuncs,
                             void *draw_data,
                             hb_draw_state_t *st,
                             float c1_x,
                             float c1_y,
                             float c2_x,
                             float c2_y,
                             float to_x,
                             float to_y,
                             void *user_data) noexcept:
    (<object>((<_pen_methods*>draw_data).curveTo))((c1_x, c1_y), (c2_x, c2_y), (to_x, to_y))


cdef hb_position_t _glyph_h_advance_func(hb_font_t* font, void* font_data,
                                         hb_codepoint_t glyph,
                                         void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    return (<FontFuncs>py_font.funcs)._glyph_h_advance_func(
        py_font, glyph, <object>user_data)


cdef hb_position_t _glyph_v_advance_func(hb_font_t* font, void* font_data,
                                         hb_codepoint_t glyph,
                                         void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    return (<FontFuncs>py_font.funcs)._glyph_v_advance_func(
        py_font, glyph, <object>user_data)


cdef hb_bool_t _glyph_v_origin_func(hb_font_t* font, void* font_data,
                                    hb_codepoint_t glyph,
                                    hb_position_t* x, hb_position_t* y,
                                    void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    cdef hb_bool_t success
    cdef hb_position_t px
    cdef hb_position_t py
    success, px, py = (<FontFuncs>py_font.funcs)._glyph_v_origin_func(
        py_font, glyph, <object>user_data)
    x[0] = px
    y[0] = py
    return success


cdef hb_bool_t _glyph_name_func(hb_font_t *font, void *font_data,
                                hb_codepoint_t glyph,
                                char *name, unsigned int size,
                                void *user_data) noexcept:
    cdef Font py_font = <Font>font_data
    cdef bytes ret = (<FontFuncs>py_font.funcs)._glyph_name_func(
        py_font, glyph, <object>user_data).encode()
    name[0] = ret
    return 1


cdef hb_bool_t _nominal_glyph_func(hb_font_t* font, void* font_data,
                                   hb_codepoint_t unicode,
                                   hb_codepoint_t* glyph,
                                   void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    glyph[0] = (<FontFuncs>py_font.funcs)._nominal_glyph_func(
        py_font, unicode, <object>user_data)
    # If the glyph is .notdef, return false, else return true
    return int(glyph[0] != 0)

cdef hb_bool_t _variation_glyph_func(hb_font_t* font, void* font_data,
                                   hb_codepoint_t unicode,
                                   hb_codepoint_t variation_selector,
                                   hb_codepoint_t* glyph,
                                   void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    glyph[0] = (<FontFuncs>py_font.funcs)._variation_glyph_func(
        py_font, unicode, variation_selector, <object>user_data)
    # If the glyph is .notdef, return false, else return true
    return int(glyph[0] != 0)


cdef hb_bool_t _font_h_extents_func(hb_font_t* font, void* font_data,
                                    hb_font_extents_t *extents,
                                    void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    font_extents = (<FontFuncs>py_font.funcs)._font_h_extents_func(
        py_font, <object>user_data)
    if font_extents is not None:
        if font_extents.ascender is not None:
            extents.ascender = font_extents.ascender
        if font_extents.descender is not None:
            extents.descender = font_extents.descender
        if font_extents.line_gap is not None:
            extents.line_gap = font_extents.line_gap
        return 1
    return 0


cdef hb_bool_t _font_v_extents_func(hb_font_t* font, void* font_data,
                                    hb_font_extents_t *extents,
                                    void* user_data) noexcept:
    cdef Font py_font = <Font>font_data
    font_extents = (<FontFuncs>py_font.funcs)._font_v_extents_func(
        py_font, <object>user_data)
    if font_extents is not None:
        if font_extents.ascender is not None:
            extents.ascender = font_extents.ascender
        if font_extents.descender is not None:
            extents.descender = font_extents.descender
        if font_extents.line_gap is not None:
            extents.line_gap = font_extents.line_gap
        return 1
    return 0


cdef class FontFuncs:
    cdef hb_font_funcs_t* _hb_ffuncs
    cdef object _glyph_h_advance_func
    cdef object _glyph_v_advance_func
    cdef object _glyph_v_origin_func
    cdef object _glyph_name_func
    cdef object _nominal_glyph_func
    cdef object _variation_glyph_func
    cdef object _font_h_extents_func
    cdef object _font_v_extents_func

    def __cinit__(self):
        self._hb_ffuncs = hb_font_funcs_create()

    def __dealloc__(self):
        hb_font_funcs_destroy(self._hb_ffuncs)

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls) -> FontFuncs:
        cdef FontFuncs inst = cls()
        return inst

    def set_glyph_h_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # h_advance
                                 user_data: object = None):
        hb_font_funcs_set_glyph_h_advance_func(
            self._hb_ffuncs, _glyph_h_advance_func, <void*>user_data, NULL)
        self._glyph_h_advance_func = func

    def set_glyph_v_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # v_advance
                                 user_data: object = None):
        hb_font_funcs_set_glyph_v_advance_func(
            self._hb_ffuncs, _glyph_v_advance_func, <void*>user_data, NULL)
        self._glyph_v_advance_func = func

    def set_glyph_v_origin_func(self,
                                func: Callable[[
                                    Font,
                                    int,  # gid
                                    object,  # user_data
                                ], (int, int, int)],  # success, v_origin_x, v_origin_y
                                user_data: object = None):
        hb_font_funcs_set_glyph_v_origin_func(
            self._hb_ffuncs, _glyph_v_origin_func, <void*>user_data, NULL)
        self._glyph_v_origin_func = func

    def set_glyph_name_func(self,
                            func: Callable[[
                                Font,
                                int,  # gid
                                object,  # user_data
                            ], str],  # name
                            user_data: object = None):
        hb_font_funcs_set_glyph_name_func(
            self._hb_ffuncs, _glyph_name_func, <void*>user_data, NULL)
        self._glyph_name_func = func

    def set_nominal_glyph_func(self,
                               func: Callable[[
                                   Font,
                                   int,  # unicode
                                   object,  # user_data
                               ], int],  # gid
                               user_data: object = None):
        hb_font_funcs_set_nominal_glyph_func(
            self._hb_ffuncs, _nominal_glyph_func, <void*>user_data, NULL)
        self._nominal_glyph_func = func

    def set_variation_glyph_func(self,
                               func: Callable[[
                                   Font,
                                   int,  # unicode
                                   int,  # variation_selector
                                   object,  # user_data
                               ], int],  # gid
                               user_data: object = None):
        hb_font_funcs_set_variation_glyph_func(
            self._hb_ffuncs, _variation_glyph_func, <void*>user_data, NULL)
        self._variation_glyph_func = func

    def set_font_h_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object = None):
        hb_font_funcs_set_font_h_extents_func(
            self._hb_ffuncs, _font_h_extents_func, <void*>user_data, NULL)
        self._font_h_extents_func = func

    def set_font_v_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object = None):
        hb_font_funcs_set_font_v_extents_func(
            self._hb_ffuncs, _font_v_extents_func, <void*>user_data, NULL)
        self._font_v_extents_func = func
