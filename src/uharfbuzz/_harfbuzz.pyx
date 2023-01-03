#cython: language_level=3
import os
import warnings
from enum import IntEnum, IntFlag
from .charfbuzz cimport *
from libc.stdlib cimport free, malloc, calloc
from libc.string cimport const_char
from collections import namedtuple
from cpython.pycapsule cimport PyCapsule_GetPointer, PyCapsule_IsValid
from typing import Callable, Dict, List, Sequence, Tuple, Union
from pathlib import Path


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
    ret = (<object>userdata)(message.decode('utf-8'))
    if ret is None:
        return 1
    return ret


def version_string() -> str:
    cdef const char* cstr = hb_version_string()
    cdef bytes packed = cstr
    return packed.decode()


class HarfBuzzError(Exception):
    pass


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


class BufferClusterLevel(IntEnum):
    MONOTONE_GRAPHEMES = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
    MONOTONE_CHARACTERS = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
    CHARACTERS = HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
    DEFAULT = HB_BUFFER_CLUSTER_LEVEL_DEFAULT


cdef class Buffer:
    cdef hb_buffer_t* _hb_buffer
    cdef object _message_callback

    def __cinit__(self):
        self._hb_buffer = hb_buffer_create()
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()
        self._message_callback = None

    def __dealloc__(self):
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
    def cluster_level(self) -> BufferClusterLevel:
        level = hb_buffer_get_cluster_level(self._hb_buffer)
        return BufferClusterLevel(level)

    @cluster_level.setter
    def cluster_level(self, value: BufferClusterLevel):
        level = BufferClusterLevel(value)
        hb_buffer_set_cluster_level(self._hb_buffer, level)

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
        self._message_callback = callback
        hb_buffer_set_message_func(self._hb_buffer, msgcallback, <void*>callback, NULL)


cdef class Blob:
    cdef hb_blob_t* _hb_blob
    cdef object _data

    def __cinit__(self, bytes data):
        if data is not None:
            self._data = data
            self._hb_blob = hb_blob_create(
                data, len(data), HB_MEMORY_MODE_READONLY, NULL, NULL)
        else:
            self._hb_blob = hb_blob_get_empty()

    @classmethod
    def from_file_path(cls, filename: Union[str, Path]):
        cdef bytes packed = os.fsencode(filename)
        cdef hb_blob_t* blob = hb_blob_create_from_file_or_fail(<char*>packed)
        if blob == NULL:
            raise HarfBuzzError(f"Failed to open: {filename}")
        cdef Blob inst = cls(None)
        inst._hb_blob = blob
        return inst

    def __dealloc__(self):
        hb_blob_destroy(self._hb_blob)
        self._data = None

    @property
    def data(self) -> bytes:
        return self._data


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
    cdef Blob _blob

    def __cinit__(self, blob: Union[Blob, bytes], int index=0):
        if blob is not None:
            if not isinstance(blob, Blob):
                self._blob = Blob(blob)
            else:
                self._blob = blob
            self._hb_face = hb_face_create(self._blob._hb_blob, index)
        else:
            self._hb_face = hb_face_get_empty()

    def __dealloc__(self):
        hb_face_destroy(self._hb_face)
        self._blob = None

    @staticmethod
    cdef Face from_ptr(hb_face_t* hb_face):
        """Create Face from taking ownership of a pointer."""

        cdef Face wrapper = Face.__new__(Face)
        wrapper._hb_face = hb_face
        wrapper._blob = wrapper.reference_blob
        return wrapper

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

    @property
    def reference_blob(self) -> Blob:
        cdef hb_blob_t* blob = hb_face_reference_blob(self._hb_face)
        if blob is NULL:
            raise MemoryError()
        cdef Blob inst = Blob(None)
        inst._hb_blob = blob
        cdef unsigned int blob_length
        cdef const_char* blob_data = hb_blob_get_data(blob, &blob_length)
        inst._data = blob_data[:blob_length]
        return inst


