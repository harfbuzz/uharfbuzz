class OTVarAxisFlags(IntFlag):
    """Flags for :class:`OTVarAxisInfo`.

    .. attribute:: HIDDEN
       :value: 0x01

       The axis should not be exposed directly in user interfaces.

    Wraps `hb_ot_var_axis_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-axis-flags-t>`_.
    """
    HIDDEN = HB_OT_VAR_AXIS_FLAG_HIDDEN


class OTVarAxisInfo(NamedTuple):
    """Data type for holding variation-axis values.

    Wraps `hb_ot_var_axis_info_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-axis-info-t>`_.
    """
    axis_index: int
    """Index of the axis in the variation-axis array."""
    tag: str
    """The tag identifying the design variation of the axis."""
    name_id: int
    """The ``name`` table Name ID that provides display names for the axis."""
    flags: OTVarAxisFlags
    """The :class:`OTVarAxisFlags` flags for the axis."""
    min_value: float
    """The minimum value on the variation axis that the font covers."""
    default_value: float
    """The position on the variation axis corresponding to the font's defaults."""
    max_value: float
    """The maximum value on the variation axis that the font covers."""


class OTVarNamedInstance(NamedTuple):
    """A named instance defined in the font's ``fvar`` table."""
    subfamily_name_id: int
    """The ``name`` table Name ID that provides display names for the
    "Subfamily name" defined for the given named instance."""
    postscript_name_id: int
    """The ``name`` table Name ID that provides display names for the
    "PostScript name" defined for the given named instance."""
    design_coords: List[float]
    """The design-space coordinates corresponding to the named instance."""


class Color(NamedTuple):
    """A color value. Colors are eight bits per channel RGB plus alpha
    transparency.

    Wraps `hb_color_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-color-t>`_.
    """
    red: int
    """Red channel value."""
    green: int
    """Green channel value."""
    blue: int
    """Blue channel value."""
    alpha: int
    """Alpha channel value."""

    def to_int(self) -> int:
        """Returns an :class:`int` representation of this :class:`Color`."""
        return HB_COLOR(self.blue, self.green, self.red, self.alpha)

    @staticmethod
    def from_int(value: int) -> Color:
        """Construct a :class:`Color` from an integer representation."""
        r = hb_color_get_red(value)
        g = hb_color_get_green(value)
        b = hb_color_get_blue(value)
        a = hb_color_get_alpha(value)
        return Color(r, g, b, a)


class OTColor(Color):
    """A :class:`Color` from a font's color palette, together with its name
    ID."""
    name_id: int | None


class OTColorPaletteFlags(IntFlag):
    """Flags that describe the properties of a color palette.

    .. attribute:: DEFAULT
       :value: 0x00

       Default indicating that there is nothing special to note about a
       color palette.

    .. attribute:: USABLE_WITH_LIGHT_BACKGROUND
       :value: 0x01

       Flag indicating that the color palette is appropriate to use when
       displaying the font on a light background such as white.

    .. attribute:: USABLE_WITH_DARK_BACKGROUND
       :value: 0x02

       Flag indicating that the color palette is appropriate to use when
       displaying the font on a dark background such as black.

    Wraps `hb_ot_color_palette_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-palette-flags-t>`_.
    """
    DEFAULT = HB_OT_COLOR_PALETTE_FLAG_DEFAULT
    USABLE_WITH_LIGHT_BACKGROUND = HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_LIGHT_BACKGROUND
    USABLE_WITH_DARK_BACKGROUND = HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_DARK_BACKGROUND


class OTColorPalette(NamedTuple):
    """A color palette from a font's ``CPAL`` table."""
    colors: List[OTColor]
    """The colors that make up the palette."""
    name_id: int | None
    """The ``name`` table Name ID that provides display names for the
    palette, or ``None`` if no name is associated."""
    flags: OTColorPaletteFlags
    """The :class:`OTColorPaletteFlags` flags for the palette."""


class OTColorLayer(NamedTuple):
    """A pair of glyph and color index.

    A color index of ``0xFFFF`` does not refer to a palette color, but
    indicates that the foreground color should be used.

    Wraps `hb_ot_color_layer_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-layer-t>`_.
    """
    glyph: int
    """The glyph ID of the layer."""
    color_index: int
    """The palette color index of the layer."""


