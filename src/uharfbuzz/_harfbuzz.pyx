#cython: language_level=3
cimport cython
import os
import warnings
from enum import IntEnum, IntFlag
from .charfbuzz cimport *
from libc.stdlib cimport free, malloc, calloc
from libc.string cimport const_char
from cpython.pycapsule cimport PyCapsule_GetPointer, PyCapsule_IsValid
from cpython.unicode cimport (
    PyUnicode_1BYTE_DATA, PyUnicode_2BYTE_DATA, PyUnicode_4BYTE_DATA,
    PyUnicode_1BYTE_KIND, PyUnicode_2BYTE_KIND, PyUnicode_4BYTE_KIND,
    PyUnicode_KIND, PyUnicode_GET_LENGTH, PyUnicode_FromKindAndData
)
from typing import Callable, Dict, List, Sequence, Tuple, Union, NamedTuple
from pathlib import Path
from functools import wraps


DEF STATIC_ARRAY_SIZE = 128


cdef int msgcallback(hb_buffer_t *buffer, hb_font_t *font, const char* message, void* userdata) noexcept:
    ret = (<object>userdata)(message.decode('utf-8'))
    if ret is None:
        return 1
    return ret


def version_string() -> str:
    cdef const char* cstr = hb_version_string()
    cdef bytes packed = cstr
    return packed.decode()


WARNED = set()


def deprecated(replacement=None):
    """Decorator to raise a warning when a deprecated function is called."""

    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            message = f"{func.__name__!r} is deprecated"
            if replacement:
                message += f", use {replacement} instead"
            if message not in WARNED:
                warnings.warn(message, DeprecationWarning)
                WARNED.add(message)
            return func(*args, **kwargs)

        return wrapper

    return decorator


class HarfBuzzError(Exception):
    pass


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
    def create(cls):
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
                       item_offset: int = 0, item_length: int = -1) -> None:
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
                 item_offset: int = 0, item_length: int = -1) -> None:
        hb_buffer_add_utf8(
            self._hb_buffer, text, len(text), item_offset, item_length)
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()

    def add_str(self, text: str,
                item_offset: int = 0, item_length: int = -1) -> None:

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
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()

    def guess_segment_properties(self) -> None:
        hb_buffer_guess_segment_properties(self._hb_buffer)

    def set_message_func(self, callback) -> None:
        self._message_callback = callback
        hb_buffer_set_message_func(self._hb_buffer, msgcallback, <void*>callback, NULL)


