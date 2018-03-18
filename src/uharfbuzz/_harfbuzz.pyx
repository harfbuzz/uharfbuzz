from functools import partial
cimport harfbuzz as c
# currently we malloc but dont free..
from libc.stdlib cimport free, malloc
from typing import Callable, List, Tuple


cdef class Buffer:
    cdef c.hb_buffer_t* _hb_buffer

    def __cinit__(self):
        self._hb_buffer = NULL

    def __dealloc__(self):
        if self._hb_buffer is not NULL:
            c.hb_buffer_destroy(self._hb_buffer)

    @classmethod
    def create(cls):
        cdef Buffer inst = cls()
        inst._hb_buffer = c.hb_buffer_create()
        return inst

    @property
    def direction(self) -> str:
        return c.hb_direction_to_string(
            c.hb_buffer_get_direction(self._hb_buffer))

    @direction.setter
    def direction(self, value: str):
        packed = value.encode()
        cdef char* cstr = packed
        c.hb_buffer_set_direction(
            self._hb_buffer, c.hb_direction_from_string(cstr, -1))

    @property
    def language(self) -> str:
        return c.hb_language_to_string(
            c.hb_buffer_get_language(self._hb_buffer))

    @language.setter
    def language(self, value: str):
        packed = value.encode()
        cdef char* cstr = packed
        c.hb_buffer_set_language(
            self._hb_buffer, c.hb_language_from_string(cstr, -1))

    @property
    def script(self) -> str:
        cdef char cstr[5]
        c.hb_tag_to_string(c.hb_buffer_get_script(self._hb_buffer), cstr)
        cdef bytes packed = cstr
        return packed.decode()

    @script.setter
    def script(self, value: str):
        packed = value.encode()
        cdef char* cstr = packed
        # all the *_from_string calls should probably be checked and throw an
        # exception if NULL
        c.hb_buffer_set_script(
            self._hb_buffer, c.hb_script_from_string(cstr, -1))

    def add_codepoints(self, codepoints: List[int],
                       item_offset: int = None, item_length: int = None) -> None:
        cdef int size = len(codepoints)
        if item_offset is None:
            item_offset = 0
        if item_length is None:
            item_length = size
        cdef c.hb_codepoint_t* hb_codepoints = <c.hb_codepoint_t*>malloc(
                size * sizeof(c.hb_codepoint_t))
        for i in range(size):
            hb_codepoints[i] = codepoints[i]
        c.hb_buffer_add_codepoints(
            self._hb_buffer, hb_codepoints, size, item_offset, item_length)

    def add_str(self, text: str,
                item_offset: int = None, item_length: int = None) -> None:
        cdef bytes packed = text.encode('UTF-8')
        size = len(packed)
        if item_offset is None:
            item_offset = 0
        if item_length is None:
            item_length = size
        cdef char* cstr = packed
        c.hb_buffer_add_utf8(
            self._hb_buffer, cstr, size, item_offset, item_length)

    def guess_segment_properties(self) -> None:
        hb_buffer_guess_segment_properties(self._hb_buffer)

cdef hb_user_data_key_t k


cdef hb_blob_t* _reference_table_func(
        hb_face_t* face, hb_tag_t tag, void* user_data):
    cdef Face py_face = <object>(c.hb_face_get_user_data(face, &k))
    #
    cdef char cstr[5]
    c.hb_tag_to_string(tag, cstr)
    cdef bytes packed = cstr
    #
    cdef bytes table = py_face._reference_table_func(
        py_face, packed.decode(), <object>user_data)
    return c.hb_blob_create(
        table, len(table), HB_MEMORY_MODE_READONLY, NULL, NULL)


cdef class Face:
    cdef c.hb_face_t* _hb_face
    cdef object _reference_table_func

    def __cinit__(self):
        self._hb_face = NULL

    def __dealloc__(self):
        if self._hb_face is not NULL:
            c.hb_face_destroy(self._hb_face)
        self._func = None

    """ use bytes/bytearray, not Blob
    @classmethod
    def create(self, blob: Blob, index: int):
        cdef Face inst = cls()
        inst._hb_face = c.hb_face_create(blob, index)
        return inst
    """

    @classmethod
    def create_for_tables(cls,
                          func: Callable[[
                              Face,
                              str,  # tag
                              object  # user_data
                          ], bytes],
                          user_data: object):
        cdef Face inst = cls()
        inst._hb_face = c.hb_face_create_for_tables(
            _reference_table_func, <void*>user_data, NULL)
        c.hb_face_set_user_data(inst._hb_face, &k, <void*>inst, NULL, 0)
        inst._reference_table_func = func
        return inst

    @property
    def upem(self) -> int:
        return c.hb_face_get_upem(self._hb_face)

    @upem.setter
    def upem(self, value: int):
        c.hb_face_set_upem(self._hb_face, value)