class OTLayoutGlyphClass(IntEnum):
    """The GDEF classes defined for glyphs.

    .. attribute:: UNCLASSIFIED
       :value: 0

       Glyphs not matching the other classifications.

    .. attribute:: BASE_GLYPH
       :value: 1

       Spacing, single characters, capable of accepting marks.

    .. attribute:: LIGATURE
       :value: 2

       Glyphs that represent ligation of multiple characters.

    .. attribute:: MARK
       :value: 3

       Non-spacing, combining glyphs that represent marks.

    .. attribute:: COMPONENT
       :value: 4

       Spacing glyphs that represent part of a single character.

    Wraps `hb_ot_layout_glyph_class_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-glyph-class-t>`_.
    """
    UNCLASSIFIED = HB_OT_LAYOUT_GLYPH_CLASS_UNCLASSIFIED
    BASE_GLYPH = HB_OT_LAYOUT_GLYPH_CLASS_BASE_GLYPH
    LIGATURE = HB_OT_LAYOUT_GLYPH_CLASS_LIGATURE
    MARK = HB_OT_LAYOUT_GLYPH_CLASS_MARK
    COMPONENT = HB_OT_LAYOUT_GLYPH_CLASS_COMPONENT


cdef hb_user_data_key_t k


cdef hb_blob_t* _reference_table_func(
        hb_face_t* face, hb_tag_t tag, void* user_data) noexcept:
    cdef Face py_face = <object>(hb_face_get_user_data(face, &k))
    #
    cdef char cstr[5]
    hb_tag_to_string(tag, cstr)
    cstr[4] = b'\0'
    cdef bytes packed = cstr
    #
    cdef bytes table = py_face._reference_table_func(
        py_face, packed.decode(), <object>user_data)
    if table is None:
        return NULL
    return hb_blob_create(
        table, len(table), HB_MEMORY_MODE_READONLY, NULL, NULL)


cdef unsigned int _get_table_tags_func(
        const hb_face_t* face,
        unsigned int start_offset,
        unsigned int* table_count,
        hb_tag_t* table_tags,
        void* user_data) noexcept:
    cdef Face py_face = <object>(hb_face_get_user_data(<hb_face_t*>face, &k))
    cdef list tags = py_face._get_table_tags_func(py_face, <object>user_data)
    cdef unsigned int population = len(tags)
    cdef unsigned int end_offset
    cdef unsigned int i
    cdef bytes packed

    if table_count is NULL:
        return population

    if start_offset >= population:
        table_count[0] = 0
        return population

    end_offset = start_offset + table_count[0]
    if end_offset < start_offset:
        table_count[0] = 0
        return population
    if end_offset > population:
        end_offset = population

    table_count[0] = end_offset - start_offset
    for i in range(start_offset, end_offset):
        packed = tags[i].encode()
        table_tags[i - start_offset] = hb_tag_from_string(<char*>packed, -1)

    return population


class OTNameIdPredefined(IntEnum):
    """Predefined values for the OpenType ``name`` table Name ID.

    .. attribute:: COPYRIGHT

       Copyright notice.

    .. attribute:: FONT_FAMILY

       Font Family name.

    .. attribute:: FONT_SUBFAMILY

       Font Subfamily name.

    .. attribute:: UNIQUE_ID

       Unique font identifier.

    .. attribute:: FULL_NAME

       Full font name that reflects all family and relevant subfamily
       descriptors.

    .. attribute:: VERSION_STRING

       Version string.

    .. attribute:: POSTSCRIPT_NAME

       PostScript name for the font.

    .. attribute:: TRADEMARK

       Trademark.

    .. attribute:: MANUFACTURER

       Manufacturer name.

    .. attribute:: DESIGNER

       Designer.

    .. attribute:: DESCRIPTION

       Description.

    .. attribute:: VENDOR_URL

       URL of font vendor.

    .. attribute:: DESIGNER_URL

       URL of typeface designer.

    .. attribute:: LICENSE

       License description.

    .. attribute:: LICENSE_URL

       License information URL.

    .. attribute:: TYPOGRAPHIC_FAMILY

       Typographic family name.

    .. attribute:: TYPOGRAPHIC_SUBFAMILY

       Typographic subfamily name.

    .. attribute:: MAC_FULL_NAME

       Compatible full name (Macintosh only).

    .. attribute:: SAMPLE_TEXT

       Sample text.

    .. attribute:: CID_FINDFONT_NAME

       PostScript CID findfont name.

    .. attribute:: WWS_FAMILY

       WWS family name.

    .. attribute:: WWS_SUBFAMILY

       WWS subfamily name.

    .. attribute:: LIGHT_BACKGROUND

       Light background palette.

    .. attribute:: DARK_BACKGROUND

       Dark background palette.

    .. attribute:: VARIATIONS_PS_PREFIX

       Variations PostScript name prefix.

    .. attribute:: INVALID

       Value to represent a nonexistent name ID.

    Wraps `hb_ot_name_id_predefined_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-name.html#hb-ot-name-id-predefined-t>`_.
    """
    COPYRIGHT = HB_OT_NAME_ID_COPYRIGHT
    FONT_FAMILY = HB_OT_NAME_ID_FONT_FAMILY
    FONT_SUBFAMILY = HB_OT_NAME_ID_FONT_SUBFAMILY
    UNIQUE_ID = HB_OT_NAME_ID_UNIQUE_ID
    FULL_NAME = HB_OT_NAME_ID_FULL_NAME
    VERSION_STRING = HB_OT_NAME_ID_VERSION_STRING
    POSTSCRIPT_NAME = HB_OT_NAME_ID_POSTSCRIPT_NAME
    TRADEMARK = HB_OT_NAME_ID_TRADEMARK
    MANUFACTURER = HB_OT_NAME_ID_MANUFACTURER
    DESIGNER = HB_OT_NAME_ID_DESIGNER
    DESCRIPTION = HB_OT_NAME_ID_DESCRIPTION
    VENDOR_URL = HB_OT_NAME_ID_VENDOR_URL
    DESIGNER_URL = HB_OT_NAME_ID_DESIGNER_URL
    LICENSE = HB_OT_NAME_ID_LICENSE
    LICENSE_URL = HB_OT_NAME_ID_LICENSE_URL
    TYPOGRAPHIC_FAMILY = HB_OT_NAME_ID_TYPOGRAPHIC_FAMILY
    TYPOGRAPHIC_SUBFAMILY = HB_OT_NAME_ID_TYPOGRAPHIC_SUBFAMILY
    MAC_FULL_NAME = HB_OT_NAME_ID_MAC_FULL_NAME
    SAMPLE_TEXT = HB_OT_NAME_ID_SAMPLE_TEXT
    CID_FINDFONT_NAME = HB_OT_NAME_ID_CID_FINDFONT_NAME
    WWS_FAMILY = HB_OT_NAME_ID_WWS_FAMILY
    WWS_SUBFAMILY = HB_OT_NAME_ID_WWS_SUBFAMILY
    LIGHT_BACKGROUND = HB_OT_NAME_ID_LIGHT_BACKGROUND
    DARK_BACKGROUND = HB_OT_NAME_ID_DARK_BACKGROUND
    VARIATIONS_PS_PREFIX = HB_OT_NAME_ID_VARIATIONS_PS_PREFIX
    INVALID = HB_OT_NAME_ID_INVALID


