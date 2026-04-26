class GlyphFlags(IntFlag):
    UNSAFE_TO_BREAK = HB_GLYPH_FLAG_UNSAFE_TO_BREAK
    UNSAFE_TO_CONCAT = HB_GLYPH_FLAG_UNSAFE_TO_CONCAT
    SAFE_TO_INSERT_TATWEEL = HB_GLYPH_FLAG_SAFE_TO_INSERT_TATWEEL

cdef class GlyphInfo:

    cdef hb_glyph_info_t _hb_glyph_info
    # could maybe store Buffer to prevent GC

    cdef set(self, hb_glyph_info_t info):
        self._hb_glyph_info = info

    @property
    def codepoint(self) -> int:
        return self._hb_glyph_info.codepoint

    @property
    def cluster(self) -> int:
        return self._hb_glyph_info.cluster

    @property
    def flags(self) -> GlyphFlags:
        return GlyphFlags(self._hb_glyph_info.mask & HB_GLYPH_FLAG_DEFINED)


cdef class GlyphPosition:
    cdef hb_glyph_position_t _hb_glyph_position
    # could maybe store Buffer to prevent GC

    cdef set(self, hb_glyph_position_t position):
        self._hb_glyph_position = position

    @property
    def position(self) -> Tuple[int, int, int, int]:
        return (
            self._hb_glyph_position.x_offset,
            self._hb_glyph_position.y_offset,
            self._hb_glyph_position.x_advance,
            self._hb_glyph_position.y_advance
        )

    @property
    def x_advance(self) -> int:
        return self._hb_glyph_position.x_advance

    @property
    def y_advance(self) -> int:
        return self._hb_glyph_position.y_advance

    @property
    def x_offset(self) -> int:
        return self._hb_glyph_position.x_offset

    @property
    def y_offset(self) -> int:
        return self._hb_glyph_position.y_offset


class BufferFlags(IntFlag):
    DEFAULT = HB_BUFFER_FLAG_DEFAULT
    BOT = HB_BUFFER_FLAG_BOT
    EOT = HB_BUFFER_FLAG_EOT
    PRESERVE_DEFAULT_IGNORABLES = HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES
    REMOVE_DEFAULT_IGNORABLES = HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES
    DO_NOT_INSERT_DOTTED_CIRCLE = HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE
    VERIFY = HB_BUFFER_FLAG_VERIFY
    PRODUCE_UNSAFE_TO_CONCAT = HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT
    PRODUCE_SAFE_TO_INSERT_TATWEEL = HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL

class BufferClusterLevel(IntEnum):
    MONOTONE_GRAPHEMES = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
    MONOTONE_CHARACTERS = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
    CHARACTERS = HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
    GRAPHEMES = HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES
    DEFAULT = HB_BUFFER_CLUSTER_LEVEL_DEFAULT

class BufferContentType(IntEnum):
    INVALID = HB_BUFFER_CONTENT_TYPE_INVALID
    UNICODE = HB_BUFFER_CONTENT_TYPE_UNICODE
    GLYPHS = HB_BUFFER_CONTENT_TYPE_GLYPHS

class BufferSerializeFormat(IntEnum):
    TEXT = HB_BUFFER_SERIALIZE_FORMAT_TEXT
    JSON = HB_BUFFER_SERIALIZE_FORMAT_JSON
    INVALID = HB_BUFFER_SERIALIZE_FORMAT_INVALID

class BufferSerializeFlags(IntFlag):
    DEFAULT = HB_BUFFER_SERIALIZE_FLAG_DEFAULT
    NO_CLUSTERS = HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS
    NO_POSITIONS = HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS
    NO_GLYPH_NAMES = HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES
    GLYPH_EXTENTS = HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS
    GLYPH_FLAGS = HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS
    NO_ADVANCES = HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES
    DEFINED = HB_BUFFER_SERIALIZE_FLAG_DEFINED

