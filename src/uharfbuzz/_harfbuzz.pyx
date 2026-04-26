#cython: language_level=3
cimport cython
import os
import warnings
from enum import IntEnum, IntFlag
from .charfbuzz cimport *
from libc.stdlib cimport free, malloc, calloc
from libc.string cimport const_char
from libc.math cimport isnan, NAN
from cpython.pycapsule cimport PyCapsule_GetPointer, PyCapsule_IsValid
from cpython.unicode cimport PyUnicode_GetLength, PyUnicode_AsUCS4Copy
from cpython.mem cimport PyMem_Free
from typing import Callable, Dict, List, Sequence, Tuple, Union, NamedTuple
from pathlib import Path
from functools import wraps

# Declare Limited API types and functions (Python 3.3+)
cdef extern from "Python.h":
    ctypedef uint32_t Py_UCS4


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

include "_set.pxi"
include "_map.pxi"
include "_blob.pxi"
include "_buffer.pxi"
include "_face.pxi"
include "_draw.pxi"
include "_paint.pxi"
include "_font.pxi"
include "_serialize.pxi"
include "_subset.pxi"


def shape(font: Font, buffer: Buffer,
        features: Dict[str,Union[int,bool,Sequence[Tuple[int,int,Union[int,bool]]]]] | None = None,
        shapers: List[str] | None = None):
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


def ot_font_set_funcs(font: Font):
    hb_ot_font_set_funcs(font._hb_font)