# typing.NamedTuple doesn't seem to work with cython
GlyphExtents = namedtuple(
    "GlyphExtents", ["x_bearing", "y_bearing", "width", "height"]
)

FontExtents = namedtuple(
    "FontExtents", ["ascender", "descender", "line_gap"]
)

cdef class Font:
    cdef hb_font_t* _hb_font
    # GC bookkeeping
    cdef Face _face
    cdef FontFuncs _ffuncs

    def __cinit__(self, face_or_font):
        if isinstance(face_or_font, Font):
            self.__create_sub_font(face_or_font)
            return
        self.__create(face_or_font)

    cdef __create(self, Face face):
        self._hb_font = hb_font_create(face._hb_face)
        self._face = face

    cdef __create_sub_font(self, Font font):
        self._hb_font = hb_font_create_sub_font (font._hb_font)
        self._face = font._face

    def __dealloc__(self):
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

    def get_glyph_name(self, gid: int):
        cdef char name[64]
        cdef bytes packed
        success = hb_font_get_glyph_name(self._hb_font, gid, name, 64)
        if success:
            packed = name
            return packed.decode()
        else:
            return None

    def get_glyph_extents(self, gid: int):
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

    def get_font_extents(self, direction: str):
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

    def get_nominal_glyph(self, unicode: int):
        cdef hb_codepoint_t gid
        success = hb_font_get_nominal_glyph(self._hb_font, unicode, &gid)
        return gid if success else None

    def get_var_coords_normalized(self):
        cdef unsigned int length
        cdef const int *coords
        coords = hb_font_get_var_coords_normalized(self._hb_font, &length)
        # Convert from 2.14 fixed to float: divide by 1 << 14
        return [coords[i] / 0x4000 for i in range(length)]

    def set_var_coords_normalized(self, coords):
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

    def glyph_to_string(self, gid: int):
        cdef char name[64]
        cdef bytes packed
        hb_font_glyph_to_string(self._hb_font, gid, name, 64)
        packed = name
        return packed.decode()

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

        hb_font_get_glyph_shape(self._hb_font, gid, drawfuncs, <void*>&methods)

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
                            void *user_data):
    (<object>((<_pen_methods*>draw_data).moveTo))((to_x, to_y))

cdef void _pen_line_to_func(hb_draw_funcs_t *dfuncs,
                            void *draw_data,
                            hb_draw_state_t *st,
                            float to_x,
                            float to_y,
                            void *user_data):
    (<object>((<_pen_methods*>draw_data).lineTo))((to_x, to_y))

cdef void _pen_close_path_func(hb_draw_funcs_t *dfuncs,
                               void *draw_data,
                               hb_draw_state_t *st,
                               void *user_data):
    (<object>((<_pen_methods*>draw_data).closePath))()

cdef void _pen_quadratic_to_func(hb_draw_funcs_t *dfuncs,
                                 void *draw_data,
                                 hb_draw_state_t *st,
                                 float c1_x,
                                 float c1_y,
                                 float to_x,
                                 float to_y,
                                 void *user_data):
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
                             void *user_data):
    (<object>((<_pen_methods*>draw_data).curveTo))((c1_x, c1_y), (c2_x, c2_y), (to_x, to_y))


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


cdef hb_bool_t _font_h_extents_func(hb_font_t* font, void* font_data,
                                    hb_font_extents_t *extents,
                                    void* user_data):
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
                                    void* user_data):
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
    cdef object _font_h_extents_func
    cdef object _font_v_extents_func

    def __cinit__(self):
        self._hb_ffuncs = hb_font_funcs_create()

    def __dealloc__(self):
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

    def set_font_h_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object) -> None:
        hb_font_funcs_set_font_h_extents_func(
            self._hb_ffuncs, _font_h_extents_func, <void*>user_data, NULL)
        self._font_h_extents_func = func

    def set_font_v_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object) -> None:
        hb_font_funcs_set_font_v_extents_func(
            self._hb_ffuncs, _font_v_extents_func, <void*>user_data, NULL)
        self._font_v_extents_func = func