cdef class Buffer:
    cdef hb_buffer_t* _hb_buffer
    cdef object _message_callback

    DEFAULT_REPLACEMENT_CODEPOINT = HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT

    def __cinit__(self):
        self._hb_buffer = hb_buffer_create()
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()
        self._message_callback = None

    def __dealloc__(self):
        hb_buffer_destroy(self._hb_buffer)

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls) -> Buffer:
        cdef Buffer inst = cls()
        return inst

    def __len__(self) -> int:
        return hb_buffer_get_length(self._hb_buffer)

    def reset(self):
        hb_buffer_reset (self._hb_buffer)

    def clear_contents(self):
        hb_buffer_clear_contents(self._hb_buffer)

    @property
    def direction(self) -> str:
        cdef const_char* cstr = hb_direction_to_string(
            hb_buffer_get_direction(self._hb_buffer))
        cdef bytes packed = cstr
        return packed.decode()

    @direction.setter
    def direction(self, value: str):
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        hb_buffer_set_direction(
            self._hb_buffer, hb_direction_from_string(cstr, -1))

    @property
    def glyph_infos(self) -> List[GlyphInfo]:
        cdef unsigned int count
        cdef hb_glyph_info_t* glyph_infos = hb_buffer_get_glyph_infos(
            self._hb_buffer, &count)
        cdef list infos = []
        cdef GlyphInfo info
        cdef unsigned int i
        for i in range(count):
            info = GlyphInfo()
            info.set(glyph_infos[i])
            infos.append(info)
        return infos

    @property
    def glyph_positions(self) -> List[GlyphPosition]:
        cdef unsigned int count
        cdef hb_glyph_position_t* glyph_positions = \
            hb_buffer_get_glyph_positions(self._hb_buffer, &count)
        if glyph_positions is NULL:
            return None
        cdef list positions = []
        cdef GlyphPosition position
        cdef unsigned int i
        for i in range(count):
            position = GlyphPosition()
            position.set(glyph_positions[i])
            positions.append(position)
        return positions

    @property
    def language(self) -> str:
        cdef const_char* cstr = hb_language_to_string(
            hb_buffer_get_language(self._hb_buffer))
        if cstr is NULL:
            return None
        cdef bytes packed = cstr
        return packed.decode()

    @language.setter
    def language(self, value: str):
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        hb_buffer_set_language(
            self._hb_buffer, hb_language_from_string(cstr, -1))

    @property
    def script(self) -> str:
        cdef char cstr[5]
        hb_tag_to_string(hb_buffer_get_script(self._hb_buffer), cstr)
        cstr[4] = b'\0'
        if cstr[0] == b'\0':
            return None
        cdef bytes packed = cstr
        return packed.decode()

    @script.setter
    def script(self, value: str):
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        # all the *_from_string calls should probably be checked and throw an
        # exception if invalid
        hb_buffer_set_script(
            self._hb_buffer, hb_script_from_string(cstr, -1))

    @property
    def flags(self) -> BufferFlags:
        level = hb_buffer_get_flags(self._hb_buffer)
        return BufferFlags(level)

    @flags.setter
    def flags(self, value: BufferFlags):
        level = BufferFlags(value)
        hb_buffer_set_flags(self._hb_buffer, level)

    @property
    def cluster_level(self) -> BufferClusterLevel:
        level = hb_buffer_get_cluster_level(self._hb_buffer)
        return BufferClusterLevel(level)

    @cluster_level.setter
    def cluster_level(self, value: BufferClusterLevel):
        level = BufferClusterLevel(value)
        hb_buffer_set_cluster_level(self._hb_buffer, level)

    @property
    def content_type(self) -> BufferContentType:
        level = hb_buffer_get_content_type(self._hb_buffer)
        return BufferContentType(level)

    @content_type.setter
    def content_type(self, value: BufferContentType):
        level = BufferContentType(value)
        hb_buffer_set_content_type(self._hb_buffer, level)

    @property
    def replacement_codepoint(self) -> int:
        return hb_buffer_get_replacement_codepoint(self._hb_buffer)

    @replacement_codepoint.setter
    def replacement_codepoint(self, value: int):
        hb_buffer_set_replacement_codepoint(self._hb_buffer, value)

    @property
    def invisible_glyph(self) -> int:
        return hb_buffer_get_invisible_glyph(self._hb_buffer)

    @invisible_glyph.setter
    def invisible_glyph(self, value: int):
        hb_buffer_set_invisible_glyph(self._hb_buffer, value)

    @property
    def not_found_glyph(self) -> int:
        return hb_buffer_get_not_found_glyph(self._hb_buffer)

    @not_found_glyph.setter
    def not_found_glyph(self, value: int):
        hb_buffer_set_not_found_glyph(self._hb_buffer, value)

    def set_language_from_ot_tag(self, value: str):
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        hb_buffer_set_language(
            self._hb_buffer, hb_ot_tag_to_language(hb_tag_from_string(cstr, -1)))

    def set_script_from_ot_tag(self, value: str):
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        hb_buffer_set_script(
            self._hb_buffer, hb_ot_tag_to_script(hb_tag_from_string(cstr, -1)))

    def add_codepoints(self, codepoints: List[int],
                       item_offset: int = 0, item_length: int = -1):
        cdef unsigned int size = len(codepoints)
        cdef hb_codepoint_t* hb_codepoints
        if not size:
            return
        hb_codepoints = <hb_codepoint_t*>malloc(
            size * sizeof(hb_codepoint_t))
        for i in range(size):
            hb_codepoints[i] = codepoints[i]
        hb_buffer_add_codepoints(
            self._hb_buffer, hb_codepoints, size, item_offset, item_length)
        free(hb_codepoints)
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()

    def add_utf8(self, text: bytes,
                 item_offset: int = 0, item_length: int = -1):
        hb_buffer_add_utf8(
            self._hb_buffer, text, len(text), item_offset, item_length)
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()

    def add_str(self, text: str,
                item_offset: int = 0, item_length: int = -1):
        cdef Py_UCS4* ucs4_buffer
        cdef Py_ssize_t text_length

        ucs4_buffer = PyUnicode_AsUCS4Copy(text)
        if ucs4_buffer == NULL:
            raise MemoryError()
        try:
            text_length = PyUnicode_GetLength(text)
            if text_length == -1:
                raise ValueError("Invalid Unicode string")
            hb_buffer_add_utf32(
                self._hb_buffer,
                <uint32_t*>ucs4_buffer,
                text_length,
                item_offset,
                item_length
            )
            if not hb_buffer_allocation_successful(self._hb_buffer):
                raise MemoryError()
        finally:
            PyMem_Free(ucs4_buffer)

    def guess_segment_properties(self):
        hb_buffer_guess_segment_properties(self._hb_buffer)

    def set_message_func(self, callback: Callable[str]):
        self._message_callback = callback
        hb_buffer_set_message_func(self._hb_buffer, msgcallback, <void*>callback, NULL)

    def serialize(self,
                  font: Font,
                  format: BufferSerializeFormat = BufferSerializeFormat.TEXT,
                  flags: BufferSerializeFlags = BufferSerializeFlags.DEFAULT) -> str:
        cdef unsigned int num_glyphs = hb_buffer_get_length(self._hb_buffer)
        cdef unsigned int start = 0
        cdef char cstr[STATIC_ARRAY_SIZE]
        cdef unsigned int consumed
        cdef bytes packed = b""

        while start < num_glyphs:
            start += hb_buffer_serialize(
                self._hb_buffer,
                start,
                num_glyphs,
                cstr,
                STATIC_ARRAY_SIZE,
                &consumed,
                font._hb_font,
                format,
                flags
            )
            if consumed == 0:
                break
            packed += cstr[:consumed]

        return packed.decode()
