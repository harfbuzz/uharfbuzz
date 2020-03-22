from libc.stdint cimport uint8_t, uint16_t, uint32_t


cdef extern from "hb.h":

    # hb-common.h
    ctypedef void (*hb_destroy_func_t) (void* user_data)
    ctypedef int hb_bool_t
    ctypedef unsigned long hb_codepoint_t
    ctypedef long hb_position_t
    ctypedef unsigned long hb_mask_t
    ctypedef unsigned long hb_tag_t

    ctypedef enum hb_direction_t:
        HB_DIRECTION_LTR
        HB_DIRECTION_RTL
        HB_DIRECTION_TTB
        HB_DIRECTION_BTT
    ctypedef enum hb_script_t:
        pass
    ctypedef struct hb_language_t:
        pass
    ctypedef struct hb_feature_t:
        hb_tag_t tag
        unsigned long value
        unsigned int start
        unsigned int end

    hb_direction_t hb_direction_from_string(const char* str, int len)
    const char* hb_direction_to_string(hb_direction_t direction)
    hb_bool_t hb_feature_from_string(
        const char* str, int len,
        hb_feature_t* feature)
    void hb_feature_to_string(
        hb_feature_t* feature,
        char* buf, unsigned int size)
    hb_language_t hb_language_from_string(const char* str, int len)
    const char* hb_language_to_string(hb_language_t language)
    hb_script_t hb_script_from_string(const char* str, int len)
    hb_tag_t hb_tag_from_string(const char* str, int len)
    void hb_tag_to_string(hb_tag_t tag, char* buf)
    hb_language_t hb_ot_tag_to_language(hb_tag_t tag)
    hb_script_t hb_ot_tag_to_script(hb_tag_t tag)

    ctypedef struct hb_user_data_key_t:
        pass

    ctypedef union hb_var_int_t:
        unsigned long u32
        long i32
        unsigned int u16[2]
        int i16[2]
        unsigned short u8[4]
        short i8[4]

    # hb-blob.h
    ctypedef struct hb_blob_t:
        pass
    ctypedef enum hb_memory_mode_t:
        HB_MEMORY_MODE_DUPLICATE
        HB_MEMORY_MODE_READONLY
        HB_MEMORY_MODE_WRITABLE
        HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE

    hb_blob_t* hb_blob_create(
        const char* data, unsigned int length,
        hb_memory_mode_t mode,
        void* user_data, hb_destroy_func_t destroy)

    # hb-buffer.h
    ctypedef struct hb_buffer_t:
        pass

    ctypedef struct hb_glyph_info_t:
        hb_codepoint_t codepoint
        hb_mask_t mask
        unsigned long cluster
    ctypedef struct hb_glyph_position_t:
        hb_position_t x_advance
        hb_position_t y_advance
        hb_position_t x_offset
        hb_position_t y_offset
        hb_var_int_t var

    hb_buffer_t* hb_buffer_create()
    hb_bool_t hb_buffer_allocation_successful(hb_buffer_t* buffer)
    void hb_buffer_add_codepoints(
        hb_buffer_t* buffer,
        const hb_codepoint_t* text, int text_length,
        unsigned int item_offset, int item_length)
    void hb_buffer_add_latin1(
        hb_buffer_t* buffer,
        const uint8_t* text, int text_length,
        unsigned int item_offset, int item_length)
    void hb_buffer_add_utf8(
        hb_buffer_t* buffer,
        const char* text, int text_length,
        unsigned int item_offset, int item_length)
    void hb_buffer_add_utf16(
        hb_buffer_t* buffer,
        const uint16_t* text, int text_length,
        unsigned int item_offset, int item_length)
    void hb_buffer_add_utf32(
        hb_buffer_t* buffer,
        const uint32_t* text, int text_length,
        unsigned int item_offset, int item_length)
    void hb_buffer_guess_segment_properties(hb_buffer_t* buffer)
    hb_direction_t hb_buffer_get_direction(hb_buffer_t* buffer)
    void hb_buffer_set_direction(hb_buffer_t* buffer, hb_direction_t direction)
    hb_glyph_info_t* hb_buffer_get_glyph_infos(
        hb_buffer_t* buffer, unsigned int* length)
    hb_glyph_position_t* hb_buffer_get_glyph_positions(
        hb_buffer_t* buffer, unsigned int* length)
    hb_script_t hb_buffer_get_script(hb_buffer_t* buffer)
    void hb_buffer_set_script(hb_buffer_t* buffer, hb_script_t script)
    hb_language_t hb_buffer_get_language(hb_buffer_t* buffer)
    void hb_buffer_set_language(hb_buffer_t* buffer, hb_language_t language)
    void hb_buffer_destroy(hb_buffer_t* buffer)
    ctypedef hb_bool_t (*hb_buffer_message_func_t) (
        hb_buffer_t *buffer,
        hb_font_t *font,
        const char *message,
        void *user_data)
    void hb_buffer_set_message_func (
        hb_buffer_t *buffer,
        hb_buffer_message_func_t func,
        void *user_data,
        void* destroy)

    # hb-face.h
    ctypedef struct hb_face_t:
        pass
    ctypedef hb_blob_t* (*hb_reference_table_func_t) (
        hb_face_t* face, hb_tag_t tag, void* user_data)

    hb_face_t* hb_face_create(hb_blob_t* blob, unsigned int index)
    hb_face_t* hb_face_create_for_tables(
        hb_reference_table_func_t reference_table_func,
        void* user_data, hb_destroy_func_t destroy)
    unsigned int hb_face_get_upem(hb_face_t* face)
    void hb_face_set_upem(hb_face_t* face, unsigned int upem)
    void* hb_face_get_user_data(hb_face_t* face, hb_user_data_key_t* key)
    hb_bool_t hb_face_set_user_data(
        hb_face_t* face,
        hb_user_data_key_t* key,
        void* data, hb_destroy_func_t destroy,
        hb_bool_t replace)
    void hb_face_destroy(hb_face_t* face)

    # hb-font.h
    ctypedef struct hb_font_funcs_t:
        pass
    ctypedef struct hb_font_t:
        pass
    ctypedef hb_bool_t (*hb_font_get_nominal_glyph_func_t) (
        hb_font_t* font, void* font_data,
        hb_codepoint_t unicode,
        hb_codepoint_t* glyph,
        void* user_data);
    ctypedef hb_position_t (*hb_font_get_glyph_advance_func_t) (
        hb_font_t* font, void* font_data,
        hb_codepoint_t glyph,
        void* user_data)
    ctypedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_h_advance_func_t;
    ctypedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_v_advance_func_t;
    ctypedef hb_bool_t (*hb_font_get_glyph_origin_func_t) (
        hb_font_t* font, void* font_data,
        hb_codepoint_t glyph,
        hb_position_t* x, hb_position_t* y,
        void* user_data)
    ctypedef hb_font_get_glyph_origin_func_t hb_font_get_glyph_v_origin_func_t;
    ctypedef hb_bool_t (*hb_font_get_glyph_name_func_t) (
        hb_font_t *font, void *font_data,
        hb_codepoint_t glyph,
        char *name, unsigned int size,
        void *user_data)
    ctypedef struct hb_variation_t:
        hb_tag_t tag
        float value

    hb_font_funcs_t* hb_font_funcs_create()
    void hb_font_funcs_set_glyph_h_advance_func(
        hb_font_funcs_t* ffuncs,
        hb_font_get_glyph_h_advance_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_glyph_v_advance_func(
        hb_font_funcs_t* ffuncs,
        hb_font_get_glyph_v_advance_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_glyph_v_origin_func(
        hb_font_funcs_t* ffuncs,
        hb_font_get_glyph_v_origin_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_glyph_name_func (
        hb_font_funcs_t* ffuncs,
        hb_font_get_glyph_name_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_nominal_glyph_func(
        hb_font_funcs_t* ffuncs,
        hb_font_get_nominal_glyph_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_destroy(hb_font_funcs_t* ffuncs)

    hb_font_t* hb_font_create(hb_face_t* face)
    void hb_font_set_funcs(
        hb_font_t* font,
        hb_font_funcs_t* klass,
        void* font_data, hb_destroy_func_t destroy)
    void hb_font_get_scale(hb_font_t* font, int* x_scale, int* y_scale)
    void hb_font_set_scale(hb_font_t* font, int x_scale, int y_scale)
    void hb_font_set_variations(
        hb_font_t* font,
        const hb_variation_t* variations,
        unsigned int variations_length)
    void hb_font_destroy(hb_font_t* font)

    # hb-shape.h
    void hb_shape(
        hb_font_t* font,
        hb_buffer_t* buffer,
        const hb_feature_t* features, unsigned int num_features)


cdef extern from "hb-ot.h":

    # hb-ot-layout.h
    unsigned int hb_ot_layout_language_get_feature_tags(
        hb_face_t* face,
        hb_tag_t table_tag,
        unsigned int script_index,
        unsigned int language_index,
        unsigned int start_offset,
        unsigned int* feature_count,  # in/out
        hb_tag_t* feature_tags)  # out
    unsigned int hb_ot_layout_script_get_language_tags(
        hb_face_t* face,
        hb_tag_t table_tag,
        unsigned int script_index,
        unsigned int start_offset,
        unsigned int* language_count,  # in/out
        hb_tag_t* language_tags)  # out
    unsigned int hb_ot_layout_table_get_script_tags(
        hb_face_t* face,
        hb_tag_t table_tag,
        unsigned int start_offset,
        unsigned int* script_count,  # in/out
        hb_tag_t* script_tags)  # out

    ctypedef enum hb_ot_layout_baseline_tag_t:
        HB_OT_LAYOUT_BASELINE_TAG_ROMAN
        HB_OT_LAYOUT_BASELINE_TAG_HANGING
        HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_BOTTOM_OR_LEFT
        HB_OT_LAYOUT_BASELINE_TAG_IDEO_FACE_TOP_OR_RIGHT
        HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_BOTTOM_OR_LEFT
        HB_OT_LAYOUT_BASELINE_TAG_IDEO_EMBOX_TOP_OR_RIGHT
        HB_OT_LAYOUT_BASELINE_TAG_MATH

    hb_bool_t hb_ot_layout_get_baseline(
        hb_font_t* font,
        hb_ot_layout_baseline_tag_t baseline_tag,
        hb_direction_t direction,
        hb_tag_t script_tag,
        hb_tag_t language_tag,
        hb_position_t* coord)  # out

    # hb-ot-font.h
    void hb_ot_font_set_funcs(hb_font_t* font)