cdef class Blob:
    cdef hb_blob_t* _hb_blob

    def __cinit__(self, bytes data = None):
        if data is not None:
            self._hb_blob = hb_blob_create(
                data, len(data), HB_MEMORY_MODE_DUPLICATE, NULL, NULL)
        else:
            self._hb_blob = hb_blob_get_empty()

    @staticmethod
    cdef Blob from_ptr(hb_blob_t* hb_blob):
        """Create Blob from a pointer taking ownership of a it."""

        cdef Blob wrapper = Blob.__new__(Blob)
        wrapper._hb_blob = hb_blob
        return wrapper

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

    def __len__(self) -> int:
        return hb_blob_get_length(self._hb_blob)

    def __bool__(self) -> bool:
        return len(self) > 0

    @property
    def data(self) -> bytes:
        """Return the blob's data as bytes."""
        if not self:
            return b""
        cdef unsigned int blob_length
        cdef const_char* blob_data = hb_blob_get_data(self._hb_blob, &blob_length)
        return blob_data[:blob_length]


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
        """Create Face from a pointer taking ownership of a it."""

        cdef Face wrapper = Face.__new__(Face)
        wrapper._hb_face = hb_face
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
    def unicodes (self):
        s = Set()
        hb_face_collect_unicodes(self._hb_face, s._hb_set)
        return s

    @property
    def variation_selectors(self):
        s = Set()
        hb_face_collect_variation_selectors(self._hb_face, s._hb_set)
        return s

    def variation_unicodes(self, variation_selector):
        s = Set()
        hb_face_collect_variation_unicodes(self._hb_face, variation_selector, s._hb_set)
        return s

    # variations
    @property
    def has_var_data(self) -> bool:
        return hb_ot_var_has_data(self._hb_face)

    @property
    def axis_infos(self) -> list[OTVarAxisInfo]:
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
    def named_instances(self) -> list[OTVarNamedInstance]:
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
    def color_palettes(self) -> list[OTColorPalette]:
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
        cdef uint32_t *text
        cdef unsigned int length

        if language is None:
            lang = <hb_language_t>0  # HB_LANGUAGE_INVALID
        else:
            packed = language.encode()
            lang = hb_language_from_string(<char*>packed, -1)

        length = hb_ot_name_get_utf32(self._hb_face, name_id, lang, NULL, NULL)
        if length:
            length += 1  # for the null terminator
            text = <uint32_t*>malloc(length * sizeof(uint32_t))
            hb_ot_name_get_utf32(self._hb_face, name_id, lang, &length, text)
            return PyUnicode_FromKindAndData(PyUnicode_4BYTE_KIND, text, length)
        return None


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

    @property
    def synthetic_slant(self) -> float:
        return hb_font_get_synthetic_slant(self._hb_font)

    @synthetic_slant.setter
    def synthetic_slant(self, value: float):
        hb_font_set_synthetic_slant(self._hb_font, value)

    @property
    def synthetic_bold(self) -> tuple[float, float, bool]:
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

    def set_variation(self, name: str, value: float) -> None:
        packed = name.encode()
        cdef hb_tag_t tag = hb_tag_from_string(packed, -1)
        hb_font_set_variation(self._hb_font, tag, value)

    def get_glyph_name(self, gid: int):
        cdef char name[64]
        cdef bytes packed
        success = hb_font_get_glyph_name(self._hb_font, gid, name, 64)
        if success:
            packed = name
            return packed.decode()
        else:
            return None

    def get_glyph_from_name(self, name: str):
        cdef hb_codepoint_t gid
        cdef bytes packed
        packed = name.encode()
        success = hb_font_get_glyph_from_name(self._hb_font, <char*>packed, len(packed), &gid)
        return gid if success else None

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

    def get_glyph_h_advance(self, gid: int):
        return hb_font_get_glyph_h_advance(self._hb_font, gid)

    def get_glyph_v_advance(self, gid: int):
        return hb_font_get_glyph_v_advance(self._hb_font, gid)

    def get_glyph_h_origin(self, gid: int):
        cdef hb_position_t x, y
        success = hb_font_get_glyph_h_origin(self._hb_font, gid, &x, &y)
        return (x, y) if success else None

    def get_glyph_v_origin(self, gid: int):
        cdef hb_position_t x, y
        success = hb_font_get_glyph_v_origin(self._hb_font, gid, &x, &y)
        return (x, y) if success else None

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

    def get_variation_glyph(self, unicode: int, variation_selector: int):
        cdef hb_codepoint_t gid
        success = hb_font_get_variation_glyph(self._hb_font, unicode, variation_selector, &gid)
        return gid if success else None

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

    def get_var_coords_design(self):
        cdef unsigned int length
        cdef const float *coords
        coords = hb_font_get_var_coords_design(self._hb_font, &length)
        return [coords[i] for i in range(length)]

    def set_var_coords_design(self, coords):
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

    def glyph_to_string(self, gid: int):
        cdef char name[64]
        cdef bytes packed
        hb_font_glyph_to_string(self._hb_font, gid, name, 64)
        packed = name
        return packed.decode()

    def glyph_from_string(self, string: str):
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
                    foreground: Color | None = None) -> None:
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

    def get_math_glyph_kerning(self, glyph: int, kern: OTMathKern, int correction_height) -> int:
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
    def create(cls):
        cdef FontFuncs inst = cls()
        return inst

    def set_glyph_h_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # h_advance
                                 user_data: object = None) -> None:
        hb_font_funcs_set_glyph_h_advance_func(
            self._hb_ffuncs, _glyph_h_advance_func, <void*>user_data, NULL)
        self._glyph_h_advance_func = func

    def set_glyph_v_advance_func(self,
                                 func: Callable[[
                                     Font,
                                     int,  # gid
                                     object,  # user_data
                                 ], int],  # v_advance
                                 user_data: object = None) -> None:
        hb_font_funcs_set_glyph_v_advance_func(
            self._hb_ffuncs, _glyph_v_advance_func, <void*>user_data, NULL)
        self._glyph_v_advance_func = func

    def set_glyph_v_origin_func(self,
                                func: Callable[[
                                    Font,
                                    int,  # gid
                                    object,  # user_data
                                ], (int, int, int)],  # success, v_origin_x, v_origin_y
                                user_data: object = None) -> None:
        hb_font_funcs_set_glyph_v_origin_func(
            self._hb_ffuncs, _glyph_v_origin_func, <void*>user_data, NULL)
        self._glyph_v_origin_func = func

    def set_glyph_name_func(self,
                            func: Callable[[
                                Font,
                                int,  # gid
                                object,  # user_data
                            ], str],  # name
                            user_data: object = None) -> None:
        hb_font_funcs_set_glyph_name_func(
            self._hb_ffuncs, _glyph_name_func, <void*>user_data, NULL)
        self._glyph_name_func = func

    def set_nominal_glyph_func(self,
                               func: Callable[[
                                   Font,
                                   int,  # unicode
                                   object,  # user_data
                               ], int],  # gid
                               user_data: object = None) -> None:
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
                               user_data: object = None) -> None:
        hb_font_funcs_set_variation_glyph_func(
            self._hb_ffuncs, _variation_glyph_func, <void*>user_data, NULL)
        self._variation_glyph_func = func

    def set_font_h_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object = None) -> None:
        hb_font_funcs_set_font_h_extents_func(
            self._hb_ffuncs, _font_h_extents_func, <void*>user_data, NULL)
        self._font_h_extents_func = func

    def set_font_v_extents_func(self,
                                func: Callable[[
                                    Font,
                                    object,  # user_data
                                ], FontExtents],  # extents
                                user_data: object = None) -> None:
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
        if not hb_buffer_allocation_successful(buffer._hb_buffer):
            raise MemoryError()
    finally:
        if hb_features is not NULL:
            free(hb_features)


