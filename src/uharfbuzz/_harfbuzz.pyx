#cython: language_level=3
from charfbuzz cimport *
from libc.stdlib cimport free, malloc
from libc.string cimport const_char
from typing import Callable, Dict, List, Tuple


cdef extern from "Python.h":
    # PEP 393
    bint PyUnicode_IS_READY(object u)
    Py_ssize_t PyUnicode_GET_LENGTH(object u)
    int PyUnicode_KIND(object u)
    void* PyUnicode_DATA(object u)
    ctypedef uint8_t Py_UCS1
    ctypedef uint16_t Py_UCS2
    Py_UCS1 PyUnicode_1BYTE_DATA(object u)
    Py_UCS2 PyUnicode_2BYTE_DATA(object u)
    Py_UCS4 PyUnicode_4BYTE_DATA(object u)
    int PyUnicode_1BYTE_KIND
    int PyUnicode_2BYTE_KIND
    int PyUnicode_4BYTE_KIND


cdef int msgcallback(hb_buffer_t *buffer, hb_font_t *font, const char* message, void* userdata):
    (<object>userdata)(message.decode('utf-8'))
    return 1


cdef class GlyphInfo:
    cdef hb_glyph_info_t _hb_glyph_info
    # could maybe store Buffer to prevent GC

    cdef set(self, hb_glyph_info_t info):
        self._hb_glyph_info = info

    @property
    def codepoint(self):
        return self._hb_glyph_info.codepoint

    @property
    def cluster(self):
        return self._hb_glyph_info.cluster


cdef class GlyphPosition:
    cdef hb_glyph_position_t _hb_glyph_position
    # could maybe store Buffer to prevent GC

    cdef set(self, hb_glyph_position_t position):
        self._hb_glyph_position = position

    @property
    def position(self):
        return (
            self._hb_glyph_position.x_offset,
            self._hb_glyph_position.y_offset,
            self._hb_glyph_position.x_advance,
            self._hb_glyph_position.y_advance
        )

    @property
    def x_advance(self):
        return self._hb_glyph_position.x_advance

    @property
    def y_advance(self):
        return self._hb_glyph_position.y_advance

    @property
    def x_offset(self):
        return self._hb_glyph_position.x_offset

    @property
    def y_offset(self):
        return self._hb_glyph_position.y_offset


cdef class Buffer:
    cdef hb_buffer_t* _hb_buffer

    def __cinit__(self):
        self._hb_buffer = hb_buffer_create()
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()

    def __dealloc__(self):
        if self._hb_buffer is not NULL:
            hb_buffer_destroy(self._hb_buffer)

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls):
        cdef Buffer inst = cls()
        return inst

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
                       item_offset: int = 0, item_length: int = -1) -> None:
        cdef unsigned int size = len(codepoints)
        cdef hb_codepoint_t* hb_codepoints
        if not size:
            hb_codepoints = NULL
        else:
            hb_codepoints = <hb_codepoint_t*>malloc(
                size * sizeof(hb_codepoint_t))
            for i in range(size):
                hb_codepoints[i] = codepoints[i]
        hb_buffer_add_codepoints(
            self._hb_buffer, hb_codepoints, size, item_offset, item_length)
        if hb_codepoints is not NULL:
            free(hb_codepoints)

    def add_utf8(self, text: bytes,
                 item_offset: int = 0, item_length: int = -1) -> None:
        hb_buffer_add_utf8(
            self._hb_buffer, text, len(text), item_offset, item_length)

    def add_str(self, text: str,
                item_offset: int = 0, item_length: int = -1) -> None:
        # ensure unicode string is in the "canonical" representation
        assert PyUnicode_IS_READY(text)

        cdef Py_ssize_t length = PyUnicode_GET_LENGTH(text)
        cdef int kind = PyUnicode_KIND(text)

        if kind == PyUnicode_1BYTE_KIND:
            hb_buffer_add_latin1(
                self._hb_buffer,
                <uint8_t*>PyUnicode_1BYTE_DATA(text),
                length,
                item_offset,
                item_length,
            )
        elif kind == PyUnicode_2BYTE_KIND:
            hb_buffer_add_utf16(
                self._hb_buffer,
                <uint16_t*>PyUnicode_2BYTE_DATA(text),
                length,
                item_offset,
                item_length,
            )
        elif kind == PyUnicode_4BYTE_KIND:
            hb_buffer_add_utf32(
                self._hb_buffer,
                <uint32_t*>PyUnicode_4BYTE_DATA(text),
                length,
                item_offset,
                item_length,
            )
        else:
            raise AssertionError(kind)

    def guess_segment_properties(self) -> None:
        hb_buffer_guess_segment_properties(self._hb_buffer)

    def set_message_func(self, callback) -> None:
        hb_buffer_set_message_func(self._hb_buffer, msgcallback, <void*>callback, NULL)


cdef hb_user_data_key_t k


cdef hb_blob_t* _reference_table_func(
        hb_face_t* face, hb_tag_t tag, void* user_data):
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