def shape(font: Font, buffer: Buffer,
        features: Dict[str,Union[int,bool,Sequence[Tuple[int,int,Union[int,bool]]]]] = None,
        shapers: List[str] = None) -> None:
    cdef unsigned int size
    cdef hb_feature_t* hb_features
    cdef bytes packed
    cdef hb_feature_t feat
    cdef const char* c_shapers[10]
    size = 0
    hb_features = NULL
    try:
        if features:
            for value in features.values():
                if isinstance(value, int):
                    size += 1
                else:
                    size += len(value)
            hb_features = <hb_feature_t*>malloc(size * sizeof(hb_feature_t))
            i = 0
            for name, value in features.items():
                assert i < size, "index out of range for feature array capacity"
                packed = name.encode()
                if isinstance(value, int):
                    hb_feature_from_string(packed, len(packed), &feat)
                    feat.value = value
                    hb_features[i] = feat
                    i += 1
                else:
                    feat.tag = hb_tag_from_string(packed, -1)
                    for start, end, value in value:
                        feat.value = value
                        feat.start = start
                        feat.end = end
                        hb_features[i] = feat
                        i += 1
        if shapers:
            for i, shaper in enumerate(shapers[:9]):
                packed = shaper.encode()
                c_shapers[i] = packed
            c_shapers[i + 1] = NULL
            ret = hb_shape_full(font._hb_font, buffer._hb_buffer, hb_features, size, c_shapers)
            if not ret:
                raise RuntimeError("All shapers failed")
        else:
            hb_shape(font._hb_font, buffer._hb_buffer, hb_features, size)
    finally:
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

cdef void _move_to_func(hb_draw_funcs_t *dfuncs,
                        void *draw_data,
                        hb_draw_state_t *st,
                        float to_x,
                        float to_y,
                        void *user_data):
    m = (<object>draw_data).move_to_func()
    userdata = <object>user_data
    if userdata is None:
        userdata = (<object>draw_data).user_data()
    m(to_x, to_y, userdata)

cdef void _line_to_func(hb_draw_funcs_t *dfuncs,
                        void *draw_data,
                        hb_draw_state_t *st,
                        float to_x,
                        float to_y,
                        void *user_data):
    l = (<object>draw_data).line_to_func()
    userdata = <object>user_data
    if userdata is None:
        userdata = (<object>draw_data).user_data()
    l(to_x, to_y, userdata)

cdef void _close_path_func(hb_draw_funcs_t *dfuncs,
                           void *draw_data,
                           hb_draw_state_t *st,
                           void *user_data):
    cl = (<object>draw_data).close_path_func()
    userdata = <object>user_data
    if userdata is None:
        userdata = (<object>draw_data).user_data()
    cl(userdata)

cdef void _quadratic_to_func(hb_draw_funcs_t *dfuncs,
                             void *draw_data,
                             hb_draw_state_t *st,
                             float c1_x,
                             float c1_y,
                             float to_x,
                             float to_y,
                             void *user_data):
    q = (<object>draw_data).quadratic_to_func()
    userdata = <object>user_data
    if userdata is None:
        userdata = (<object>draw_data).user_data()
    q(c1_x, c1_y, to_x, to_y, userdata)

cdef void _cubic_to_func(hb_draw_funcs_t *dfuncs,
                         void *draw_data,
                         hb_draw_state_t *st,
                         float c1_x,
                         float c1_y,
                         float c2_x,
                         float c2_y,
                         float to_x,
                         float to_y,
                         void *user_data):
    c = (<object>draw_data).cubic_to_func()
    userdata = <object>user_data
    if userdata is None:
        userdata = (<object>draw_data).user_data()
    c(c1_x, c1_y, c2_x, c2_y, to_x, to_y, userdata)