def ot_tag_to_script(tag: str) -> str:
    cdef bytes packed = tag.encode()
    cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
    cdef hb_script_t hb_script = hb_ot_tag_to_script(hb_tag)
    cdef char cstr[5]
    hb_tag_to_string(hb_script, cstr)
    cstr[4] = b'\0'
    packed = cstr
    return packed.decode()


def ot_tag_to_language(tag: str) -> str:
    cdef bytes packed = tag.encode()
    cdef hb_tag_t hb_tag = hb_tag_from_string(<char*>packed, -1)
    cdef hb_language_t hb_language = hb_ot_tag_to_language(hb_tag)
    cdef const_char* cstr = hb_language_to_string(hb_language)
    if cstr is NULL:
        return None
    packed = cstr
    return packed.decode()


@deprecated("Face.get_lookup_glyph_alternates()")
def ot_layout_lookup_get_glyph_alternates(
        face: Face, lookup_index : int, glyph : hb_codepoint_t) -> List[int]:
   return face.get_lookup_glyph_alternates(lookup_index, glyph)


@deprecated("Face.get_language_feature_tags()")
def ot_layout_language_get_feature_tags(
        face: Face, tag: str, script_index: int = 0,
        language_index: int = 0xFFFF) -> List[str]:
    return face.get_language_feature_tags(tag, script_index, language_index)


@deprecated("Face.get_script_language_tags()")
def ot_layout_script_get_language_tags(
        face: Face, tag: str, script_index: int = 0) -> List[str]:
    return face.get_script_language_tags(tag, script_index)

@deprecated("Face.get_table_script_tags()")
def ot_layout_table_get_script_tags(face: Face, tag: str) -> List[str]:
    return face.get_table_script_tags(tag)

@deprecated("Face.get_layout_baseline()")
def ot_layout_get_baseline(font: Font,
                           baseline_tag: str,
                           direction: str,
                           script_tag: str,
                           language_tag: str) -> int:
    return font.get_layout_baseline(baseline_tag, direction, script_tag, language_tag)

@deprecated("Face.face.has_layout_glyph_classes")
def ot_layout_has_glyph_classes(face: Face) -> bool:
    return face.has_layout_glyph_classes

@deprecated("Face.has_layout_positioning")
def ot_layout_has_positioning(face: Face) -> bool:
    return face.has_layout_positioning

@deprecated("Face.has_layout_substitution")
def ot_layout_has_substitution(face: Face) -> bool:
    return face.has_layout_substitution

@deprecated("Face.get_layout_glyph_class()")
def ot_layout_get_glyph_class(face: Face, glyph: int) -> OTLayoutGlyphClass:
    return face.get_layout_glyph_class(glyph)

@deprecated("Face.has_color_palettes")
def ot_color_has_palettes(face: Face) -> bool:
    return face.has_color_palettes

@deprecated("Face.color_palettes")
def ot_color_palette_get_count(face: Face) -> int:
    return hb_ot_color_palette_get_count(face._hb_face)

@deprecated("Face.get_color_palette()")
def ot_color_palette_get_flags(face: Face, palette_index: int) -> OTColorPaletteFlags:
    return OTColorPaletteFlags(hb_ot_color_palette_get_flags(face._hb_face, palette_index))

@deprecated("Face.get_color_palette()")
def ot_color_palette_get_colors(face: Face, palette_index: int) -> List[Color]:
    cdef list ret = []
    cdef unsigned int i
    cdef unsigned int start_offset = 0
    cdef unsigned int color_count = STATIC_ARRAY_SIZE
    cdef hb_color_t colors[STATIC_ARRAY_SIZE]
    while color_count == STATIC_ARRAY_SIZE:
        hb_ot_color_palette_get_colors(face._hb_face, palette_index, start_offset, &color_count, colors)
        for i in range(color_count):
            ret.append(Color.from_int(colors[i]))
    return ret

@deprecated("Face.get_color_palette()")
def ot_color_palette_get_name_id(face: Face, palette_index: int) -> int | None:
    cdef hb_ot_name_id_t name_id
    name_id = hb_ot_color_palette_get_name_id(face._hb_face, palette_index)
    if name_id == HB_OT_NAME_ID_INVALID:
        return None
    return name_id

