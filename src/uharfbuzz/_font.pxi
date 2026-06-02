class GlyphExtents(NamedTuple):
    """Glyph extent values, measured in font units.

    Note that ``height`` is negative, in coordinate systems that grow up.

    Wraps `hb_glyph_extents_t
    <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-glyph-extents-t>`_.
    """
    x_bearing: int
    """Distance from the x-origin to the left extremum of the glyph."""
    y_bearing: int
    """Distance from the top extremum of the glyph to the y-origin."""
    width: int
    """Distance from the left extremum of the glyph to the right extremum."""
    height: int
    """Distance from the top extremum of the glyph to the bottom extremum."""


class FontExtents(NamedTuple):
    """Font-wide extent values, measured in scaled units.

    Note that typically ``ascender`` is positive and ``descender`` negative,
    in coordinate systems that grow up.

    Wraps `hb_font_extents_t
    <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-extents-t>`_.
    """
    ascender: int
    """The height of typographic ascenders."""
    descender: int
    """The depth of typographic descenders."""
    line_gap: int
    """The suggested line-spacing gap."""


class OTMathConstant(IntEnum):
    """Math constants from the OpenType ``MATH`` table.

    Wraps `hb_ot_math_constant_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-constant-t>`_.
    """
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
    """Math kerning (cut-in) information for a glyph.

    Wraps `hb_ot_math_kern_entry_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-kern-entry-t>`_.
    """
    max_correction_height: int
    """The maximum height at which this entry should be used."""
    kern_value: int
    """The kern value of the entry."""


class OTMathKern(IntEnum):
    """The math kerning-table types defined for the four corners of a glyph.

    .. attribute:: TOP_RIGHT
       :value: 0

       The top right corner of the glyph.

    .. attribute:: TOP_LEFT
       :value: 1

       The top left corner of the glyph.

    .. attribute:: BOTTOM_RIGHT
       :value: 2

       The bottom right corner of the glyph.

    .. attribute:: BOTTOM_LEFT
       :value: 3

       The bottom left corner of the glyph.

    Wraps `hb_ot_math_kern_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-kern-t>`_.
    """
    TOP_RIGHT = HB_OT_MATH_KERN_TOP_RIGHT
    TOP_LEFT = HB_OT_MATH_KERN_TOP_LEFT
    BOTTOM_RIGHT = HB_OT_MATH_KERN_BOTTOM_RIGHT
    BOTTOM_LEFT = HB_OT_MATH_KERN_BOTTOM_LEFT


class OTMathGlyphVariant(NamedTuple):
    """Math-variant information for a glyph.

    Wraps `hb_ot_math_glyph_variant_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-glyph-variant-t>`_.
    """
    glyph: int
    """The glyph index of the variant."""
    advance: int
    """The advance width of the variant."""


class OTMathGlyphPartFlags(IntFlag):
    """Flags for math glyph parts.

    .. attribute:: EXTENDER
       :value: 0x01

       This is an extender glyph part that can be repeated to reach the
       desired length.

    Wraps `hb_ot_math_glyph_part_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-glyph-part-flags-t>`_.
    """
    EXTENDER = HB_OT_MATH_GLYPH_PART_FLAG_EXTENDER


class OTMathGlyphPart(NamedTuple):
    """Information for a "part" component of a math-variant glyph. Large
    variants for stretchable math glyphs (such as parentheses) can be
    constructed on the fly from parts.

    Wraps `hb_ot_math_glyph_part_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-glyph-part-t>`_.
    """
    glyph: int
    """The glyph index of the variant part."""
    start_connector_length: int
    """The length of the connector on the starting side of the variant part."""
    end_connector_length: int
    """The length of the connector on the ending side of the variant part."""
    full_advance: int
    """The total advance of the part."""
    flags: OTMathGlyphPartFlags
    """:class:`OTMathGlyphPartFlags` flags for the part."""