cdef class DrawFuncs:
    cdef hb_draw_funcs_t* _hb_drawfuncs
    cdef object _move_to_func
    cdef object _line_to_func
    cdef object _cubic_to_func
    cdef object _quadratic_to_func
    cdef object _close_path_func
    cdef object _user_data

    def __cinit__(self):
        self._hb_drawfuncs = hb_draw_funcs_create()
        self._user_data = None

    def __dealloc__(self):
        hb_draw_funcs_destroy(self._hb_drawfuncs)

    def get_glyph_shape(self, font: Font, gid: int):
        hb_font_get_glyph_shape(font._hb_font, gid, self._hb_drawfuncs, <void*>self);

    def draw_glyph(self, font: Font, gid: int, user_data: object):
        warnings.warn(
            "draw_glyph() is deprecated, use get_glyph_shape() instead",
            DeprecationWarning,
        )
        self._user_data = user_data
        self.get_glyph_shape(font, gid)

    def move_to_func(self):
        return self._move_to_func

    def line_to_func(self):
        return self._line_to_func

    def cubic_to_func(self):
        return self._cubic_to_func

    def quadratic_to_func(self):
        return self._quadratic_to_func

    def close_path_func(self):
        return self._close_path_func

    def user_data(self):
        return self._user_data

    def set_move_to_func(self,
                                 func: Callable[[
                                     float,
                                     float,
                                     object,  # user_data
                                 ], None],
                                 user_data: object = None) -> None:
        cdef hb_draw_move_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._move_to_func = None
            func_p = <hb_draw_move_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._move_to_func = func
            func_p = _move_to_func
            user_data_p = <void*>user_data
        hb_draw_funcs_set_move_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_line_to_func(self,
                         func: Callable[[
                             float,
                             float,
                             object,  # user_data
                         ], None],
                         user_data: object = None) -> None:
        cdef hb_draw_line_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._line_to_func = None
            func_p = <hb_draw_line_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._line_to_func = func
            func_p = _line_to_func
            user_data_p = <void*>user_data
        hb_draw_funcs_set_line_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_cubic_to_func(self,
                          func: Callable[[
                             float,
                             float,
                             float,
                             float,
                             float,
                             float,
                             object,  # user_data
                          ], None],
                          user_data: object = None) -> None:
        cdef hb_draw_cubic_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._cubic_to_func = None
            func_p = <hb_draw_cubic_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._cubic_to_func = func
            func_p = _cubic_to_func
            user_data_p = <void*>user_data
        hb_draw_funcs_set_cubic_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_quadratic_to_func(self,
                              func: Callable[[
                                 float,
                                 float,
                                 float,
                                 float,
                                 object,  # user_data
                              ], None],
                              user_data: object = None) -> None:
        cdef hb_draw_quadratic_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._quadratic_to_func = None
            func_p = <hb_draw_quadratic_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._quadratic_to_func = func
            func_p = _quadratic_to_func
            user_data_p = <void*>user_data
        hb_draw_funcs_set_quadratic_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_close_path_func(self,
                            func: Callable[[
                                object
                            ], None],
                            user_data: object = None) -> None:
        cdef hb_draw_close_path_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._close_path_func = None
            func_p = <hb_draw_close_path_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._close_path_func = func
            func_p = _close_path_func
            user_data_p = <void*>user_data
        hb_draw_funcs_set_close_path_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