@deprecated("Face.color_palette_color_get_name_id()")
def ot_color_palette_color_get_name_id(face: Face, color_index: int) -> int | None:
    return face.color_palette_color_get_name_id(color_index)

@deprecated("Face.has_color_layers")
def ot_color_has_layers(face: Face) -> bool:
    return face.has_color_layers

@deprecated("Face.get_glyph_color_layers()")
def ot_color_glyph_get_layers(face: Face, glyph: int) -> List[OTColorLayer]:
    return face.get_glyph_color_layers(glyph)

@deprecated("Face.has_color_paint")
def ot_color_has_paint(face: Face) -> bool:
    return face.has_color_paint

@deprecated("Face.glyph_has_color_paint()")
def ot_color_glyph_has_paint(face: Face, glyph: int) -> bool:
    return face.glyph_has_color_paint(glyph)

@deprecated("Face.has_color_svg")
def ot_color_has_svg(face: Face) -> bool:
    return face.has_color_svg

@deprecated("Face.get_glyph_color_svg()")
def ot_color_glyph_get_svg(face: Face, glyph: int) -> Blob:
    return face.get_glyph_color_svg(glyph)

@deprecated("Face.has_color_png")
def ot_color_has_png(face: Face) -> bool:
    return face.has_color_png

@deprecated("Font.get_glyph_color_png()")
def ot_color_glyph_get_png(font: Font, glyph: int) -> Blob:
    return font.get_glyph_color_png(glyph)


@deprecated("Face.has_math_data")
def ot_math_has_data(face: Face) -> bool:
    return face.has_math_data

@deprecated("Font.get_math_constant()")
def ot_math_get_constant(font: Font, constant: OTMathConstant) -> int:
    return font.get_math_constant(constant)

@deprecated("Font.get_math_glyph_italics_correction()")
def ot_math_get_glyph_italics_correction(font: Font, glyph: int) -> int:
    return font.get_math_glyph_italics_correction(glyph)

@deprecated("Font.get_math_glyph_top_accent_attachment()")
def ot_math_get_glyph_top_accent_attachment(font: Font, glyph: int) -> int:
    return font.get_math_glyph_top_accent_attachment(glyph)

@deprecated("Face.is_glyph_extended_math_shape()")
def ot_math_is_glyph_extended_shape(face: Face, glyph: int) -> bool:
    return face.is_glyph_extended_math_shape(glyph)

@deprecated("Font.get_math_min_connector_overlap()")
def ot_math_get_min_connector_overlap(font: Font, direction: str) -> int:
    return font.get_math_min_connector_overlap(direction)

@deprecated("Font.get_math_glyph_kerning()")
def ot_math_get_glyph_kerning(font: Font,
                              glyph: int,
                              kern: OTMathKern,
                              int correction_height) -> int:
    return font.get_math_glyph_kerning(glyph, kern, correction_height)

@deprecated("Font.get_math_glyph_kernings()")
def ot_math_get_glyph_kernings(font: Font,
                               glyph: int,
                               kern: OTMathKern) -> List[OTMathKernEntry]:
    return font.get_math_glyph_kernings(glyph, kern)

@deprecated("Font.get_math_glyph_variants()")
def ot_math_get_glyph_variants(font: Font, glyph: int, direction: str) -> List[OTMathGlyphVariant]:
    return font.get_math_glyph_variants(glyph, direction)

@deprecated("Font.get_math_glyph_assembly()")
def ot_math_get_glyph_assembly(font: Font,
                               glyph: int,
                               direction: str) -> Tuple[List[OTMathGlyphPart], int]:
    return font.get_math_glyph_assembly(glyph, direction)


