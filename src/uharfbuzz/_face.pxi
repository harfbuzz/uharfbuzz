class OTVarAxisFlags(IntFlag):
    HIDDEN = HB_OT_VAR_AXIS_FLAG_HIDDEN


class OTVarAxisInfo(NamedTuple):
    axis_index: int
    tag: str
    name_id: int
    flags: OTVarAxisFlags
    min_value: float
    default_value: float
    max_value: float


class OTVarNamedInstance(NamedTuple):
    subfamily_name_id: int
    postscript_name_id: int
    design_coords: List[float]


class Color(NamedTuple):
    red: int
    green: int
    blue: int
    alpha: int

    def to_int(self) -> int:
        return HB_COLOR(self.blue, self.green, self.red, self.alpha)

    @staticmethod
    def from_int(value: int) -> Color:
        r = hb_color_get_red(value)
        g = hb_color_get_green(value)
        b = hb_color_get_blue(value)
        a = hb_color_get_alpha(value)
        return Color(r, g, b, a)


class OTColor(Color):
    name_id: int | None


class OTColorPaletteFlags(IntFlag):
    DEFAULT = HB_OT_COLOR_PALETTE_FLAG_DEFAULT
    USABLE_WITH_LIGHT_BACKGROUND = HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_LIGHT_BACKGROUND
    USABLE_WITH_DARK_BACKGROUND = HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_DARK_BACKGROUND


class OTColorPalette(NamedTuple):
    colors: List[OTColor]
    name_id: int | None
    flags: OTColorPaletteFlags


class OTColorLayer(NamedTuple):
    glyph: int
    color_index: int


class OTLayoutGlyphClass(IntEnum):
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


class OTNameIdPredefined(IntEnum):
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
    name_id: OTNameIdPredefined | int
    language: str | None


cdef class Face:
    cdef hb_face_t* _hb_face
    cdef object _reference_table_func
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

    # DEPRECATED: use the normal constructor
    @classmethod
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
        cdef Face inst = cls(None)
        inst._hb_face = hb_face_create_for_tables(
            _reference_table_func, <void*>user_data, NULL)
        hb_face_set_user_data(inst._hb_face, &k, <void*>inst, NULL, 0)
        inst._reference_table_func = func
        return inst

    @property
    def count(self) -> int:
        return hb_face_count(self._blob._hb_blob)

    @property
    def index(self) -> int:
        return hb_face_get_index(self._hb_face)

    @index.setter
    def index(self, value: int):
        hb_face_set_index(self._hb_face, value)

    @property
    def upem(self) -> int:
        return hb_face_get_upem(self._hb_face)

    @upem.setter
    def upem(self, value: int):
        hb_face_set_upem(self._hb_face, value)

    @property
    def glyph_count(self) -> int:
        return hb_face_get_glyph_count(self._hb_face)

    @glyph_count.setter
    def glyph_count(self, value: int):
        hb_face_set_glyph_count(self._hb_face, value)

    @property
    def blob(self) -> Blob:
        cdef hb_blob_t* blob = hb_face_reference_blob(self._hb_face)
        if blob is NULL:
            raise MemoryError()
        return Blob.from_ptr(blob)

    def reference_table(self, tag: str) -> Blob:
        cdef bytes packed = tag.encode()
        cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
        cdef hb_blob_t* blob = hb_face_reference_table(self._hb_face, hb_tag)
        if blob is NULL:
            raise MemoryError()
        return Blob.from_ptr(blob)

    @property
    def table_tags(self) -> List[str]:
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
        s = Set()
        hb_face_collect_unicodes(self._hb_face, s._hb_set)
        return s

    @property
    def variation_selectors(self) -> Set[int]:
        s = Set()
        hb_face_collect_variation_selectors(self._hb_face, s._hb_set)
        return s

    def variation_unicodes(self, variation_selector: int) -> Set[int]:
        s = Set()
        hb_face_collect_variation_unicodes(self._hb_face, variation_selector, s._hb_set)
        return s

    # variations
    @property
    def has_var_data(self) -> bool:
        return hb_ot_var_has_data(self._hb_face)

    @property
    def axis_infos(self) -> List[OTVarAxisInfo]:
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
        return hb_ot_math_has_data(self._hb_face)

    def is_glyph_extended_math_shape(self, glyph: int) -> bool:
        return hb_ot_math_is_glyph_extended_shape(self._hb_face, glyph)

    # color
    @property
    def has_color_layers(self) -> bool:
        return hb_ot_color_has_layers(self._hb_face)

    def get_glyph_color_layers(self, glyph: int) -> List[OTColorLayer]:
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
        return hb_ot_color_has_palettes(self._hb_face)

    def get_color_palette(self, palette_index: int) -> OTColorPalette:
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
        cdef list palettes = []
        cdef unsigned int palette_count = hb_ot_color_palette_get_count(self._hb_face)
        for i in range(palette_count):
            palettes.append(self.get_color_palette(i))
        return palettes

    def color_palette_color_get_name_id(self, color_index: int) -> int | None:
        cdef hb_ot_name_id_t name_id
        name_id =  hb_ot_color_palette_color_get_name_id(self._hb_face, color_index)
        if name_id == HB_OT_NAME_ID_INVALID:
            return None
        return name_id

    @property
    def has_color_paint(self) -> bool:
        return hb_ot_color_has_paint(self._hb_face)

    def glyph_has_color_paint(self, glyph: int) -> bool:
        return hb_ot_color_glyph_has_paint(self._hb_face, glyph)

    @property
    def has_color_svg(self) -> bool:
        return hb_ot_color_has_svg(self._hb_face)

    def get_glyph_color_svg(self, glyph: int) -> Blob:
        cdef hb_blob_t* blob
        blob = hb_ot_color_glyph_reference_svg(self._hb_face, glyph)
        return Blob.from_ptr(blob)

    @property
    def has_color_png(self) -> bool:
        return hb_ot_color_has_png(self._hb_face)

    # layout
    @property
    def has_layout_glyph_classes(self) -> bool:
        return hb_ot_layout_has_glyph_classes(self._hb_face)

    def get_layout_glyph_class(self, glyph: int) -> OTLayoutGlyphClass:
        return OTLayoutGlyphClass(hb_ot_layout_get_glyph_class(self._hb_face, glyph))

    @property
    def has_layout_positioning(self) -> bool:
        return hb_ot_layout_has_positioning(self._hb_face)

    @property
    def has_layout_substitution(self) -> bool:
        return hb_ot_layout_has_substitution(self._hb_face)

    def get_lookup_glyph_alternates(self, lookup_index: int, glyph: int) -> List[int]:
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