class OTNameEntry(NamedTuple):
    """Structure representing a name ID in a particular language.

    Wraps `hb_ot_name_entry_t
    <https://harfbuzz.github.io/harfbuzz-hb-ot-name.html#hb-ot-name-entry-t>`_.
    """
    name_id: OTNameIdPredefined | int
    """The name ID, as an :class:`OTNameIdPredefined` value or a raw
    :class:`int` if it does not match any of the predefined ones."""
    language: str | None
    """The BCP 47 language tag, or ``None`` if the language cannot be
    determined."""


cdef class Face:
    """Font face objects.

    A font face is an object that represents a single face from within a
    font family. More precisely, a font face represents a single face in a
    binary font file. Font faces are typically built from a binary blob and
    a face index. Font faces are used to create fonts.

    The face index is used for blobs of file formats such as TTC and DFont
    that can contain more than one face. Face indices within such
    collections are zero-based.

    :param blob: A :class:`Blob` or :class:`bytes` containing the font data.
        If ``None``, the empty face is returned.
    :param index: The index of the face within the blob.

    Wraps `hb_face_t
    <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-t>`_.
    """

    cdef hb_face_t* _hb_face
    cdef object _reference_table_func
    cdef object _get_table_tags_func
    cdef Blob _blob

    def __cinit__(self, blob: Union[Blob, bytes] = None, int index=0):
        if blob is not None:
            if not isinstance(blob, Blob):
                self._blob = Blob(blob)
            else:
                self._blob = blob
            self._hb_face = hb_face_create(self._blob._hb_blob, index)
        else:
            self._hb_face = hb_face_get_empty()
            self._blob = None

    def __dealloc__(self):
        hb_face_destroy(self._hb_face)
        self._blob = None

    @staticmethod
    cdef Face from_ptr(hb_face_t* hb_face):
        """Create Face from a pointer, taking ownership of it."""

        cdef Face wrapper = Face.__new__(Face)
        wrapper._hb_face = hb_face
        return wrapper

    @classmethod
    @deprecated("Face()", since="0.10.0")
    def create(cls, blob: bytes, index: int = 0) -> Face:
        cdef Face inst = cls(blob, index)
        return inst

    @classmethod
    def create_for_tables(cls,
                          func: Callable[[
                              Face,
                              str,  # tag
                              object  # user_data
                          ], bytes],
                          user_data: object) -> Face:
        """Variant of the normal constructor, built for those cases where it
        is more convenient to provide data for individual tables instead of
        the whole font data. With the caveat that :attr:`table_tags` would
        not work with faces created this way. You can address that by
        calling the :meth:`set_get_table_tags_func` method and setting the
        appropriate callback.

        Creates a new face object from the specified ``user_data`` and
        ``func``.

        :param func: A callback that takes the :class:`Face`, a table tag,
            and the ``user_data`` and returns the table data as
            :class:`bytes`.
        :param user_data: User data passed to ``func`` on each call.

        Wraps `hb_face_create_for_tables()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-create-for-tables>`_.
        """
        cdef Face inst = cls(None)
        inst._hb_face = hb_face_create_for_tables(
            _reference_table_func, <void*>user_data, NULL)
        hb_face_set_user_data(inst._hb_face, &k, <void*>inst, NULL, 0)
        inst._reference_table_func = func
        return inst

    @property
    def count(self) -> int:
        """The number of faces in the blob.

        Wraps `hb_face_count()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-count>`_.
        """
        return hb_face_count(self._blob._hb_blob)

    @property
    def index(self) -> int:
        """The face-index of this face.

        Face indices within a collection are zero-based. Changing the index
        has no effect on the face itself, only on the value returned by this
        property.

        Wraps `hb_face_get_index()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-get-index>`_
        / `hb_face_set_index()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-set-index>`_.
        """
        return hb_face_get_index(self._hb_face)

    @index.setter
    def index(self, value: int):
        hb_face_set_index(self._hb_face, value)

    @property
    def upem(self) -> int:
        """The units-per-em (UPEM) value of the face.

        Typical UPEM values for fonts are 1000, or 2048, but any value in
        between 16 and 16,384 is allowed for OpenType fonts.

        Wraps `hb_face_get_upem()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-get-upem>`_
        / `hb_face_set_upem()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-set-upem>`_.
        """
        return hb_face_get_upem(self._hb_face)

    @upem.setter
    def upem(self, value: int):
        hb_face_set_upem(self._hb_face, value)

    @property
    def glyph_count(self) -> int:
        """The glyph-count value of the face.

        Wraps `hb_face_get_glyph_count()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-get-glyph-count>`_
        / `hb_face_set_glyph_count()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-set-glyph-count>`_.
        """
        return hb_face_get_glyph_count(self._hb_face)

    @glyph_count.setter
    def glyph_count(self, value: int):
        hb_face_set_glyph_count(self._hb_face, value)

    @property
    def blob(self) -> Blob:
        """A :class:`Blob` containing the binary data of the face.

        If referencing the face data is not possible, this property creates
        a blob out of individual table blobs if :attr:`table_tags` works
        with this face, otherwise it returns an empty blob.

        :type: Blob

        Wraps `hb_face_reference_blob()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-reference-blob>`_.
        """
        cdef hb_blob_t* blob = hb_face_reference_blob(self._hb_face)
        if blob is NULL:
            raise MemoryError()
        return Blob.from_ptr(blob)

    def reference_table(self, tag: str) -> Blob:
        """Fetches a reference to the specified table within the face.

        :param tag: The four-character tag of the table to query.

        :returns: A :class:`Blob` with the table data, or an empty blob if
            referencing table data is not possible.

        Wraps `hb_face_reference_table()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-reference-table>`_.
        """
        cdef bytes packed = tag.encode()
        cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
        cdef hb_blob_t* blob = hb_face_reference_table(self._hb_face, hb_tag)
        if blob is NULL:
            raise MemoryError()
        return Blob.from_ptr(blob)

    def set_get_table_tags_func(self,
                                func: Callable[[Face, object], List[str]],
                                user_data: object = None):
        """Sets the implementation function for retrieving the table tags
        of the face.

        :param func: A callback that takes the :class:`Face` and the
            ``user_data`` and returns the list of table tags as
            :class:`str`.
        :param user_data: User data passed to ``func`` on each call.

        Wraps `hb_face_set_get_table_tags_func()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-set-get-table-tags-func>`_.
        """
        self._get_table_tags_func = func
        hb_face_set_get_table_tags_func(
            self._hb_face, _get_table_tags_func, <void*>user_data, NULL)

    @property
    def table_tags(self) -> List[str]:
        """A list of all table tags for the face, if possible.

        :type: list[str]

        Wraps `hb_face_get_table_tags()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-get-table-tags>`_.
        """
        cdef unsigned int tag_count = STATIC_ARRAY_SIZE
        cdef hb_tag_t tags_array[STATIC_ARRAY_SIZE]
        cdef list tags = []
        cdef char cstr[5]
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while tag_count == STATIC_ARRAY_SIZE:
            hb_face_get_table_tags(
                self._hb_face, start_offset, &tag_count, tags_array)
            for i in range(tag_count):
                hb_tag_to_string(tags_array[i], cstr)
                cstr[4] = b'\0'
                packed = cstr
                tags.append(packed.decode())
            start_offset += tag_count
        return tags

    @property
    def unicodes (self) -> Set[int]:
        """All Unicode characters covered by the face.

        :type: Set

        Wraps `hb_face_collect_unicodes()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-collect-unicodes>`_.
        """
        s = Set()
        hb_face_collect_unicodes(self._hb_face, s._hb_set)
        return s

    @property
    def variation_selectors(self) -> Set[int]:
        """All Unicode "Variation Selector" characters covered by the face.

        :type: Set

        Wraps `hb_face_collect_variation_selectors()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-collect-variation-selectors>`_.
        """
        s = Set()
        hb_face_collect_variation_selectors(self._hb_face, s._hb_set)
        return s

    def variation_unicodes(self, variation_selector: int) -> Set[int]:
        """All Unicode characters for ``variation_selector`` covered by the
        face.

        :param variation_selector: The Variation Selector to query.

        :returns: The :class:`Set` of Unicode characters.

        Wraps `hb_face_collect_variation_unicodes()
        <https://harfbuzz.github.io/harfbuzz-hb-face.html#hb-face-collect-variation-unicodes>`_.
        """
        s = Set()
        hb_face_collect_variation_unicodes(self._hb_face, variation_selector, s._hb_set)
        return s

    # variations
    @property
    def has_var_data(self) -> bool:
        """Whether the face includes any OpenType variation data in the
        ``fvar`` table.

        Wraps `hb_ot_var_has_data()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-has-data>`_.
        """
        return hb_ot_var_has_data(self._hb_face)

    @property
    def axis_infos(self) -> List[OTVarAxisInfo]:
        """A list of all variation axes in the face.

        :type: list[OTVarAxisInfo]

        Wraps `hb_ot_var_get_axis_infos()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-get-axis-infos>`_.
        """
        cdef unsigned int axis_count = STATIC_ARRAY_SIZE
        cdef hb_ot_var_axis_info_t axis_array[STATIC_ARRAY_SIZE]
        cdef list infos = []
        cdef char cstr[5]
        cdef bytes packed
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while axis_count == STATIC_ARRAY_SIZE:
            hb_ot_var_get_axis_infos(
                self._hb_face, start_offset, &axis_count, axis_array)
            for i in range(axis_count):
                hb_tag_to_string(axis_array[i].tag, cstr)
                cstr[4] = b'\0'
                packed = cstr
                infos.append(
                    OTVarAxisInfo(
                        axis_index=axis_array[i].axis_index,
                        tag=packed.decode(),
                        name_id=axis_array[i].name_id,
                        flags=axis_array[i].flags,
                        min_value=axis_array[i].min_value,
                        default_value=axis_array[i].default_value,
                        max_value=axis_array[i].max_value
                    )
                )
            start_offset += axis_count
        return infos

    @property
    def named_instances(self) -> List[OTVarNamedInstance]:
        """The named instances defined in the face's ``fvar`` table.

        :type: list[OTVarNamedInstance]

        Wraps `hb_ot_var_get_named_instance_count()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-get-named-instance-count>`_,
        `hb_ot_var_named_instance_get_subfamily_name_id()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-named-instance-get-subfamily-name-id>`_,
        `hb_ot_var_named_instance_get_postscript_name_id()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-named-instance-get-postscript-name-id>`_,
        and `hb_ot_var_named_instance_get_design_coords()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-var.html#hb-ot-var-named-instance-get-design-coords>`_.
        """
        instances = []
        cdef hb_face_t* face = self._hb_face
        cdef unsigned int instance_count = hb_ot_var_get_named_instance_count(face)
        cdef unsigned int axis_count = hb_ot_var_get_axis_count(face)
        cdef hb_ot_name_id_t subfamily_name_id
        cdef hb_ot_name_id_t postscript_name_id
        cdef float* coords = <float*>malloc(axis_count * sizeof(float))
        cdef unsigned int coord_length
        for i in range(instance_count):
            coord_length = axis_count
            hb_ot_var_named_instance_get_design_coords(face, i, &coord_length, coords)
            instances.append(
                OTVarNamedInstance(
                    subfamily_name_id=hb_ot_var_named_instance_get_subfamily_name_id(face, i),
                    postscript_name_id=hb_ot_var_named_instance_get_postscript_name_id(face, i),
                    design_coords=[coords[j] for j in range(coord_length)],
                )
            )
        free(coords)
        return instances

    # math
    @property
    def has_math_data(self) -> bool:
        """Whether the face has a ``MATH`` table.

        Wraps `hb_ot_math_has_data()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-has-data>`_.
        """
        return hb_ot_math_has_data(self._hb_face)

    def is_glyph_extended_math_shape(self, glyph: int) -> bool:
        """Tests whether the given glyph index is an extended shape in the
        face.

        :param glyph: The glyph index to test.

        :returns: ``True`` if the glyph is an extended shape, ``False``
            otherwise.

        Wraps `hb_ot_math_is_glyph_extended_shape()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-math.html#hb-ot-math-is-glyph-extended-shape>`_.
        """
        return hb_ot_math_is_glyph_extended_shape(self._hb_face, glyph)

    # color
    @property
    def has_color_layers(self) -> bool:
        """Whether the face includes a ``COLR`` table with data according to
        COLRv0.

        Wraps `hb_ot_color_has_layers()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-has-layers>`_.
        """
        return hb_ot_color_has_layers(self._hb_face)

    def get_glyph_color_layers(self, glyph: int) -> List[OTColorLayer]:
        """Fetches a list of all color layers for the specified glyph index in
        the face.

        :param glyph: The glyph index to query.

        :returns: The array of layers found.

        Wraps `hb_ot_color_glyph_get_layers()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-glyph-get-layers>`_.
        """
        cdef list ret = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        cdef unsigned int layer_count = STATIC_ARRAY_SIZE
        cdef hb_ot_color_layer_t layers[STATIC_ARRAY_SIZE]
        while layer_count == STATIC_ARRAY_SIZE:
            hb_ot_color_glyph_get_layers(self._hb_face, glyph, start_offset, &layer_count, layers)
            for i in range(layer_count):
                ret.append(OTColorLayer(layers[i].glyph, layers[i].color_index))
            start_offset += layer_count
        return ret

    @property
    def has_color_palettes(self) -> bool:
        """Whether the face includes a ``CPAL`` color-palette table.

        Wraps `hb_ot_color_has_palettes()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-has-palettes>`_.
        """
        return hb_ot_color_has_palettes(self._hb_face)

    def get_color_palette(self, palette_index: int) -> OTColorPalette:
        """Fetches the color palette at the specified index.

        :param palette_index: The index of the color palette.

        :returns: An :class:`OTColorPalette` with the colors, name ID, and
            flags of the palette.

        Wraps `hb_ot_color_palette_get_colors()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-palette-get-colors>`_,
        `hb_ot_color_palette_get_name_id()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-palette-get-name-id>`_,
        and `hb_ot_color_palette_get_flags()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-palette-get-flags>`_.
        """
        cdef hb_face_t* face = self._hb_face
        cdef list colors = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        cdef unsigned int color_count = STATIC_ARRAY_SIZE
        cdef hb_color_t c_colors[STATIC_ARRAY_SIZE]
        while color_count == STATIC_ARRAY_SIZE:
            hb_ot_color_palette_get_colors(face, palette_index, start_offset, &color_count, c_colors)
            for i in range(color_count):
                colors.append(Color.from_int(c_colors[i]))

        return OTColorPalette(
            colors=colors,
            name_id=hb_ot_color_palette_get_name_id(face, palette_index),
            flags=OTColorPaletteFlags(hb_ot_color_palette_get_flags(face, palette_index))
        )

    @property
    def color_palettes(self) -> List[OTColorPalette]:
        """The face's color palettes.

        :type: list[OTColorPalette]

        Wraps `hb_ot_color_palette_get_count()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-palette-get-count>`_.
        """
        cdef list palettes = []
        cdef unsigned int palette_count = hb_ot_color_palette_get_count(self._hb_face)
        for i in range(palette_count):
            palettes.append(self.get_color_palette(i))
        return palettes

    def color_palette_color_get_name_id(self, color_index: int) -> int | None:
        """Fetches the ``name`` table Name ID that provides display names
        for the specified color in the face's ``CPAL`` color palette.

        :param color_index: The index of the color.

        :returns: The Name ID, or ``None`` if the color is not named.

        Wraps `hb_ot_color_palette_color_get_name_id()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-palette-color-get-name-id>`_.
        """
        cdef hb_ot_name_id_t name_id
        name_id =  hb_ot_color_palette_color_get_name_id(self._hb_face, color_index)
        if name_id == HB_OT_NAME_ID_INVALID:
            return None
        return name_id

    @property
    def has_color_paint(self) -> bool:
        """Whether the face includes a ``COLR`` table with data according to
        COLRv1.

        Wraps `hb_ot_color_has_paint()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-has-paint>`_.
        """
        return hb_ot_color_has_paint(self._hb_face)

    def glyph_has_color_paint(self, glyph: int) -> bool:
        """Tests whether the face includes COLRv1 paint data for ``glyph``.

        :param glyph: The glyph index to query.

        :returns: ``True`` if data is found, ``False`` otherwise.

        Wraps `hb_ot_color_glyph_has_paint()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-glyph-has-paint>`_.
        """
        return hb_ot_color_glyph_has_paint(self._hb_face, glyph)

    @property
    def has_color_svg(self) -> bool:
        """Whether the face includes any ``SVG`` glyph images.

        Wraps `hb_ot_color_has_svg()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-has-svg>`_.
        """
        return hb_ot_color_has_svg(self._hb_face)

    def get_glyph_color_svg(self, glyph: int) -> Blob:
        """Fetches the SVG document for a glyph. The blob may be either
        plain text or gzip-encoded.

        If the glyph has no SVG document, the singleton empty blob is
        returned.

        :param glyph: An SVG glyph index.

        :returns: A :class:`Blob` with the content of the SVG document.

        Wraps `hb_ot_color_glyph_reference_svg()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-glyph-reference-svg>`_.
        """
        cdef hb_blob_t* blob
        blob = hb_ot_color_glyph_reference_svg(self._hb_face, glyph)
        return Blob.from_ptr(blob)

    @property
    def has_color_png(self) -> bool:
        """Whether the face has PNG glyph images (either in ``CBDT`` or
        ``sbix`` tables).

        Wraps `hb_ot_color_has_png()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-color.html#hb-ot-color-has-png>`_.
        """
        return hb_ot_color_has_png(self._hb_face)

    # layout
    @property
    def has_layout_glyph_classes(self) -> bool:
        """Whether the face has any glyph classes defined in its GDEF table.

        Wraps `hb_ot_layout_has_glyph_classes()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-has-glyph-classes>`_.
        """
        return hb_ot_layout_has_glyph_classes(self._hb_face)

    def get_layout_glyph_class(self, glyph: int) -> OTLayoutGlyphClass:
        """Fetches the GDEF class of the requested glyph.

        :param glyph: The glyph code point to query.

        :returns: The :class:`OTLayoutGlyphClass` glyph class of the given
            code point in the GDEF table of the face.

        Wraps `hb_ot_layout_get_glyph_class()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-get-glyph-class>`_.
        """
        return OTLayoutGlyphClass(hb_ot_layout_get_glyph_class(self._hb_face, glyph))

    @property
    def has_layout_positioning(self) -> bool:
        """Whether the face includes any GPOS positioning.

        Wraps `hb_ot_layout_has_positioning()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-has-positioning>`_.
        """
        return hb_ot_layout_has_positioning(self._hb_face)

    @property
    def has_layout_substitution(self) -> bool:
        """Whether the face includes any GSUB substitutions.

        Wraps `hb_ot_layout_has_substitution()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-has-substitution>`_.
        """
        return hb_ot_layout_has_substitution(self._hb_face)

    def get_lookup_glyph_alternates(self, lookup_index: int, glyph: int) -> List[int]:
        """Fetches alternates of a glyph from a given GSUB lookup index.

        :param lookup_index: Index of the feature lookup to query.
        :param glyph: A glyph id.

        :returns: Alternate glyphs associated with the glyph id.

        Wraps `hb_ot_layout_lookup_get_glyph_alternates()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-lookup-get-glyph-alternates>`_.
        """
        cdef list alternates = []
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        cdef unsigned int alternate_count = STATIC_ARRAY_SIZE
        cdef hb_codepoint_t c_alternates[STATIC_ARRAY_SIZE]
        while alternate_count == STATIC_ARRAY_SIZE:
            hb_ot_layout_lookup_get_glyph_alternates(self._hb_face, lookup_index, glyph, start_offset,
                &alternate_count, c_alternates)
            for i in range(alternate_count):
                alternates.append(c_alternates[i])
            start_offset += alternate_count
        return alternates

    def get_language_feature_tags(self,
                                  tag: str,
                                  script_index: int = 0,
                                  language_index: int = 0xFFFF) -> List[str]:
        """Fetches a list of all features in the face's GSUB or GPOS table.

        :param tag: ``"GSUB"`` or ``"GPOS"``.
        :param script_index: The index of the requested script tag.
        :param language_index: The index of the requested language tag.

        :returns: The array of feature tags found for the query.

        Wraps `hb_ot_layout_language_get_feature_tags()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-language-get-feature-tags>`_.
        """
        cdef bytes packed = tag.encode()
        cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
        cdef unsigned int feature_count = STATIC_ARRAY_SIZE
        cdef hb_tag_t c_tags[STATIC_ARRAY_SIZE]
        cdef list tags = []
        cdef char cstr[5]
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while feature_count == STATIC_ARRAY_SIZE:
            hb_ot_layout_language_get_feature_tags(
                self._hb_face,
                hb_tag, script_index,
                language_index,
                start_offset,
                &feature_count,
                c_tags)
            for i in range(feature_count):
                hb_tag_to_string(c_tags[i], cstr)
                cstr[4] = b'\0'
                packed = cstr
                tags.append(packed.decode())
            start_offset += feature_count
        return tags

    def get_script_language_tags(self, tag: str, script_index: int = 0) -> List[str]:
        """Fetches a list of language tags in the face's GSUB or GPOS table,
        underneath the specified script index.

        :param tag: ``"GSUB"`` or ``"GPOS"``.
        :param script_index: The index of the requested script tag.

        :returns: Array of language tags found in the table.

        Wraps `hb_ot_layout_script_get_language_tags()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-script-get-language-tags>`_.
        """
        cdef bytes packed = tag.encode()
        cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
        cdef unsigned int language_count = STATIC_ARRAY_SIZE
        cdef hb_tag_t c_tags[STATIC_ARRAY_SIZE]
        cdef list tags = []
        cdef char cstr[5]
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while language_count == STATIC_ARRAY_SIZE:
            hb_ot_layout_script_get_language_tags(
                self._hb_face,
                hb_tag,
                script_index,
                start_offset,
                &language_count,
                c_tags)
            for i in range(language_count):
                hb_tag_to_string(c_tags[i], cstr)
                cstr[4] = b'\0'
                packed = cstr
                tags.append(packed.decode())
            start_offset += language_count
        return tags

    def get_table_script_tags(self, tag: str) -> List[str]:
        """Fetches a list of all scripts enumerated in the specified face's
        GSUB or GPOS table.

        :param tag: ``"GSUB"`` or ``"GPOS"``.

        :returns: The array of script tags found for the query.

        Wraps `hb_ot_layout_table_get_script_tags()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-layout-table-get-script-tags>`_.
        """
        cdef bytes packed = tag.encode()
        cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
        cdef unsigned int script_count = STATIC_ARRAY_SIZE
        cdef hb_tag_t c_tags[STATIC_ARRAY_SIZE]
        cdef list tags = []
        cdef char cstr[5]
        cdef unsigned int i
        cdef unsigned int start_offset = 0
        while script_count == STATIC_ARRAY_SIZE:
            hb_ot_layout_table_get_script_tags(
                self._hb_face,
                hb_tag,
                start_offset,
                &script_count,
                c_tags)
            for i in range(script_count):
                hb_tag_to_string(c_tags[i], cstr)
                cstr[4] = b'\0'
                packed = cstr
                tags.append(packed.decode())
            start_offset += script_count
        return tags

    def list_names(self) -> List[OTNameEntry]:
        """Enumerates all available name IDs and language combinations.

        :returns: Array of available name entries.

        Wraps `hb_ot_name_list_names()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-name.html#hb-ot-name-list-names>`_.
        """
        cdef list ret = []
        cdef unsigned int num_entries
        cdef const hb_ot_name_entry_t* entries
        cdef unsigned int i
        cdef const_char *cstr
        cdef bytes packed

        entries = hb_ot_name_list_names(self._hb_face, &num_entries)
        for i in range(num_entries):
            cstr = hb_language_to_string(entries[i].language)
            if cstr is NULL:
                language = None
            else:
                packed = cstr
                language = packed.decode()
            if entries[i].name_id in iter(OTNameIdPredefined):
                name_id = OTNameIdPredefined(entries[i].name_id)
            else:
                name_id = entries[i].name_id
            ret.append(OTNameEntry(name_id=name_id, language=language))
        return ret

    def get_name(self, name_id: OTNameIdPredefined | int, language: str | None = None) -> str | None:
        """Fetches a font name from the OpenType ``name`` table.

        :param name_id: The OpenType name identifier to fetch.
        :param language: The BCP 47 language tag to fetch the name for. If
            ``None``, English (``"en"``) is assumed.

        :returns: The name as a :class:`str`, or ``None`` if not found.

        Wraps `hb_ot_name_get_utf8()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-name.html#hb-ot-name-get-utf8>`_.
        """
        cdef bytes packed
        cdef hb_language_t lang
        cdef char *text
        cdef unsigned int length

        if language is None:
            lang = <hb_language_t>0  # HB_LANGUAGE_INVALID
        else:
            packed = language.encode()
            lang = hb_language_from_string(<char*>packed, -1)

        length = hb_ot_name_get_utf8(self._hb_face, name_id, lang, NULL, NULL)
        if length:
            length += 1  # for the null terminator
            text = <char*>malloc(length * sizeof(char))
            if text == NULL:
                raise MemoryError()
            try:
                hb_ot_name_get_utf8(self._hb_face, name_id, lang, &length, text)
                result = text[:length].decode("utf-8")
                return result
            finally:
                free(text)
        return None