cdef class Face:
    cdef hb_face_t* _hb_face
    cdef object _reference_table_func

    def __cinit__(self, bytes blob, int index=0):
        cdef hb_blob_t* hb_blob
        if blob is not None:
            hb_blob = hb_blob_create(
                blob, len(blob), HB_MEMORY_MODE_READONLY, NULL, NULL)
            self._hb_face = hb_face_create(hb_blob, index)
        else:
            self._hb_face = NULL

    def __dealloc__(self):
        if self._hb_face is not NULL:
            hb_face_destroy(self._hb_face)

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls, bytes blob, int index=0):
        cdef Face inst = cls(blob, index)
        return inst

    @classmethod
    def create_for_tables(cls,
                          func: Callable[[
                              Face,
                              str,  # tag
                              object  # user_data
                          ], bytes],
                          user_data: object):
        cdef Face inst = cls(None)
        inst._hb_face = hb_face_create_for_tables(
            _reference_table_func, <void*>user_data, NULL)
        hb_face_set_user_data(inst._hb_face, &k, <void*>inst, NULL, 0)
        inst._reference_table_func = func
        return inst

    @property
    def upem(self) -> int:
        return hb_face_get_upem(self._hb_face)

    @upem.setter
    def upem(self, value: int):
        hb_face_set_upem(self._hb_face, value)


cdef class Font:
    cdef hb_font_t* _hb_font
    # GC bookkeeping
    cdef Face _face
    cdef FontFuncs _ffuncs

    def __cinit__(self, Face face):
        self._hb_font = hb_font_create(face._hb_face)
        self._face = face

    def __dealloc__(self):
        if self._hb_font is not NULL:
            hb_font_destroy(self._hb_font)
        self._face = self._ffuncs = None

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls, face: Face):
        cdef Font inst = cls(face)
        return inst

    @property
    def face(self):
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

    def set_variations(self, variations: Dict[str, float]) -> None:
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


cdef hb_position_t _glyph_h_advance_func(hb_font_t* font, void* font_data,
                                         hb_codepoint_t glyph,
                                         void* user_data):
    cdef Font py_font = <Font>font_data
    return (<FontFuncs>py_font.funcs)._glyph_h_advance_func(
        py_font, glyph, <object>user_data)


cdef hb_position_t _glyph_v_advance_func(hb_font_t* font, void* font_data,
                                         hb_codepoint_t glyph,
                                         void* user_data):
    cdef Font py_font = <Font>font_data
    return (<FontFuncs>py_font.funcs)._glyph_v_advance_func(
        py_font, glyph, <object>user_data)


cdef hb_bool_t _glyph_v_origin_func(hb_font_t* font, void* font_data,
                                    hb_codepoint_t glyph,
                                    hb_position_t* x, hb_position_t* y,
                                    void* user_data):
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
                                void *user_data):
    cdef Font py_font = <Font>font_data
    cdef bytes ret = (<FontFuncs>py_font.funcs)._glyph_name_func(
        py_font, glyph, <object>user_data).encode()
    name[0] = ret
    return 1


cdef hb_bool_t _nominal_glyph_func(hb_font_t* font, void* font_data,
                                   hb_codepoint_t unicode,
                                   hb_codepoint_t* glyph,
                                   void* user_data):
    cdef Font py_font = <Font>font_data
    glyph[0] = (<FontFuncs>py_font.funcs)._nominal_glyph_func(
        py_font, unicode, <object>user_data)
    # If the glyph is .notdef, return false, else return true
    return int(glyph[0] != 0)


cdef class FontFuncs:
    cdef hb_font_funcs_t* _hb_ffuncs
    cdef object _glyph_h_advance_func
    cdef object _glyph_v_advance_func
    cdef object _glyph_v_origin_func
    cdef object _glyph_name_func
    cdef object _nominal_glyph_func

    def __cinit__(self):
        self._hb_ffuncs = hb_font_funcs_create()

    def __dealloc__(self):
        if self._hb_ffuncs is not NULL:
            hb_font_funcs_destroy(self._hb_ffuncs)

    # DEPRECATED: use the normal constructor
    @classmethod
    def create(cls):
        cdef FontFuncs inst = cls()
        return inst

    def set_glyph_h_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # h_advance
                                 user_data: object) -> None:
        hb_font_funcs_set_glyph_h_advance_func(
            self._hb_ffuncs, _glyph_h_advance_func, <void*>user_data, NULL)
        self._glyph_h_advance_func = func

    def set_glyph_v_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # v_advance
                                 user_data: object) -> None:
        hb_font_funcs_set_glyph_v_advance_func(
            self._hb_ffuncs, _glyph_v_advance_func, <void*>user_data, NULL)
        self._glyph_v_advance_func = func

    def set_glyph_v_origin_func(self,
                                func: Callable[[
                                    Font,
                                    int,  # gid
                                    object,  # user_data
                                ], (int, int, int)],  # success, v_origin_x, v_origin_y
                                user_data: object) -> None:
        hb_font_funcs_set_glyph_v_origin_func(
            self._hb_ffuncs, _glyph_v_origin_func, <void*>user_data, NULL)
        self._glyph_v_origin_func = func

    def set_glyph_name_func(self,
                            func: Callable[[
                                Font,
                                int,  # gid
                                object,  # user_data
                            ], str],  # name
                            user_data: object) -> None:
        hb_font_funcs_set_glyph_name_func(
            self._hb_ffuncs, _glyph_name_func, <void*>user_data, NULL)
        self._glyph_name_func = func

    def set_nominal_glyph_func(self,
                               func: Callable[[
                                   Font,
                                   int,  # unicode
                                   object,  # user_data
                               ], int],  # gid
                               user_data: object) -> None:
        hb_font_funcs_set_nominal_glyph_func(
            self._hb_ffuncs, _nominal_glyph_func, <void*>user_data, NULL)
        self._nominal_glyph_func = func