cdef class HBObject:
    cdef hb_object_t* _hb_obj_list
    cdef unsigned int _num

    def __cinit__(self, num_nodes):
        self._hb_obj_list = <hb_object_t*>calloc(num_nodes, sizeof(hb_object_t))
        if self._hb_obj_list == NULL:
            raise MemoryError()
        self._num = num_nodes

    def __dealloc__(self):
        if self._hb_obj_list != NULL:
            for i in range(self._num):
                if self._hb_obj_list[i].real_links != NULL:
                    free(self._hb_obj_list[i].real_links)
                if self._hb_obj_list[i].virtual_links != NULL:
                    free(self._hb_obj_list[i].virtual_links)
            free(self._hb_obj_list)

    cdef update_obj_length(self,
                           unsigned int idx,
                           char* head,
                           char* tail):
        self._hb_obj_list[idx].head = head
        self._hb_obj_list[idx].tail = tail
       
    cdef hb_link_t* create_links(self, unsigned int idx,
                                 unsigned int link_num,
                                 bint is_real_link):
        if link_num == 0:
            return NULL
        
        cdef hb_link_t* p = <hb_link_t*>calloc(link_num, sizeof(hb_link_t))
        if p == NULL:
            raise MemoryError()
        
        if is_real_link:
            self._hb_obj_list[idx].num_real_links = link_num
            self._hb_obj_list[idx].real_links = p
        else:
            self._hb_obj_list[idx].num_virtual_links = link_num
            self._hb_obj_list[idx].virtual_links = p
        return p

    cdef update_links(self, unsigned int idx, bint is_real_link,
                      links: List[Tuple[int, int, int]]):
        cdef unsigned int num_links = len(links)
        cdef hb_link_t* l = NULL
        if is_real_link:
            l = self._hb_obj_list[idx].real_links
        else:
            l = self._hb_obj_list[idx].virtual_links
        
        for i in range(num_links):
            l[i].position = links[i][0]
            l[i].width = links[i][1]
            l[i].objidx = links[i][2]

class RepackerError(Exception):
    pass


def repack(subtables: List[bytes],
           graphnodes: List[Tuple[List[Tuple[int, int, int]],
                            List[Tuple[int, int, int]]
                            ]]) -> bytes:
    return repack_with_tag("", subtables, graphnodes)


def repack_with_tag(tag: str,
                    subtables: List[bytes],
                    graphnodes: List[Tuple[List[Tuple[int, int, int]],
                                     List[Tuple[int, int, int]]
                                     ]]) -> bytes:

    """The whole table is represented as a Graph
       and the input graphnodes is a flat list of subtables
       with each node(subtable) represented by a tuple of 2
       list: real_link list and virtual_link list.

       A link(egde) is an offset link between parent table and
       child table. It's represented in the format of a tuple: 
       (posiiton: int, width: int, objidx: int):

       - position: means relative position of the offset field
         in bytes from the beginning of the subtable's C struct.
         e.g:
         a GSUB header struct in C looks like below:
         
         uint16 majorVersion
         uint16 minorVersion
         offset16 scriptListOffset
         offset16 featureListOffset
         offset16 lookupListOffset
         And the position for scriptListOffset is 4 
         which is calculated from (16+16)/8
       - width: size of the offset:
         e.g 2 for offset16 and 4 for offset32
       - objidx: objidx is the index of the subtable
         in graph/tree generated by postorder traversal

       There're 2 types of links:
       - real_link represents an real offset field in the parent table
       - virtual_link is not real offset link, it specifies an ordering
         constraint that harfbuzz packing must follow.
         A virtual link would have 0 width, 0 position, and a real objidx.
         e.g:
         if Node A has a virtual link with objidx b(corresponding Node is B),
         then that means Node B is always packed after Node A in the final
         serialized order
         """

    if len(subtables) != len(graphnodes):
        raise ValueError(
            f"Input num of subtables({len(subtables)}) != num of graph nodes({len(graphnodes)})"
        )
    cdef:
        unsigned int num_nodes = len(subtables)
        bytes table_bytes = b''.join(subtables)
        char* table_data = table_bytes
        unsigned int head = 0, tail = 0
        hb_link_t* p = NULL
        HBObject obj_list = HBObject(num_nodes)
    for i in range(num_nodes):
        tail += len(subtables[i])
        obj_list.update_obj_length(i, table_data + head, table_data + tail)
        head = tail
        
        node = graphnodes[i]
        # real_links
        p = obj_list.create_links(i, len(node[0]), True)
        if p != NULL:
            obj_list.update_links(i, True, node[0])
        # virtual_links
        p = obj_list.create_links(i, len(node[1]), False)
        if p != NULL:
            obj_list.update_links(i, False, node[1])

    cdef bytes tag_packed = tag.encode()
    cdef char* cstr = tag_packed
    cdef hb_blob_t* packed_blob = hb_subset_repack_or_fail(hb_tag_from_string(cstr, -1),
							   obj_list._hb_obj_list,
							   num_nodes)
    if packed_blob == NULL:
        raise RepackerError()
    
    cdef unsigned int blob_length
    cdef const_char* blob_data = hb_blob_get_data(packed_blob, &blob_length)
    cdef bytes packed = blob_data[:blob_length]
    
    hb_blob_destroy(packed_blob)
    return packed