class OTMetricsTag(IntEnum):
    """Metric tags corresponding to `MVAR Value Tags
    <https://docs.microsoft.com/en-us/typography/opentype/spec/mvar#value-tags>`_.

    Wraps `hb_ot_metrics_tag_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-metrics.html#hb-ot-metrics-tag-t>`_.
    """
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
    """Style tags defined by `OpenType Design-Variation Axis Tag Registry
    <https://docs.microsoft.com/en-us/typography/opentype/spec/dvaraxisreg>`_.

    .. attribute:: ITALIC

       Used to vary between non-italic and italic. A value of 0 can be
       interpreted as "Roman" (non-italic); a value of 1 can be interpreted
       as (fully) italic.

    .. attribute:: OPTICAL_SIZE

       Used to vary design to suit different text sizes. Non-zero. Values
       can be interpreted as text size, in points.

    .. attribute:: SLANT_ANGLE

       Used to vary between upright and slanted text. Values must be
       greater than -90 and less than +90. Values can be interpreted as
       the angle, in counter-clockwise degrees, of oblique slant from
       whatever the designer considers to be upright for that font design.
       Typical right-leaning Italic fonts have a negative slant angle
       (typically around -12).

    .. attribute:: SLANT_RATIO

       Same as :attr:`SLANT_ANGLE` expressed as a ratio. Typical
       right-leaning Italic fonts have a positive slant ratio (typically
       around 0.2).

    .. attribute:: WIDTH

       Used to vary width of text from narrower to wider. Non-zero. Values
       can be interpreted as a percentage of whatever the font designer
       considers "normal width" for that font design.

    .. attribute:: WEIGHT

       Used to vary stroke thicknesses or other design details to give
       variation from lighter to blacker. Values can be interpreted in
       direct comparison to values for usWeightClass in the OS/2 table, or
       the CSS font-weight property.

    Wraps `hb_style_tag_t
    <https://harfbuzz.github.io/harfbuzz-hb-style.html#hb-style-tag-t>`_.
    """
    ITALIC = HB_STYLE_TAG_ITALIC
    OPTICAL_SIZE = HB_STYLE_TAG_OPTICAL_SIZE
    SLANT_ANGLE = HB_STYLE_TAG_SLANT_ANGLE
    SLANT_RATIO = HB_STYLE_TAG_SLANT_RATIO
    WIDTH = HB_STYLE_TAG_WIDTH
    WEIGHT = HB_STYLE_TAG_WEIGHT