def shape(font: Font, buffer: Buffer, features: Dict[str, bool] = None) -> None:
    cdef unsigned int size
    cdef hb_feature_t* hb_features
    cdef bytes packed
    cdef char* cstr
    cdef hb_feature_t feat
    if features is None:
        size = 0
        hb_features = NULL
    else:
        size = len(features)
        hb_features = <hb_feature_t*>malloc(size * sizeof(hb_feature_t))
        for i, (name, value) in enumerate(features.items()):
            packed = name.encode()
            cstr = packed
            hb_feature_from_string(packed, len(packed), &feat)
            feat.value = value
            hb_features[i] = feat
    hb_shape(font._hb_font, buffer._hb_buffer, hb_features, size)
    if hb_features is not NULL:
        free(hb_features)


DEF STATIC_TAGS_ARRAY_SIZE = 128


def ot_layout_language_get_feature_tags(
        face: Face, tag: str, script_index: int = 0,
        language_index: int = 0xFFFF) -> List[str]:
    cdef bytes packed = tag.encode()
    cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
    cdef unsigned int feature_count = STATIC_TAGS_ARRAY_SIZE
    cdef hb_tag_t feature_tags[STATIC_TAGS_ARRAY_SIZE]
    cdef list tags = []
    cdef char cstr[5]
    cdef unsigned int i
    cdef unsigned int start_offset = 0
    while feature_count == STATIC_TAGS_ARRAY_SIZE:
        hb_ot_layout_language_get_feature_tags(
            face._hb_face, hb_tag, script_index, language_index, start_offset, &feature_count,
            feature_tags)
        for i in range(feature_count):
            hb_tag_to_string(feature_tags[i], cstr)
            cstr[4] = b'\0'
            packed = cstr
            tags.append(packed.decode())
        start_offset += feature_count
    return tags


def ot_layout_script_get_language_tags(
        face: Face, tag: str, script_index: int = 0) -> List[str]:
    cdef bytes packed = tag.encode()
    cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
    cdef unsigned int language_count = STATIC_TAGS_ARRAY_SIZE
    cdef hb_tag_t language_tags[STATIC_TAGS_ARRAY_SIZE]
    cdef list tags = []
    cdef char cstr[5]
    cdef unsigned int i
    cdef unsigned int start_offset = 0
    while language_count == STATIC_TAGS_ARRAY_SIZE:
        hb_ot_layout_script_get_language_tags(
            face._hb_face, hb_tag, script_index, start_offset, &language_count, language_tags)
        for i in range(language_count):
            hb_tag_to_string(language_tags[i], cstr)
            cstr[4] = b'\0'
            packed = cstr
            tags.append(packed.decode())
        start_offset += language_count
    return tags

def ot_layout_table_get_script_tags(face: Face, tag: str) -> List[str]:
    cdef bytes packed = tag.encode()
    cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
    cdef unsigned int script_count = STATIC_TAGS_ARRAY_SIZE
    cdef hb_tag_t script_tags[STATIC_TAGS_ARRAY_SIZE]
    cdef list tags = []
    cdef char cstr[5]
    cdef unsigned int i
    cdef unsigned int start_offset = 0
    while script_count == STATIC_TAGS_ARRAY_SIZE:
        hb_ot_layout_table_get_script_tags(
            face._hb_face, hb_tag, start_offset, &script_count, script_tags)
        for i in range(script_count):
            hb_tag_to_string(script_tags[i], cstr)
            cstr[4] = b'\0'
            packed = cstr
            tags.append(packed.decode())
        start_offset += script_count
    return tags

def ot_layout_get_baseline(font: Font,
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
    success = hb_ot_layout_get_baseline(font._hb_font,
                                        hb_baseline_tag,
                                        hb_direction,
                                        hb_script_tag,
                                        hb_language_tag,
                                        &hb_position)
    if success:
        return hb_position
    else:
        return None

def ot_font_set_funcs(Font font):
    hb_ot_font_set_funcs(font._hb_font)