def ot_font_set_funcs(Font font):
    hb_ot_font_set_funcs(font._hb_font)


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
                                ], None]) -> None:
        self._push_transform_func = func
        hb_paint_funcs_set_push_transform_func(
            self._hb_paintfuncs, _paint_push_transform_func, <void*>self, NULL)

    def set_pop_transform_func(self,
                               func: Callable[[
                                   object,  # paint_data
                               ], None]) -> None:
        self._pop_transform_func = func
        hb_paint_funcs_set_pop_transform_func(
            self._hb_paintfuncs, _paint_pop_transform_func, <void*>self, NULL)

    def set_color_glyph_func(self,
                             func: Callable[[
                                 int,  # gid
                                 object,  # paint_data
                             ], bool]) -> None:
        self._color_glyph_func = func
        hb_paint_funcs_set_color_glyph_func(
            self._hb_paintfuncs, _paint_color_glyph_func, <void*>self, NULL)

    def set_push_clip_glyph_func(self,
                                 func: Callable[[
                                     int,  # gid
                                     object,  # paint_data
                                 ], None]) -> None:
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
                                     ], None]) -> None:
        self._push_clip_rectangle_func = func
        hb_paint_funcs_set_push_clip_rectangle_func(
            self._hb_paintfuncs, _paint_push_clip_rectangle_func, <void*>self, NULL)

    def set_pop_clip_func(self,
                          func: Callable[[
                              object,  # paint_data
                          ], None]) -> None:
        self._pop_clip_func = func
        hb_paint_funcs_set_pop_clip_func(
            self._hb_paintfuncs, _paint_pop_clip_func, <void*>self, NULL)

    def set_color_func(self,
                       func: Callable[[
                           Color,  # color
                           bool,  # is_foreground
                           object,  # paint_data
                       ], None]) -> None:
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
                       ], bool]) -> None:
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
                                 ], None]) -> None:
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
                                 ], None]) -> None:
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
                                ], None]) -> None:
        self._sweep_gradient_func = func
        hb_paint_funcs_set_sweep_gradient_func(
            self._hb_paintfuncs, _paint_sweep_gradient_func, <void*>self, NULL)

    def set_push_group_func(self,
                            func: Callable[[
                                object,  # paint_data
                            ], None]) -> None:
        self._push_group_func = func
        hb_paint_funcs_set_push_group_func(
            self._hb_paintfuncs, _paint_push_group_func, <void*>self, NULL)

    def set_pop_group_func(self,
                           func: Callable[[
                               PaintCompositeMode,  # mode
                               object,  # paint_data
                           ], None]) -> None:
        self._pop_group_func = func
        hb_paint_funcs_set_pop_group_func(
            self._hb_paintfuncs, _paint_pop_group_func, <void*>self, NULL)

    def set_custom_palette_color_func(self,
                                      func: Callable[[
                                          int,  # color_index
                                          object,  # paint_data
                                      ], Color]) -> None:
        self._custom_palette_color_func = func
        hb_paint_funcs_set_custom_palette_color_func(
            self._hb_paintfuncs, _paint_custom_palette_color_func, <void*>self, NULL)


cdef void _move_to_func(hb_draw_funcs_t *dfuncs,
                        void *draw_data,
                        hb_draw_state_t *st,
                        float to_x,
                        float to_y,
                        void *user_data) noexcept:
    m = <object>user_data
    m(to_x, to_y, <object>draw_data)

cdef void _line_to_func(hb_draw_funcs_t *dfuncs,
                        void *draw_data,
                        hb_draw_state_t *st,
                        float to_x,
                        float to_y,
                        void *user_data) noexcept:
    l = <object>user_data
    l(to_x, to_y, <object>draw_data)

cdef void _close_path_func(hb_draw_funcs_t *dfuncs,
                           void *draw_data,
                           hb_draw_state_t *st,
                           void *user_data) noexcept:
    cl = <object>user_data
    cl(<object>draw_data)

cdef void _quadratic_to_func(hb_draw_funcs_t *dfuncs,
                             void *draw_data,
                             hb_draw_state_t *st,
                             float c1_x,
                             float c1_y,
                             float to_x,
                             float to_y,
                             void *user_data) noexcept:
    q = <object>user_data
    q(c1_x, c1_y, to_x, to_y, <object>draw_data)

cdef void _cubic_to_func(hb_draw_funcs_t *dfuncs,
                         void *draw_data,
                         hb_draw_state_t *st,
                         float c1_x,
                         float c1_y,
                         float c2_x,
                         float c2_y,
                         float to_x,
                         float to_y,
                         void *user_data) noexcept:
    c = <object>user_data
    c(c1_x, c1_y, c2_x, c2_y, to_x, to_y, <object>draw_data)