cdef class Font:
    """Font objects.

    A font object represents a font face at a specific size and with certain
    other parameters (pixels-per-em, points-per-em, variation settings)
    specified. Font objects are created from font face objects, and are used
    as input to :func:`shape`, among other things.

    Client programs can optionally pass in their own functions that
    implement the basic, lower-level queries of font objects. This set of
    font functions is defined by the virtual methods in :class:`FontFuncs`.

    :param face_or_font: A :class:`Face` to create a font from, or another
        :class:`Font` to create a sub-font from. If ``None``, the empty font
        is returned.

    Wraps `hb_font_t
    <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-t>`_.
    """

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
        """Create Font from a pointer, taking ownership of it."""

        cdef Font wrapper = Font.__new__(Font)
        wrapper._hb_font = hb_font
        wrapper._face = Face.from_ptr(hb_face_reference(hb_font_get_face(hb_font)))
        return wrapper

    @classmethod
    @deprecated("Font()", since="0.10.0")
    def create(cls, face: Face) -> Font:
        cdef Font inst = cls(face)
        return inst

    @property
    def face(self) -> Face:
        """The :class:`Face` associated with this font.

        :type: Face

        Wraps `hb_font_get_face()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-face>`_.
        """
        return self._face

    @property
    def funcs(self) -> FontFuncs:
        """The font-functions structure attached to this font.

        Assigning to this property replaces the font-functions structure
        attached to the font.

        :type: FontFuncs

        Wraps `hb_font_set_funcs()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-funcs>`_.
        """
        return self._ffuncs

    @funcs.setter
    def funcs(self, ffuncs: FontFuncs):
        hb_font_set_funcs(
            self._hb_font, ffuncs._hb_ffuncs, <void*>self, NULL)
        self._ffuncs = ffuncs

    @property
    def scale(self) -> Tuple[int, int]:
        """The horizontal and vertical scale of the font, as a
        ``(x_scale, y_scale)`` tuple.

        The font scale is a number related to, but not the same as, font
        size. Typically the client establishes a scale factor to be used
        between the two. For example, 64, or 256, which would be the
        fractional-precision part of the font scale. This is necessary
        because position values are integer types and you need to leave
        room for fractional values in there.

        For example, to set the font size to 20, with 64 levels of
        fractional precision you would call
        ``font.scale = (20 * 64, 20 * 64)``.

        In the example above, even what font size 20 means is up to
        you. It might be 20 pixels, or 20 points, or 20 millimeters.
        HarfBuzz does not care about that. You can set the point size of
        the font using :attr:`ptem`, and the pixel size using
        :attr:`ppem`.

        The choice of scale is yours but needs to be consistent between
        what you set here, and what you expect out of position values as
        well has draw / paint API output values.

        Fonts default to a scale equal to the UPEM value of their face.
        A font with this setting is sometimes called an "unscaled" font.

        Wraps `hb_font_get_scale()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-scale>`_
        / `hb_font_set_scale()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-scale>`_.
        """
        cdef int x, y
        hb_font_get_scale(self._hb_font, &x, &y)
        return (x, y)

    @scale.setter
    def scale(self, value: Tuple[int, int]):
        x, y = value
        hb_font_set_scale(self._hb_font, x, y)

    @property
    def ppem(self) -> Tuple[int, int]:
        """The horizontal and vertical pixels-per-em (PPEM) of the font, as
        a ``(x_ppem, y_ppem)`` tuple.

        These values are used for pixel-size-specific adjustment to shaping
        and draw results, though for the most part they are unused and can
        be left unset.

        Wraps `hb_font_get_ppem()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-ppem>`_
        / `hb_font_set_ppem()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-ppem>`_.
        """
        cdef unsigned int x, y
        hb_font_get_ppem(self._hb_font, &x, &y)
        return (x, y)

    @ppem.setter
    def ppem(self, value: Tuple[int, int]):
        x, y = value
        hb_font_set_ppem(self._hb_font, x, y)

    @property
    def ptem(self) -> float:
        """The "point size" of the font. Set to zero to unset. Used in
        CoreText to implement optical sizing.

        Note: there are 72 points in an inch.

        Wraps `hb_font_get_ptem()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-ptem>`_
        / `hb_font_set_ptem()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-ptem>`_.
        """
        return hb_font_get_ptem(self._hb_font)

    @ptem.setter
    def ptem(self, value: float):
        hb_font_set_ptem(self._hb_font, value)

    @property
    def synthetic_slant(self) -> float:
        """The "synthetic slant" of the font. By default is zero. Synthetic
        slant is the graphical skew applied to the font at rendering time.

        HarfBuzz needs to know this value to adjust shaping results,
        metrics, and style values to match the slanted rendering.

        The slant value is a ratio. For example, a 20% slant would be
        represented as a 0.2 value.

        Wraps `hb_font_get_synthetic_slant()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-synthetic-slant>`_
        / `hb_font_set_synthetic_slant()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-synthetic-slant>`_.
        """
        return hb_font_get_synthetic_slant(self._hb_font)

    @synthetic_slant.setter
    def synthetic_slant(self, value: float):
        hb_font_set_synthetic_slant(self._hb_font, value)

    @property
    def synthetic_bold(self) -> Tuple[float, float, bool]:
        """The "synthetic boldness" of the font, as a tuple ``(x_embolden,
        y_embolden, in_place)``.

        Positive values for ``x_embolden`` / ``y_embolden`` make a font
        bolder, negative values thinner. Typical values are in the 0.01 to
        0.05 range. The default value is zero.

        If ``in_place`` is ``False``, then glyph advance-widths are also
        adjusted, otherwise they are not. The in-place mode is useful for
        simulating font grading.

        The setter accepts a :class:`float` (applied to both axes,
        ``in_place=False``), a 1-tuple, a 2-tuple, or a 3-tuple.

        Wraps `hb_font_get_synthetic_bold()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-synthetic-bold>`_
        / `hb_font_set_synthetic_bold()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-synthetic-bold>`_.
        """
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
        """The currently-set named-instance index of the font.

        Wraps `hb_font_get_var_named_instance()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-var-named-instance>`_
        / `hb_font_set_var_named_instance()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-var-named-instance>`_.
        """
        return hb_font_get_var_named_instance(self._hb_font)

    @var_named_instance.setter
    def var_named_instance(self, value: int):
        hb_font_set_var_named_instance(self._hb_font, value)

    def set_variations(self, variations: Dict[str, float]):
        """Applies a list of font-variation settings to the font.

        Note that this overrides all existing variations set on the font.
        Axes not included in ``variations`` will be effectively set to
        their default values.

        :param variations: A mapping of axis-tag string to value.

        Wraps `hb_font_set_variations()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-variations>`_.
        """
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
        """Change the value of one variation axis on the font.

        Note: this method is expensive to be called repeatedly. If you want
        to set multiple variation axes at the same time, use
        :meth:`set_variations` instead.

        :param name: The axis tag.
        :param value: The value of the variation axis.

        Wraps `hb_font_set_variation()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-variation>`_.
        """
        packed = name.encode()
        cdef hb_tag_t tag = hb_tag_from_string(packed, -1)
        hb_font_set_variation(self._hb_font, tag, value)

    def get_glyph_name(self, gid: int) -> str | None:
        """Fetches the glyph-name string for a glyph ID in the font.

        According to the OpenType specification, glyph names are limited to
        63 characters and can only contain (a subset of) ASCII.

        :param gid: The glyph ID to query.

        :returns: Name string retrieved for the glyph ID, or ``None`` if not
            found.

        Wraps `hb_font_get_glyph_name()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-name>`_.
        """
        cdef char name[64]
        cdef bytes packed
        success = hb_font_get_glyph_name(self._hb_font, gid, name, 64)
        if success:
            packed = name
            return packed.decode()
        else:
            return None

    def get_glyph_from_name(self, name: str) -> int | None:
        """Fetches the glyph ID that corresponds to a name string in the
        font.

        :param name: The name to query.

        :returns: The glyph ID retrieved, or ``None`` if not found.

        Wraps `hb_font_get_glyph_from_name()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-from-name>`_.
        """
        cdef hb_codepoint_t gid
        cdef bytes packed
        packed = name.encode()
        success = hb_font_get_glyph_from_name(self._hb_font, <char*>packed, len(packed), &gid)
        return gid if success else None

    def get_glyph_extents(self, gid: int) -> GlyphExtents:
        """Fetches the :class:`GlyphExtents` data for a glyph ID.

        :param gid: The glyph ID to query.

        :returns: The :class:`GlyphExtents` retrieved, or ``None`` if not
            found.

        Wraps `hb_font_get_glyph_extents()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-extents>`_.
        """
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
        """Fetches the advance for a glyph ID, for horizontal text segments.

        Wraps `hb_font_get_glyph_h_advance()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-h-advance>`_.
        """
        return hb_font_get_glyph_h_advance(self._hb_font, gid)

    def get_glyph_v_advance(self, gid: int) -> int:
        """Fetches the advance for a glyph ID, for vertical text segments.

        Wraps `hb_font_get_glyph_v_advance()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-v-advance>`_.
        """
        return hb_font_get_glyph_v_advance(self._hb_font, gid)

    def get_glyph_h_origin(self, gid: int) -> Tuple[int, int] | None:
        """Fetches the (X, Y) coordinates of the origin for a glyph ID, for
        horizontal text segments.

        :returns: The (X, Y) coordinates of the origin, or ``None`` if not
            found.

        Wraps `hb_font_get_glyph_h_origin()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-h-origin>`_.
        """
        cdef hb_position_t x, y
        success = hb_font_get_glyph_h_origin(self._hb_font, gid, &x, &y)
        return (x, y) if success else None

    def get_glyph_v_origin(self, gid: int) -> Tuple[int, int] | None:
        """Fetches the (X, Y) coordinates of the origin for a glyph ID, for
        vertical text segments.

        :returns: The (X, Y) coordinates of the origin, or ``None`` if not
            found.

        Wraps `hb_font_get_glyph_v_origin()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-glyph-v-origin>`_.
        """
        cdef hb_position_t x, y
        success = hb_font_get_glyph_v_origin(self._hb_font, gid, &x, &y)
        return (x, y) if success else None

    def get_font_extents(self, direction: str) -> FontExtents:
        """Fetches the extents for a font in a text segment of the
        specified direction.

        Calls the appropriate direction-specific variant (horizontal or
        vertical) depending on the value of ``direction``.

        :param direction: The direction of the text segment.

        :returns: The :class:`FontExtents` retrieved.

        Wraps `hb_font_get_extents_for_direction()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-extents-for-direction>`_.
        """
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
        """Fetches the glyph ID for a Unicode code point when followed by
        the specified variation-selector code point.

        :returns: The glyph ID retrieved, or ``None`` if not found.

        Wraps `hb_font_get_variation_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-variation-glyph>`_.
        """
        cdef hb_codepoint_t gid
        success = hb_font_get_variation_glyph(self._hb_font, unicode, variation_selector, &gid)
        return gid if success else None

    def get_nominal_glyph(self, unicode: int) -> int | None:
        """Fetches the nominal glyph ID for a Unicode code point.

        :returns: The glyph ID retrieved, or ``None`` if not found.

        Wraps `hb_font_get_nominal_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-nominal-glyph>`_.
        """
        cdef hb_codepoint_t gid
        success = hb_font_get_nominal_glyph(self._hb_font, unicode, &gid)
        return gid if success else None

    def get_var_coords_normalized(self) -> List[float]:
        """Fetches the list of normalized variation coordinates currently
        set on the font.

        :returns: The coordinates array.

        Wraps `hb_font_get_var_coords_normalized()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-var-coords-normalized>`_.
        """
        cdef unsigned int length
        cdef const int *coords
        coords = hb_font_get_var_coords_normalized(self._hb_font, &length)
        # Convert from 2.14 fixed to float: divide by 1 << 14
        return [coords[i] / 0x4000 for i in range(length)]

    def set_var_coords_normalized(self, coords: List[float]):
        """Applies a list of variation coordinates (in normalized units) to
        the font.

        Note that this overrides all existing variations set on the font.
        Axes not included in ``coords`` will be effectively set to their
        default values.

        Wraps `hb_font_set_var_coords_normalized()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-var-coords-normalized>`_.
        """
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
        """Fetches the list of variation coordinates (in design-space
        units) currently set on the font.

        Wraps `hb_font_get_var_coords_design()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-get-var-coords-design>`_.
        """
        cdef unsigned int length
        cdef const float *coords
        coords = hb_font_get_var_coords_design(self._hb_font, &length)
        return [coords[i] for i in range(length)]

    def set_var_coords_design(self, coords: List[float]):
        """Applies a list of variation coordinates (in design-space units)
        to the font.

        Note that this overrides all existing variations set on the font.
        Axes not included in ``coords`` will be effectively set to their
        default values.

        Wraps `hb_font_set_var_coords_design()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-set-var-coords-design>`_.
        """
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
        """Fetches the name of the specified glyph ID.

        If the glyph ID has no name, a string of the form ``gidDDD`` is
        generated, with ``DDD`` being the glyph ID.

        Wraps `hb_font_glyph_to_string()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-glyph-to-string>`_.
        """
        cdef char name[64]
        cdef bytes packed
        hb_font_glyph_to_string(self._hb_font, gid, name, 64)
        packed = name
        return packed.decode()

    def glyph_from_string(self, string: str) -> int:
        """Fetches the glyph ID that matches the specified string.

        Strings of the format ``gidDDD`` or ``uniUUUU`` are parsed
        automatically.

        :returns: The glyph ID corresponding to the string requested, or
            ``None`` if not found.

        Wraps `hb_font_glyph_from_string()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-glyph-from-string>`_.
        """
        cdef hb_codepoint_t gid
        cdef bytes packed
        packed = string.encode()
        success = hb_font_glyph_from_string(self._hb_font, <char*>packed, len(packed), &gid)
        return gid if success else None

    def draw_glyph(self, gid: int, draw_funcs: DrawFuncs, draw_state: object = None):
        """Draws the outline that corresponds to a glyph in the font.

        The outline is returned by way of calls to the callbacks of the
        ``draw_funcs`` object, with ``draw_state`` passed to them.

        :param gid: The glyph ID.
        :param draw_funcs: The :class:`DrawFuncs` to draw to.
        :param draw_state: User data to pass to the draw callbacks.

        Wraps `hb_font_draw_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-draw-glyph>`_.
        """
        cdef void *draw_state_p = <void *>draw_state
        if PyCapsule_IsValid(draw_state, NULL):
            draw_state_p = <void *>PyCapsule_GetPointer(draw_state, NULL)
        hb_font_draw_glyph(self._hb_font, gid, draw_funcs._hb_drawfuncs, draw_state_p);

    def paint_glyph(self, gid: int,
                    paint_funcs: PaintFuncs,
                    paint_state: object = None,
                    palette_index: int = 0,
                    foreground: Color | None = None):
        """Paints the glyph. If painting a color glyph failed, it will fall
        back to painting an outline monochrome glyph.

        The painting instructions are returned by way of calls to the
        callbacks of the ``paint_funcs`` object, with ``paint_state`` passed
        to them.

        :param gid: The glyph ID.
        :param paint_funcs: The :class:`PaintFuncs` to paint with.
        :param paint_state: User data to pass to the paint callbacks.
        :param palette_index: The index of the font's color palette to use.
        :param foreground: The foreground color, unpremultiplied.

        Wraps `hb_font_paint_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-paint-glyph>`_.
        """
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
        """Draws the outline of a glyph using a fontTools-style pen.

        :param gid: The glyph ID.
        :param pen: An object with ``moveTo``, ``lineTo``, ``curveTo``,
            ``qCurveTo``, and ``closePath`` methods.
        """
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
        """Fetches the specified math constant.

        For most constants, the value returned is a position. However, if
        the requested constant is
        :attr:`OTMathConstant.SCRIPT_PERCENT_SCALE_DOWN`,
        :attr:`OTMathConstant.SCRIPT_SCRIPT_PERCENT_SCALE_DOWN` or
        :attr:`OTMathConstant.RADICAL_DEGREE_BOTTOM_RAISE_PERCENT`, then
        the return value is an integer between 0 and 100 representing that
        percentage.

        :raises ValueError: If ``constant`` is not a valid
            :class:`OTMathConstant`.

        Wraps `hb_ot_math_get_constant()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-constant>`_.
        """
        if constant >= len(OTMathConstant):
            raise ValueError("invalid constant")
        return hb_ot_math_get_constant(self._hb_font, constant)

    def get_math_glyph_italics_correction(self, glyph: int) -> int:
        """Fetches an italics-correction value (if one exists) for the
        specified glyph index.

        Wraps `hb_ot_math_get_glyph_italics_correction()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-glyph-italics-correction>`_.
        """
        return hb_ot_math_get_glyph_italics_correction(self._hb_font, glyph)

    def get_math_glyph_top_accent_attachment(self, glyph: int) -> int:
        """Fetches a top-accent-attachment value (if one exists) for the
        specified glyph index.

        Wraps `hb_ot_math_get_glyph_top_accent_attachment()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-glyph-top-accent-attachment>`_.
        """
        return hb_ot_math_get_glyph_top_accent_attachment(self._hb_font, glyph)

    def get_math_min_connector_overlap(self, direction: str) -> int:
        """Fetches the MathVariants table for the font and returns the
        minimum overlap of connecting glyphs that are required to draw a
        glyph assembly in the specified direction.

        Wraps `hb_ot_math_get_min_connector_overlap()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-min-connector-overlap>`_.
        """
        cdef bytes packed = direction.encode()
        cdef char* cstr = packed
        cdef hb_direction_t hb_direction = hb_direction_from_string(cstr, -1)
        return hb_ot_math_get_min_connector_overlap(self._hb_font, hb_direction)

    def get_math_glyph_kerning(self, glyph: int, kern: OTMathKern, correction_height: int) -> int:
        """Fetches the math kerning (cut-ins) value for the specified font,
        glyph index, and ``kern``.

        :raises ValueError: If ``kern`` is not a valid :class:`OTMathKern`.

        Wraps `hb_ot_math_get_glyph_kerning()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-glyph-kerning>`_.
        """
        if kern >= len(OTMathKern):
            raise ValueError("invalid kern")
        return hb_ot_math_get_glyph_kerning(self._hb_font, glyph, kern, correction_height)

    def get_math_glyph_kernings(self, glyph: int, kern: OTMathKern) -> List[OTMathKernEntry]:
        """Fetches the raw MathKern (cut-in) data for the specified font,
        glyph index, and ``kern``.

        :raises ValueError: If ``kern`` is not a valid :class:`OTMathKern`.

        Wraps `hb_ot_math_get_glyph_kernings()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-glyph-kernings>`_.
        """
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
        """Fetches the MathGlyphConstruction for the specified font, glyph
        index, and direction.

        Wraps `hb_ot_math_get_glyph_variants()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-glyph-variants>`_.
        """
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
        """Fetches the GlyphAssembly for the specified font, glyph index,
        and direction.

        :returns: A tuple ``(parts, italics_correction)`` of the glyph
            parts returned and the italics correction of the glyph
            assembly.

        Wraps `hb_ot_math_get_glyph_assembly()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-get-glyph-assembly>`_.
        """
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
    def get_metric_position(self, tag: OTMetricsTag) -> int | None:
        """Fetches metrics value corresponding to ``tag`` from the font.

        :returns: The metrics value from the font, or ``None`` if not
            found.

        Wraps `hb_ot_metrics_get_position()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-metrics.html#hb-ot-metrics-get-position>`_.
        """
        cdef hb_position_t position
        if hb_ot_metrics_get_position(self._hb_font, tag, &position):
            return position
        return None

    def get_metric_position_with_fallback(self, tag: OTMetricsTag) -> int:
        """Fetches metrics value corresponding to ``tag`` from the font, and
        synthesizes a value if the value is missing in the font.

        Wraps `hb_ot_metrics_get_position_with_fallback()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-metrics.html#hb-ot-metrics-get-position-with-fallback>`_.
        """
        cdef hb_position_t position
        hb_ot_metrics_get_position_with_fallback(self._hb_font, tag, &position)
        return position

    def get_metric_variation(self, tag: OTMetricsTag) -> float:
        """Fetches metrics value corresponding to ``tag`` from the font with
        the current font variation settings applied.

        Wraps `hb_ot_metrics_get_variation()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-metrics.html#hb-ot-metrics-get-variation>`_.
        """
        return hb_ot_metrics_get_variation(self._hb_font, tag)

    def get_metric_x_variation(self, tag: OTMetricsTag) -> int:
        """Fetches horizontal metrics value corresponding to ``tag`` from
        the font with the current font variation settings applied.

        Wraps `hb_ot_metrics_get_x_variation()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-metrics.html#hb-ot-metrics-get-x-variation>`_.
        """
        return hb_ot_metrics_get_x_variation(self._hb_font, tag)

    def get_metric_y_variation(self, tag: OTMetricsTag) -> int:
        """Fetches vertical metrics value corresponding to ``tag`` from the
        font with the current font variation settings applied.

        Wraps `hb_ot_metrics_get_y_variation()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-metrics.html#hb-ot-metrics-get-y-variation>`_.
        """
        return hb_ot_metrics_get_y_variation(self._hb_font, tag)

    # color
    def get_glyph_color_png(self, glyph: int) -> Blob:
        """Fetches the PNG image for a glyph. This function takes a font
        object, not a face object, as input. To get an optimally sized PNG
        blob, the PPEM values must be set on the font object. If PPEM is
        unset, the blob returned will be the largest PNG available.

        If the glyph has no PNG image, the singleton empty blob is returned.

        Wraps `hb_ot_color_glyph_reference_png()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-glyph-reference-png>`_.
        """
        cdef hb_blob_t* blob
        blob = hb_ot_color_glyph_reference_png(self._hb_font, glyph)
        return Blob.from_ptr(blob)

    #layout
    def get_layout_baseline(self,
                           baseline_tag: str,
                           direction: str,
                           script_tag: str,
                           language_tag: str) -> int:
        """Fetches a baseline value from the font.

        :param baseline_tag: A baseline tag.
        :param direction: Text direction.
        :param script_tag: Script tag.
        :param language_tag: Language tag, currently unused.

        :returns: The baseline value if found, or ``None`` otherwise.

        :raises ValueError: If ``baseline_tag`` is not recognized.

        Wraps `hb_ot_layout_get_baseline()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-get-baseline>`_.
        """
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
        """Searches variation axes of the font for a specific axis first; if
        not set, first tries to get default style values in the ``STAT``
        table, then tries to polyfill from different tables of the font.

        :returns: Corresponding axis or default value to a style tag.

        Wraps `hb_style_get_value()
        <https://harfbuzz.github.io/harfbuzz-hb-style.html#hb-style-get-value>`_.
        """
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
    """The virtual methods that define the font functions used by a
    :class:`Font` for the basic, lower-level queries against a font object.

    Wraps `hb_font_funcs_t
    <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-t>`_.
    """
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

    @classmethod
    @deprecated("FontFuncs()", since="0.10.0")
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
        """Sets the implementation function for the horizontal-glyph-advance
        callback.

        Wraps `hb_font_funcs_set_glyph_h_advance_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-glyph-h-advance-func>`_.
        """
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
        """Sets the implementation function for the vertical-glyph-advance
        callback.

        Wraps `hb_font_funcs_set_glyph_v_advance_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-glyph-v-advance-func>`_.
        """
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
        """Sets the implementation function for the vertical-glyph-origin
        callback. The callback must return a ``(success, x, y)`` tuple.

        Wraps `hb_font_funcs_set_glyph_v_origin_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-glyph-v-origin-func>`_.
        """
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
        """Sets the implementation function for the glyph-name callback.

        Wraps `hb_font_funcs_set_glyph_name_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-glyph-name-func>`_.
        """
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
        """Sets the implementation function for the nominal-glyph callback.

        Wraps `hb_font_funcs_set_nominal_glyph_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-nominal-glyph-func>`_.
        """
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
        """Sets the implementation function for the variation-glyph
        callback.

        Wraps `hb_font_funcs_set_variation_glyph_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-variation-glyph-func>`_.
        """
        hb_font_funcs_set_variation_glyph_func(
            self._hb_ffuncs, _variation_glyph_func, <void*>user_data, NULL)
        self._variation_glyph_func = func

    def set_font_h_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object = None):
        """Sets the implementation function for the horizontal-font-extents
        callback.

        Wraps `hb_font_funcs_set_font_h_extents_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-font-h-extents-func>`_.
        """
        hb_font_funcs_set_font_h_extents_func(
            self._hb_ffuncs, _font_h_extents_func, <void*>user_data, NULL)
        self._font_h_extents_func = func

    def set_font_v_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object = None):
        """Sets the implementation function for the vertical-font-extents
        callback.

        Wraps `hb_font_funcs_set_font_v_extents_func()
        <https://harfbuzz.github.io/harfbuzz-hb-font.html#hb-font-funcs-set-font-v-extents-func>`_.
        """
        hb_font_funcs_set_font_v_extents_func(
            self._hb_ffuncs, _font_v_extents_func, <void*>user_data, NULL)
        self._font_v_extents_func = func