def subset_preprocess(face: Face) -> Face:
    new_face = hb_subset_preprocess(face._hb_face)
    return Face.from_ptr(new_face)


cdef class SubsetInput:
    cdef hb_subset_input_t* _input

    def __cinit__(self):
        self._input = hb_subset_input_create_or_fail()
        if self._input is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._input is not NULL:
            hb_subset_input_destroy(self._input)

    def pin_axis_to_default(self, face: Face, tag: str) -> bool:
        hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        return hb_subset_input_pin_axis_to_default(
            self._input, face._hb_face, hb_tag
        )

    def pin_axis_location(self, face: Face, tag: str, value: float) -> bool:
        hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        return hb_subset_input_pin_axis_location(
            self._input, face._hb_face, hb_tag, value
        )

    @property
    def unicode_set(self) -> Set:
        raise NotImplementedError

    @property
    def glyph_set(self) -> Set:
        raise NotImplementedError

    @property
    def no_subset_table_set(self) -> Set:
        raise NotImplementedError

    @property
    def drop_table_set(self) -> Set:
        raise NotImplementedError

    @property
    def name_id_set(self) -> Set:
        raise NotImplementedError

    @property
    def name_lang_set(self) -> Set:
        raise NotImplementedError

    @property
    def layout_feature_set(self) -> Set:
        raise NotImplementedError

    @property
    def layout_script_set(self) -> Set:
        raise NotImplementedError

    @property
    def flags(self) -> SubsetFlags:
        cdef unsigned subset_flags = hb_subset_input_get_flags(self._input)
        return SubsetFlags(subset_flags)

    @flags.setter
    def flags(self, flags: SubsetFlags) -> None:
        hb_subset_input_set_flags(self._input, int(flags))


class SubsetFlags(IntFlag):
    DEFAULT = HB_SUBSET_FLAGS_DEFAULT
    NO_HINTING = HB_SUBSET_FLAGS_NO_HINTING
    RETAIN_GIDS = HB_SUBSET_FLAGS_RETAIN_GIDS
    DESUBROUTINIZE = HB_SUBSET_FLAGS_DESUBROUTINIZE
    NAME_LEGACY = HB_SUBSET_FLAGS_NAME_LEGACY
    SET_OVERLAPS_FLAG = HB_SUBSET_FLAGS_SET_OVERLAPS_FLAG
    PASSTHROUGH_UNRECOGNIZED = HB_SUBSET_FLAGS_PASSTHROUGH_UNRECOGNIZED
    NOTDEF_OUTLINE = HB_SUBSET_FLAGS_NOTDEF_OUTLINE
    GLYPH_NAMES = HB_SUBSET_FLAGS_GLYPH_NAMES
    NO_PRUNE_UNICODE_RANGES = HB_SUBSET_FLAGS_NO_PRUNE_UNICODE_RANGES


cdef class Set:
    cdef hb_set_t* _set

    def __cinit__(self):
        self._set = hb_set_create()
        if self._set is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._set is not NULL:
            hb_set_destroy(self._set)


cdef class Map:
    cdef hb_map_t* _map

    def __cinit__(self):
        self._map = hb_map_create()
        if self._map is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._map is not NULL:
            hb_map_destroy(self._map)