cdef class DrawFuncs:
    cdef hb_draw_funcs_t* _hb_drawfuncs
    cdef object _move_to_func
    cdef object _line_to_func
    cdef object _cubic_to_func
    cdef object _quadratic_to_func
    cdef object _close_path_func

    def __cinit__(self):
        self._hb_drawfuncs = hb_draw_funcs_create()

    def __dealloc__(self):
        hb_draw_funcs_destroy(self._hb_drawfuncs)

    @deprecated("Font.draw_glyph()")
    def get_glyph_shape(self, font: Font, gid: int):
        font.draw_glyph(gid, self)

    @deprecated("Font.draw_glyph()")
    def draw_glyph(self, font: Font, gid: int, draw_data: object = None):
        font.draw_glyph(gid, self, draw_data)

    def set_move_to_func(self,
                         func: Callable[[
                             float,
                             float,
                             object,  # draw_data
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
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_move_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_line_to_func(self,
                         func: Callable[[
                             float,
                             float,
                             object,  # draw_data
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
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
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
                             object,  # draw_data
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
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_cubic_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_quadratic_to_func(self,
                              func: Callable[[
                                 float,
                                 float,
                                 float,
                                 float,
                                 object,  # draw_data
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
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
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
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_close_path_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

cdef class HBObject:
    cdef hb_subset_serialize_object_t* _hb_obj_list
    cdef unsigned int _num

    def __cinit__(self, num_nodes):
        self._hb_obj_list = <hb_subset_serialize_object_t*>calloc(num_nodes, sizeof(hb_subset_serialize_object_t))
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

    cdef hb_subset_serialize_link_t* create_links(self, unsigned int idx,
                                                  unsigned int link_num,
                                                  bint is_real_link):
        if link_num == 0:
            return NULL

        cdef hb_subset_serialize_link_t* p = <hb_subset_serialize_link_t*>calloc(link_num, sizeof(hb_subset_serialize_link_t))
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
        cdef hb_subset_serialize_link_t* l = NULL
        if is_real_link:
            l = self._hb_obj_list[idx].real_links
        else:
            l = self._hb_obj_list[idx].virtual_links

        for i in range(num_links):
            l[i].position = links[i][0]
            l[i].width = links[i][1]
            l[i].objidx = links[i][2]

class SerializerError(Exception):
    pass

class RepackerError(SerializerError):
    pass


@deprecated("serialize()")
def repack(subtables, graphnodes):
    return serialize(subtables, graphnodes)


@deprecated("serialize_with_tag()")
def repack_with_tag(tag, subtables, graphnodes):
    return serialize_with_tag(tag, subtables, graphnodes)


def serialize(subtables: List[bytes],
              graphnodes: List[Tuple[List[Tuple[int, int, int]],
                                     List[Tuple[int, int, int]]
                                     ]]) -> bytes:
    return serialize_with_tag("", subtables, graphnodes)


def serialize_with_tag(tag: str,
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
        hb_subset_serialize_link_t* p = NULL
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
    cdef hb_blob_t* packed_blob = hb_subset_serialize_or_fail(hb_tag_from_string(cstr, -1),
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

def subset(face: Face, input: SubsetInput) -> Face:
    new_face = hb_subset_or_fail(face._hb_face, input._hb_input)
    if new_face == NULL:
        raise RuntimeError("Subsetting failed")
    return Face.from_ptr(new_face)

class SubsetInputSets(IntEnum):
    GLYPH_INDEX = HB_SUBSET_SETS_GLYPH_INDEX
    UNICODE = HB_SUBSET_SETS_UNICODE
    NO_SUBSET_TABLE_TAG = HB_SUBSET_SETS_NO_SUBSET_TABLE_TAG
    DROP_TABLE_TAG = HB_SUBSET_SETS_DROP_TABLE_TAG
    NAME_ID = HB_SUBSET_SETS_NAME_ID
    NAME_LANG_ID = HB_SUBSET_SETS_NAME_LANG_ID
    LAYOUT_FEATURE_TAG = HB_SUBSET_SETS_LAYOUT_FEATURE_TAG
    LAYOUT_SCRIPT_TAG = HB_SUBSET_SETS_LAYOUT_SCRIPT_TAG


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
    NO_LAYOUT_CLOSURE = HB_SUBSET_FLAGS_NO_LAYOUT_CLOSURE


cdef class SubsetInput:
    cdef hb_subset_input_t* _hb_input

    def __cinit__(self):
        self._hb_input = hb_subset_input_create_or_fail()
        if self._hb_input is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._hb_input is not NULL:
            hb_subset_input_destroy(self._hb_input)

    def subset(self, source: Face) -> Face:
        return subset(source, self)

    def keep_everything(self):
        hb_subset_input_keep_everything(self._hb_input)

    def pin_axis_to_default(self, face: Face, tag: str) -> bool:
        hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        return hb_subset_input_pin_axis_to_default(
            self._hb_input, face._hb_face, hb_tag
        )

    def pin_axis_location(self, face: Face, tag: str, value: float) -> bool:
        hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        return hb_subset_input_pin_axis_location(
            self._hb_input, face._hb_face, hb_tag, value
        )

    @property
    def unicode_set(self) -> Set:
        return Set.from_ptr(hb_set_reference (hb_subset_input_unicode_set(self._hb_input)))

    @property
    def glyph_set(self) -> Set:
        return Set.from_ptr(hb_set_reference (hb_subset_input_glyph_set(self._hb_input)))

    def sets(self, set_type : SubsetInputSets) -> Set:
        return Set.from_ptr(hb_set_reference (hb_subset_input_set(self._hb_input, set_type)))

    @property
    def no_subset_table_tag_set(self) -> Set:
        return self.sets(SubsetInputSets.NO_SUBSET_TABLE_TAG)

    @property
    def drop_table_tag_set(self) -> Set:
        return self.sets(SubsetInputSets.DROP_TABLE_TAG)

    @property
    def name_id_set(self) -> Set:
        return self.sets(SubsetInputSets.NAME_ID)

    @property
    def name_lang_id_set(self) -> Set:
        return self.sets(SubsetInputSets.NAME_LANG_ID)

    @property
    def layout_feature_tag_set(self) -> Set:
        return self.sets(SubsetInputSets.LAYOUT_FEATURE_TAG)

    @property
    def layout_script_tag_set(self) -> Set:
        return self.sets(SubsetInputSets.LAYOUT_SCRIPT_TAG)

    @property
    def flags(self) -> SubsetFlags:
        cdef unsigned subset_flags = hb_subset_input_get_flags(self._hb_input)
        return SubsetFlags(subset_flags)

    @flags.setter
    def flags(self, flags: SubsetFlags) -> None:
        hb_subset_input_set_flags(self._hb_input, int(flags))


cdef class SubsetPlan:
    cdef hb_subset_plan_t* _hb_plan

    def __cinit__(self, face: Face, input: SubsetInput):
        self._hb_plan = hb_subset_plan_create_or_fail(face._hb_face, input._hb_input)
        if self._hb_plan is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._hb_plan is not NULL:
            hb_subset_plan_destroy(self._hb_plan)

    def execute(self) -> Face:
        new_face = hb_subset_plan_execute_or_fail(self._hb_plan)
        if new_face == NULL:
            raise RuntimeError("Subsetting failed")
        return Face.from_ptr(new_face)

    @property
    def old_to_new_glyph_mapping(self) -> Map:
        return Map.from_ptr(hb_map_reference (<hb_map_t*>hb_subset_plan_old_to_new_glyph_mapping(self._hb_plan)))

    @property
    def new_to_old_glyph_mapping(self) -> Map:
        return Map.from_ptr(hb_map_reference (<hb_map_t*>hb_subset_plan_new_to_old_glyph_mapping(self._hb_plan)))

    @property
    def unicode_to_old_glyph_mapping(self) -> Map:
        return Map.from_ptr(hb_map_reference (<hb_map_t*>hb_subset_plan_unicode_to_old_glyph_mapping(self._hb_plan)))


cdef class Set:
    cdef hb_set_t* _hb_set

    INVALID_VALUE = HB_SET_VALUE_INVALID

    def __cinit__(self, init = set()):
        self._hb_set = hb_set_create()
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

        self.set(init)

    def __dealloc__(self):
        hb_set_destroy(self._hb_set)

    @staticmethod
    cdef Set from_ptr(hb_set_t* hb_set):
        """Create Set from a pointer taking ownership of a it."""

        cdef Set wrapper = Set.__new__(Set)
        wrapper._hb_set = hb_set
        return wrapper

    def copy(self) -> Set:
        c = Set()
        c._hb_set = hb_set_copy(self._hb_set)
        return c

    def __copy__(self) -> Set:
        return self.copy()

    def clear(self):
        hb_set_clear(self._hb_set)

    def __bool__(self) -> bool:
        return not hb_set_is_empty(self._hb_set)

    def invert(self):
        hb_set_invert(self._hb_set)

    def is_inverted(self) -> bool:
        return hb_set_is_inverted(self._hb_set)

    def __contains__(self, c) -> bool:
        if type(c) != int:
            return False
        if c < 0 or c >= self.INVALID_VALUE:
            return False
        return hb_set_has(self._hb_set, c)

    def add(self, c: int):
        hb_set_add(self._hb_set, c)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def add_range(self, first: int, last: int):
        hb_set_add_range(self._hb_set, first, last)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def remove(self, c: int):
        if not c in self:
            raise KeyError, c
        hb_set_del(self._hb_set, c)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def discard(self, c: int):
        hb_set_del(self._hb_set, c)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def del_range(self, first: int, last: int):
        hb_set_del_range(self._hb_set, first, last)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def _is_equal(self, other: Set) -> bool:
        return hb_set_is_equal(self._hb_set, other._hb_set)

    def __eq__(self, other):
        if type(other) != Set:
            return NotImplemented
        return self._is_equal(other)

    def issubset(self, larger_set: Set) -> bool:
        return hb_set_is_subset(self._hb_set, larger_set._hb_set)

    def issuperset(self, smaller_set: Set) -> bool:
        return hb_set_is_subset(smaller_set._hb_set, self._hb_set)

    def _set(self, other: Set):
        hb_set_set(self._hb_set, other._hb_set)

    def set(self, other):
        if type(other) == Set:
            self._set(other)
        else:
            for c in other:
                hb_set_add(self._hb_set, c)

        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def _update(self, other: Set):
        hb_set_union(self._hb_set, other._hb_set)

    def update(self, other):
        if type(other) == Set:
            self._update(other)
        else:
            for c in other:
                hb_set_add(self._hb_set, c)

        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def __ior__(self, other):
        self.update(other)
        return self

    def intersection_update(self, other: Set):
        hb_set_intersect(self._hb_set, other._hb_set)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def __iand__(self, other: Set):
        self.intersection_update(other)
        return self

    def difference_update(self, other: Set):
        hb_set_subtract(self._hb_set, other._hb_set)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def __isub__(self, other: Set):
        self.difference_update(other)
        return self

    def symmetric_difference_update(self, other: Set):
        hb_set_symmetric_difference(self._hb_set, other._hb_set)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def __ixor__(self, other: Set):
        self.symmetric_difference_update(other)
        return self

    def __len__(self) -> int:
        return hb_set_get_population(self._hb_set)

    @property
    def min(self) -> int:
        return hb_set_get_min(self._hb_set)

    @property
    def max(self) -> int:
        return hb_set_get_max(self._hb_set)

    def __iter__(self):
        return SetIter(self)

    def __repr__(self):
        if self.is_inverted():
            return "Set({...})"
        s = ', '.join(repr(v) for v in self)
        return ("Set({%s})" % s)

cdef class SetIter:
    cdef Set s
    cdef hb_set_t *_hb_set
    cdef hb_codepoint_t _c

    def __cinit__(self, s: Set):
        self.s = s
        self._hb_set = s._hb_set
        self._c = s.INVALID_VALUE

    def __iter__(self):
        return self

    def __next__(self) -> int:
        ret = hb_set_next(self._hb_set, &self._c)
        if not ret:
            raise StopIteration
        return self._c


cdef class Map:
    cdef hb_map_t* _hb_map

    INVALID_VALUE = HB_MAP_VALUE_INVALID

    def __cinit__(self, init = dict()):
        self._hb_map = hb_map_create()
        if not hb_map_allocation_successful(self._hb_map):
            raise MemoryError()

        self.update(init)

    def __dealloc__(self):
        hb_map_destroy(self._hb_map)

    @staticmethod
    cdef Map from_ptr(hb_map_t* hb_map):
        """Create Map from a pointer taking ownership of a it."""

        cdef Map wrapper = Map.__new__(Map)
        wrapper._hb_map = hb_map
        return wrapper

    def copy(self) -> Map:
        c = Map()
        c._hb_map = hb_map_copy(self._hb_map)
        return c

    def __copy__(self) -> Map:
        return self.copy()

    def _update(self, other : Map):
        hb_map_update(self._hb_map, other._hb_map)

    def update(self, other):
        if type(other) == Map:
            self._update(other)
        else:
            for k,v in other.items():
                hb_map_set(self._hb_map, k, v)

        if not hb_map_allocation_successful(self._hb_map):
            raise MemoryError()

    def clear(self):
        hb_map_clear(self._hb_map)

    def __bool__(self) -> bool:
        return not hb_map_is_empty(self._hb_map)

    def __len__(self) -> int:
        return hb_map_get_population(self._hb_map)

    def _is_equal(self, other: Map) -> bool:
        return hb_map_is_equal(self._hb_map, other._hb_map)

    def __eq__(self, other):
        if type(other) != Map:
            return NotImplemented
        return self._is_equal(other)

    def __setitem__(self, k: int, v: int):
        hb_map_set(self._hb_map, k, v)
        if not hb_map_allocation_successful(self._hb_map):
            raise MemoryError()

    def get(self, k: int):
        if k < 0 or k >= self.INVALID_VALUE:
            return None
        v = hb_map_get(self._hb_map, k)
        if v == self.INVALID_VALUE:
            v = None
        return v

    def __getitem__(self, k: int) -> int:
        v = self.get(k)
        if v is None:
            raise KeyError, v
        return v

    def __contains__(self, k) -> bool:
        if type(k) != int:
            return False
        if k < 0 or k >= self.INVALID_VALUE:
            return False
        return hb_map_has(self._hb_map, k)

    def __delitem__(self, c: int):
        if not c in self:
            raise KeyError, c
        hb_map_del(self._hb_map, c)

    def items(self):
        return MapIter(self)

    def keys(self):
        return (k for k,v in self.items())

    def values(self):
        return (v for k,v in self.items())

    def __iter__(self):
        return self.keys()

    def __repr__(self):
        s = ', '.join("%s: %s" % (repr(k), repr(v)) for k,v in sorted(self.items()))
        return ("Map({%s})" % s)

cdef class MapIter:
    cdef Map m
    cdef hb_map_t *_hb_map
    cdef int _i

    def __cinit__(self, m: Map):
        self.m = m
        self._hb_map = m._hb_map
        self._i = -1

    def __iter__(self):
        return self

    def __next__(self) -> Tuple[int, int]:
        cdef hb_codepoint_t k
        cdef hb_codepoint_t v
        ret = hb_map_next(self._hb_map, &self._i, &k, &v)
        if not ret:
            raise StopIteration
        return (k, v)