cdef class Font:
    cdef c.hb_font_t* _hb_font
    # GC bookkeeping
    cdef Face _face
    cdef FontFuncs _ffuncs

    def __cinit__(self):
        self._hb_font = NULL

    def __dealloc__(self):
        if self._hb_font is not NULL:
            c.hb_font_destroy(self._hb_font)
        self._face = self._ffuncs = None

    @classmethod
    def create(cls, face: Face):
        cdef Font inst = cls()
        inst._hb_font = c.hb_font_create(face._hb_face)
        inst._face = face
        return inst

    @property
    def funcs(self) -> FontFuncs:
        return self._ffuncs

    @funcs.setter
    def funcs(self, ffuncs: FontFuncs):
        c.hb_font_set_funcs(
            self._hb_font, ffuncs._hb_ffuncs, <void*>self, NULL)
        self._ffuncs = ffuncs

    @property
    def scale(self) -> Tuple[int, int]:
        cdef int x, y
        c.hb_font_get_scale(self._hb_font, &x, &y)
        return (x, y)

    @scale.setter
    def scale(self, value: Tuple[int, int]):
        x, y = value
        c.hb_font_set_scale(self._hb_font, x, y)

    def shape(self, buffer: Buffer, features: List[str] = None) -> None:
        cdef int size
        cdef c.hb_feature_t* hb_features
        if features is None:
            size = 0
            hb_features = NULL
        else:
            size = len(features)
            hb_features = <c.hb_feature_t*>malloc(
                size * sizeof(c.hb_feature_t))
        cdef bytes packed
        cdef char* cstr
        cdef hb_feature_t feat
        for i in range(size):
            packed = features[i].encode()
            cstr = packed
            c.hb_feature_from_string(packed, len(packed), &feat)
            hb_features[i] = feat
        c.hb_shape(self._hb_font, buffer._hb_buffer, hb_features, size)


cdef hb_position_t _glyph_h_advance_func(hb_font_t* font, void* font_data,
                                         hb_codepoint_t glyph,
                                         void* user_data):
    cdef Font py_font = <Font>font_data
    return py_font.funcs._glyph_h_advance_func(
        py_font, glyph, <object>user_data)


cdef hb_bool_t _glyph_name_func(hb_font_t *font, void *font_data,
                                hb_codepoint_t glyph,
                                char *name, unsigned int size,
                                void *user_data):
    cdef Font py_font = <Font>font_data
    cdef bytes ret = py_font.funcs._glyph_name_func(
        py_font, glyph, <object>user_data).encode()
    name[0] = ret
    return 1


cdef hb_bool_t _nominal_glyph_func(hb_font_t* font, void* font_data,
                                   hb_codepoint_t unicode,
                                   hb_codepoint_t* glyph,
                                   void* user_data):
    cdef Font py_font = <Font>font_data
    glyph[0] = py_font.funcs._nominal_glyph_func(
        py_font, unicode, <object>user_data)
    return 1


cdef class FontFuncs:
    cdef c.hb_font_funcs_t* _hb_ffuncs
    cdef object _glyph_h_advance_func
    cdef object _glyph_name_func
    cdef object _nominal_glyph_func

    def __cinit__(self):
        self._hb_ffuncs = NULL

    def __dealloc__(self):
        if self._hb_ffuncs is not NULL:
            c.hb_font_funcs_destroy(self._hb_ffuncs)

    @classmethod
    def create(cls):
        cdef FontFuncs inst = cls()
        inst._hb_ffuncs = c.hb_font_funcs_create()
        return inst

    def set_glyph_h_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # h_advance
                                 user_data: object) -> None:
        c.hb_font_funcs_set_glyph_h_advance_func(
            self._hb_ffuncs, _glyph_h_advance_func, <void*>user_data, NULL)
        self._glyph_h_advance_func = func

    def set_glyph_name_func(self,
                            func: Callable[[
                                Font,
                                int,  # gid
                                object,  # user_data
                            ], str],  # name
                            user_data: object) -> None:
        c.hb_font_funcs_set_glyph_name_func(
            self._hb_ffuncs, _glyph_name_func, <void*>user_data, NULL)
        self._glyph_name_func = func

    def set_nominal_glyph_func(self,
                               func: Callable[[
                                   Font,
                                   int,  # unicode
                                   object,  # user_data
                               ], int],  # gid
                               user_data: object) -> None:
        c.hb_font_funcs_set_nominal_glyph_func(
            self._hb_ffuncs, _nominal_glyph_func, <void*>user_data, NULL)
        self._nominal_glyph_func = func

