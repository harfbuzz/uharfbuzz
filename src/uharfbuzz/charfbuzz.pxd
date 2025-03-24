from libc.stdint cimport uint8_t, uint16_t, uint32_t


cdef extern from "hb.h":

    # hb-common.h
    ctypedef void (*hb_destroy_func_t) (void* user_data)
    ctypedef int hb_bool_t
    ctypedef unsigned long hb_codepoint_t
    ctypedef long hb_position_t
    ctypedef unsigned long hb_mask_t
    ctypedef unsigned long hb_tag_t
    ctypedef uint32_t hb_color_t

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
    ctypedef struct hb_glyph_extents_t:
        hb_position_t x_bearing
        hb_position_t y_bearing
        hb_position_t width
        hb_position_t height

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
    const char* hb_version_string()

    uint8_t hb_color_get_alpha(hb_color_t color)
    uint8_t hb_color_get_red(hb_color_t color)
    uint8_t hb_color_get_green(hb_color_t color)
    uint8_t hb_color_get_blue(hb_color_t color)

    hb_color_t HB_COLOR(uint8_t b, uint8_t g, uint8_t r, uint8_t a)

    ctypedef struct hb_user_data_key_t:
        pass

    ctypedef union hb_var_int_t:
        unsigned long u32
        long i32
        unsigned int u16[2]
        int i16[2]
        unsigned short u8[4]
        short i8[4]

    ctypedef union hb_var_num_t:
        float f
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

    hb_blob_t* hb_blob_create_from_file(
        const char *file_name)

    hb_blob_t* hb_blob_create_from_file_or_fail(
        const char *file_name)

    hb_blob_t* hb_blob_reference(hb_blob_t* blob)
    void hb_blob_destroy(hb_blob_t* blob)

    const char* hb_blob_get_data(
        hb_blob_t *blob, unsigned int *length)

    unsigned int hb_blob_get_length(
        hb_blob_t *blob)

    hb_blob_t* hb_blob_get_empty()

    # hb-buffer.h
    ctypedef struct hb_buffer_t:
        pass

    cdef hb_codepoint_t HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT

    ctypedef enum hb_glyph_flags_t:
        HB_GLYPH_FLAG_UNSAFE_TO_BREAK
        HB_GLYPH_FLAG_UNSAFE_TO_CONCAT
        HB_GLYPH_FLAG_SAFE_TO_INSERT_TATWEEL
        HB_GLYPH_FLAG_DEFINED

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

    ctypedef enum hb_buffer_content_type_t:
        HB_BUFFER_CONTENT_TYPE_INVALID
        HB_BUFFER_CONTENT_TYPE_UNICODE
        HB_BUFFER_CONTENT_TYPE_GLYPHS

    ctypedef enum hb_buffer_cluster_level_t:
        HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
        HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
        HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
        HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES
        HB_BUFFER_CLUSTER_LEVEL_DEFAULT

    ctypedef enum hb_buffer_flags_t:
        HB_BUFFER_FLAG_DEFAULT
        HB_BUFFER_FLAG_BOT
        HB_BUFFER_FLAG_EOT
        HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES
        HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES
        HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE
        HB_BUFFER_FLAG_VERIFY
        HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT
        HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL

        HB_BUFFER_FLAG_DEFINED

    hb_buffer_t* hb_buffer_create()
    hb_bool_t hb_buffer_allocation_successful(hb_buffer_t* buffer)
    void hb_buffer_reset(hb_buffer_t *buffer)
    void hb_buffer_clear_contents(hb_buffer_t *buffer)
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
    unsigned int hb_buffer_get_length(const hb_buffer_t *buffer)
    hb_glyph_info_t* hb_buffer_get_glyph_infos(
        hb_buffer_t* buffer, unsigned int* length)
    hb_glyph_position_t* hb_buffer_get_glyph_positions(
        hb_buffer_t* buffer, unsigned int* length)
    hb_script_t hb_buffer_get_script(hb_buffer_t* buffer)
    void hb_buffer_set_script(hb_buffer_t* buffer, hb_script_t script)
    hb_language_t hb_buffer_get_language(hb_buffer_t* buffer)
    void hb_buffer_set_language(hb_buffer_t* buffer, hb_language_t language)
    void hb_buffer_set_cluster_level(hb_buffer_t *buffer,
        hb_buffer_cluster_level_t cluster_level)
    hb_buffer_cluster_level_t hb_buffer_get_cluster_level(hb_buffer_t *buffer)
    void hb_buffer_destroy(hb_buffer_t* buffer)
    ctypedef hb_bool_t (*hb_buffer_message_func_t) (
        hb_buffer_t *buffer,
        hb_font_t *font,
        const char *message,
        void *user_data)
    void hb_buffer_set_message_func(
        hb_buffer_t *buffer,
        hb_buffer_message_func_t func,
        void *user_data,
        void* destroy)
    void hb_buffer_set_flags(hb_buffer_t *buffer, hb_buffer_flags_t  flags)
    hb_buffer_flags_t hb_buffer_get_flags(const hb_buffer_t *buffer)
    void hb_buffer_set_content_type(hb_buffer_t *buffer, hb_buffer_content_type_t  content_type)
    hb_buffer_content_type_t hb_buffer_get_content_type(const hb_buffer_t *buffer)
    void hb_buffer_set_replacement_codepoint(hb_buffer_t *buffer, hb_codepoint_t  replacement)
    hb_codepoint_t hb_buffer_get_replacement_codepoint(const hb_buffer_t *buffer)
    void hb_buffer_set_invisible_glyph(hb_buffer_t *buffer, hb_codepoint_t  invisible)
    hb_codepoint_t hb_buffer_get_invisible_glyph(const hb_buffer_t *buffer)
    void hb_buffer_set_not_found_glyph(hb_buffer_t *buffer, hb_codepoint_t  not_found)
    hb_codepoint_t hb_buffer_get_not_found_glyph(const hb_buffer_t *buffer)


    # hb-face.h
    ctypedef struct hb_face_t:
        pass
    ctypedef hb_blob_t* (*hb_reference_table_func_t) (
        hb_face_t* face, hb_tag_t tag, void* user_data)

    hb_face_t* hb_face_create(hb_blob_t* blob, unsigned int index)
    hb_face_t* hb_face_create_for_tables(
        hb_reference_table_func_t reference_table_func,
        void* user_data, hb_destroy_func_t destroy)
    unsigned int hb_face_count(hb_blob_t* blob)
    unsigned int hb_face_get_index(const hb_face_t* face)
    void hb_face_set_index(hb_face_t* face, unsigned int index)
    unsigned int hb_face_get_upem(hb_face_t* face)
    void hb_face_set_upem(hb_face_t* face, unsigned int upem)
    unsigned int hb_face_get_glyph_count(hb_face_t* face)
    void hb_face_set_glyph_count(hb_face_t* face, unsigned int glyph_count)
    void* hb_face_get_user_data(hb_face_t* face, hb_user_data_key_t* key)
    hb_bool_t hb_face_set_user_data(
        hb_face_t* face,
        hb_user_data_key_t* key,
        void* data, hb_destroy_func_t destroy,
        hb_bool_t replace)
    void hb_face_destroy(hb_face_t* face)
    hb_blob_t* hb_face_reference_blob(hb_face_t *face)
    hb_blob_t* hb_face_reference_table(hb_face_t *face,hb_tag_t tag)
    hb_face_t* hb_face_reference(hb_face_t *face)
    hb_face_t* hb_face_get_empty()
    unsigned int hb_face_get_table_tags(
        const hb_face_t *face,
        unsigned int  start_offset,
        unsigned int *table_count,
        hb_tag_t     *table_tags)
    void hb_face_collect_unicodes(hb_face_t *face, hb_set_t *out)
    void hb_face_collect_variation_selectors(hb_face_t *face, hb_set_t *out)
    void hb_face_collect_variation_unicodes(hb_face_t *face, hb_codepoint_t variation_selector, hb_set_t *out)


    # hb-font.h
    ctypedef struct hb_font_funcs_t:
        pass
    ctypedef struct hb_font_t:
        pass
    ctypedef hb_bool_t (*hb_font_get_nominal_glyph_func_t) (
        hb_font_t* font, void* font_data,
        hb_codepoint_t unicode,
        hb_codepoint_t* glyph,
        void* user_data)
    ctypedef hb_bool_t (*hb_font_get_variation_glyph_func_t) (
        hb_font_t *font, void *font_data,
        hb_codepoint_t unicode,
        hb_codepoint_t variation_selector,
        hb_codepoint_t *glyph,
        void *user_data)
    ctypedef hb_position_t (*hb_font_get_glyph_advance_func_t) (
        hb_font_t* font, void* font_data,
        hb_codepoint_t glyph,
        void* user_data)
    ctypedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_h_advance_func_t
    ctypedef hb_font_get_glyph_advance_func_t hb_font_get_glyph_v_advance_func_t
    ctypedef hb_bool_t (*hb_font_get_glyph_origin_func_t) (
        hb_font_t* font, void* font_data,
        hb_codepoint_t glyph,
        hb_position_t* x, hb_position_t* y,
        void* user_data)
    ctypedef hb_font_get_glyph_origin_func_t hb_font_get_glyph_v_origin_func_t
    ctypedef hb_bool_t (*hb_font_get_glyph_name_func_t) (
        hb_font_t *font, void *font_data,
        hb_codepoint_t glyph,
        char *name, unsigned int size,
        void *user_data)
    ctypedef hb_bool_t (*hb_font_get_font_extents_func_t) (
        hb_font_t *font, void *font_data,
        hb_font_extents_t *extents,
        void *user_data)
    ctypedef hb_font_get_font_extents_func_t hb_font_get_font_h_extents_func_t
    ctypedef hb_font_get_font_extents_func_t hb_font_get_font_v_extents_func_t
    ctypedef struct hb_variation_t:
        hb_tag_t tag
        float value
    ctypedef struct hb_font_extents_t:
        hb_position_t ascender
        hb_position_t descender
        hb_position_t line_gap
        hb_position_t reserved9
        hb_position_t reserved8
        hb_position_t reserved7
        hb_position_t reserved6
        hb_position_t reserved5
        hb_position_t reserved4
        hb_position_t reserved3
        hb_position_t reserved2
        hb_position_t reserved1

    hb_font_t* hb_font_create(hb_face_t* face)
    hb_font_t* hb_font_create_sub_font(hb_font_t* parent)
    hb_font_t* hb_font_get_empty()
    hb_font_t* hb_font_reference(hb_font_t *font)
    void hb_font_destroy(hb_font_t* font)

    hb_face_t *hb_font_get_face(hb_font_t *font)
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
    void hb_font_funcs_set_glyph_name_func(
        hb_font_funcs_t* ffuncs,
        hb_font_get_glyph_name_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_nominal_glyph_func(
        hb_font_funcs_t* ffuncs,
        hb_font_get_nominal_glyph_func_t func,
        void* user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_variation_glyph_func(
        hb_font_funcs_t *ffuncs,
        hb_font_get_variation_glyph_func_t func,
        void *user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_font_h_extents_func(
        hb_font_funcs_t *ffuncs,
        hb_font_get_font_h_extents_func_t func,
        void *user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_font_v_extents_func(
        hb_font_funcs_t *ffuncs,
        hb_font_get_font_v_extents_func_t func,
        void *user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_destroy(hb_font_funcs_t* ffuncs)

    void hb_font_set_funcs(
        hb_font_t* font,
        hb_font_funcs_t* klass,
        void* font_data, hb_destroy_func_t destroy)
    void hb_font_get_scale(hb_font_t* font, int* x_scale, int* y_scale)
    void hb_font_set_scale(hb_font_t* font, int x_scale, int y_scale)
    void hb_font_get_ppem(hb_font_t* font, unsigned int* x_ppem, unsigned int* y_ppem)
    void hb_font_set_ppem(hb_font_t* font, unsigned int x_ppem, unsigned int y_ppem)
    float hb_font_get_ptem(hb_font_t* font)
    void hb_font_set_ptem(hb_font_t* font, float ptem)
    void hb_font_get_synthetic_bold(hb_font_t *font,
                            float *x_embolden,
                            float *y_embolden,
                            hb_bool_t *in_place)
    void hb_font_set_synthetic_bold(hb_font_t *font,
                            float x_embolden,
                            float y_embolden,
                            hb_bool_t in_place)
    float hb_font_get_synthetic_slant(hb_font_t *font)
    void hb_font_set_synthetic_slant(hb_font_t *font, float slant)
    void hb_font_set_variations(
        hb_font_t* font,
        const hb_variation_t* variations,
        unsigned int variations_length)
    void hb_font_set_variation(
        hb_font_t *font,
        hb_tag_t tag,
        float value)
    void hb_font_set_var_named_instance(hb_font_t *font, unsigned int instance_index)
    unsigned int hb_font_get_var_named_instance(hb_font_t *font)
    void hb_font_set_var_coords_design(
        hb_font_t *font,
        const float *coords,
        unsigned int coords_length)
    const float * hb_font_get_var_coords_design(
        hb_font_t *font, unsigned int *length)
    hb_bool_t hb_font_get_glyph_name(
        hb_font_t* font,
        hb_codepoint_t glyph,
        char* name,
        unsigned int size)
    hb_bool_t hb_font_get_glyph_from_name(
        hb_font_t *font,
        const char *name,
        int len,
        hb_codepoint_t *glyph)
    hb_bool_t hb_font_get_glyph_extents(
        hb_font_t* font,
        hb_codepoint_t glyph,
        hb_glyph_extents_t *extents)
    void hb_font_get_extents_for_direction(hb_font_t *font,
        hb_direction_t direction, hb_font_extents_t *extents)
    hb_bool_t hb_font_get_h_extents(hb_font_t *font, hb_font_extents_t *extents)
    hb_bool_t hb_font_get_v_extents(hb_font_t *font, hb_font_extents_t *extents)
    hb_position_t hb_font_get_glyph_h_advance(
        hb_font_t *font,
        hb_codepoint_t glyph)
    hb_position_t hb_font_get_glyph_v_advance(
        hb_font_t *font,
        hb_codepoint_t glyph)
    hb_bool_t hb_font_get_glyph_h_origin(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_position_t *x,
        hb_position_t *y)
    hb_bool_t hb_font_get_glyph_v_origin(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_position_t *x,
        hb_position_t *y)
    hb_bool_t hb_font_get_nominal_glyph(
        hb_font_t *font,
        hb_codepoint_t unicode,
        hb_codepoint_t *glyph)
    hb_bool_t hb_font_get_variation_glyph(
        hb_font_t *font,
        hb_codepoint_t unicode,
        hb_codepoint_t variation_selector,
        hb_codepoint_t *glyph)
    const int * hb_font_get_var_coords_normalized(
        hb_font_t *font,
        unsigned int *length)
    void hb_font_set_var_coords_normalized(
        hb_font_t *font,
        const int *coords,
        unsigned int coords_length)
    void hb_font_glyph_to_string(
        hb_font_t* font,
        hb_codepoint_t glyph,
        char* name,
        unsigned int size)
    hb_bool_t hb_font_glyph_from_string(
        hb_font_t *font,
        const char *s,
        int len,
        hb_codepoint_t *glyph)

    void hb_font_draw_glyph(
        hb_font_t *font,
        hb_codepoint_t glyph,
        const hb_draw_funcs_t *dfuncs,
        void *draw_data)

    void hb_font_paint_glyph(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_paint_funcs_t *pfuncs,
        void *paint_data,
        unsigned int palette_index,
        hb_color_t foreground)

    # hb-draw.h
    ctypedef struct hb_draw_state_t:
       hb_bool_t path_open
       float path_start_x
       float path_start_y
       float current_x
       float current_y
       float slant_xy
       hb_var_num_t reserved1
       hb_var_num_t reserved2
       hb_var_num_t reserved3
       hb_var_num_t reserved4
       hb_var_num_t reserved5
       hb_var_num_t reserved6

    ctypedef struct hb_draw_funcs_t:
        pass

    ctypedef void (*hb_draw_move_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float to_x,
        float to_y,
        void *user_data)

    ctypedef void (*hb_draw_line_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float to_x,
        float to_y,
        void *user_data)

    ctypedef void (*hb_draw_quadratic_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float control_x,
        float control_y,
        float to_x,
        float to_y,
        void *user_data)

    ctypedef void (*hb_draw_cubic_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float control1_x,
        float control1_y,
        float control2_x,
        float control2_y,
        float to_x,
        float to_y,
        void *user_data)

    ctypedef void (*hb_draw_close_path_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        void *user_data)

    void hb_draw_funcs_set_move_to_func(
        hb_draw_funcs_t* dfuncs,
        hb_draw_move_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_line_to_func(
        hb_draw_funcs_t* dfuncs,
        hb_draw_line_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_quadratic_to_func(
        hb_draw_funcs_t* dfuncs,
        hb_draw_quadratic_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_cubic_to_func(
        hb_draw_funcs_t* dfuncs,
        hb_draw_cubic_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_close_path_func(
        hb_draw_funcs_t* dfuncs,
        hb_draw_close_path_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    hb_draw_funcs_t* hb_draw_funcs_create()

    void hb_draw_funcs_destroy(hb_draw_funcs_t* funcs)

    # hb-paint.h
    ctypedef struct hb_paint_funcs_t:
        pass

    ctypedef struct hb_color_stop_t:
        float offset
        hb_bool_t is_foreground
        hb_color_t color

    ctypedef enum hb_paint_extend_t:
        HB_PAINT_EXTEND_PAD
        HB_PAINT_EXTEND_REPEAT
        HB_PAINT_EXTEND_REFLECT

    ctypedef struct hb_color_line_t:
        pass

    ctypedef enum hb_paint_composite_mode_t:
        HB_PAINT_COMPOSITE_MODE_CLEAR
        HB_PAINT_COMPOSITE_MODE_SRC
        HB_PAINT_COMPOSITE_MODE_DEST
        HB_PAINT_COMPOSITE_MODE_SRC_OVER
        HB_PAINT_COMPOSITE_MODE_DEST_OVER
        HB_PAINT_COMPOSITE_MODE_SRC_IN
        HB_PAINT_COMPOSITE_MODE_DEST_IN
        HB_PAINT_COMPOSITE_MODE_SRC_OUT
        HB_PAINT_COMPOSITE_MODE_DEST_OUT
        HB_PAINT_COMPOSITE_MODE_SRC_ATOP
        HB_PAINT_COMPOSITE_MODE_DEST_ATOP
        HB_PAINT_COMPOSITE_MODE_XOR
        HB_PAINT_COMPOSITE_MODE_PLUS
        HB_PAINT_COMPOSITE_MODE_SCREEN
        HB_PAINT_COMPOSITE_MODE_OVERLAY
        HB_PAINT_COMPOSITE_MODE_DARKEN
        HB_PAINT_COMPOSITE_MODE_LIGHTEN
        HB_PAINT_COMPOSITE_MODE_COLOR_DODGE
        HB_PAINT_COMPOSITE_MODE_COLOR_BURN
        HB_PAINT_COMPOSITE_MODE_HARD_LIGHT
        HB_PAINT_COMPOSITE_MODE_SOFT_LIGHT
        HB_PAINT_COMPOSITE_MODE_DIFFERENCE
        HB_PAINT_COMPOSITE_MODE_EXCLUSION
        HB_PAINT_COMPOSITE_MODE_MULTIPLY
        HB_PAINT_COMPOSITE_MODE_HSL_HUE
        HB_PAINT_COMPOSITE_MODE_HSL_SATURATION
        HB_PAINT_COMPOSITE_MODE_HSL_COLOR
        HB_PAINT_COMPOSITE_MODE_HSL_LUMINOSITY

    hb_paint_funcs_t *hb_paint_funcs_create()
    hb_paint_funcs_t *hb_paint_funcs_get_empty()
    hb_paint_funcs_t *hb_paint_funcs_reference(hb_paint_funcs_t *funcs)
    void hb_paint_funcs_destroy(hb_paint_funcs_t *funcs)
    hb_bool_t hb_paint_funcs_set_user_data(
        hb_paint_funcs_t *funcs,
        hb_user_data_key_t *key,
        void *data,
        hb_destroy_func_t destroy,
        hb_bool_t replace)
    void *hb_paint_funcs_get_user_data(
        const hb_paint_funcs_t *funcs,
        hb_user_data_key_t *key)
    void hb_paint_funcs_make_immutable(hb_paint_funcs_t *funcs)
    hb_bool_t hb_paint_funcs_is_immutable(hb_paint_funcs_t *funcs)

    unsigned int hb_color_line_get_color_stops(
        hb_color_line_t *color_line,
        unsigned int start,
        unsigned int *count,
        hb_color_stop_t *color_stops)

    hb_paint_extend_t hb_color_line_get_extend(hb_color_line_t *color_line)

    ctypedef void (*hb_paint_push_transform_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        float xx, float yx,
        float xy, float yy,
        float dx, float dy,
        void *user_data)
    ctypedef void (*hb_paint_pop_transform_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        void *user_data)
    ctypedef hb_bool_t (*hb_paint_color_glyph_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_codepoint_t glyph,
        hb_font_t *font,
        void *user_data)
    ctypedef void (*hb_paint_push_clip_glyph_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_codepoint_t glyph,
        hb_font_t *font,
        void *user_data)
    ctypedef void (*hb_paint_push_clip_rectangle_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        float xmin, float ymin,
        float xmax, float ymax,
        void *user_data)
    ctypedef void (*hb_paint_pop_clip_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        void *user_data)
    ctypedef void (*hb_paint_color_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_bool_t is_foreground,
        hb_color_t color,
        void *user_data)
    ctypedef hb_bool_t (*hb_paint_image_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_blob_t *image,
        unsigned int width,
        unsigned int height,
        hb_tag_t format,
        float slant,
        hb_glyph_extents_t *extents,
        void *user_data)
    ctypedef unsigned int (*hb_color_line_get_color_stops_func_t) (
        hb_color_line_t *color_line,
        void *color_line_data,
        unsigned int start,
        unsigned int *count,
        hb_color_stop_t *color_stops,
        void *user_data)
    ctypedef hb_paint_extend_t (*hb_color_line_get_extend_func_t) (
        hb_color_line_t *color_line,
        void *color_line_data,
        void *user_data)
    ctypedef struct hb_color_line_t:
        void *data
        hb_color_line_get_color_stops_func_t get_color_stops
        void *get_color_stops_user_data
        hb_color_line_get_extend_func_t get_extend
        void *get_extend_user_data
        void *reserved0
        void *reserved1
        void *reserved2
        void *reserved3
        void *reserved5
        void *reserved6
        void *reserved7
        void *reserved8

    ctypedef void (*hb_paint_linear_gradient_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_color_line_t *color_line,
        float x0, float y0,
        float x1, float y1,
        float x2, float y2,
        void *user_data)
    ctypedef void (*hb_paint_radial_gradient_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_color_line_t *color_line,
        float x0, float y0, float r0,
        float x1, float y1, float r1,
        void *user_data)
    ctypedef void (*hb_paint_sweep_gradient_func_t)  (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_color_line_t *color_line,
        float x0, float y0,
        float start_angle,
        float end_angle,
        void *user_data)
    ctypedef void (*hb_paint_push_group_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        void *user_data)
    ctypedef void (*hb_paint_pop_group_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        hb_paint_composite_mode_t mode,
        void *user_data)
    ctypedef hb_bool_t (*hb_paint_custom_palette_color_func_t) (
        hb_paint_funcs_t *funcs,
        void *paint_data,
        unsigned int color_index,
        hb_color_t *color,
        void *user_data)

    void hb_paint_funcs_set_push_transform_func(
        hb_paint_funcs_t               *funcs,
        hb_paint_push_transform_func_t  func,
        void                           *user_data,
        hb_destroy_func_t               destroy)
    void hb_paint_funcs_set_pop_transform_func(
        hb_paint_funcs_t              *funcs,
        hb_paint_pop_transform_func_t  func,
        void                          *user_data,
        hb_destroy_func_t              destroy)
    void hb_paint_funcs_set_color_glyph_func(
        hb_paint_funcs_t                *funcs,
        hb_paint_color_glyph_func_t     func,
        void                            *user_data,
        hb_destroy_func_t                destroy)
    void hb_paint_funcs_set_push_clip_glyph_func(
        hb_paint_funcs_t                *funcs,
        hb_paint_push_clip_glyph_func_t  func,
        void                            *user_data,
        hb_destroy_func_t                destroy)
    void hb_paint_funcs_set_push_clip_rectangle_func(
        hb_paint_funcs_t                    *funcs,
        hb_paint_push_clip_rectangle_func_t  func,
        void                                *user_data,
        hb_destroy_func_t                    destroy)
    void hb_paint_funcs_set_pop_clip_func(
        hb_paint_funcs_t         *funcs,
        hb_paint_pop_clip_func_t  func,
        void                     *user_data,
        hb_destroy_func_t         destroy)
    void hb_paint_funcs_set_color_func(
        hb_paint_funcs_t      *funcs,
        hb_paint_color_func_t  func,
        void                  *user_data,
        hb_destroy_func_t      destroy)
    void hb_paint_funcs_set_image_func(
        hb_paint_funcs_t      *funcs,
        hb_paint_image_func_t  func,
        void                  *user_data,
        hb_destroy_func_t      destroy)
    void hb_paint_funcs_set_linear_gradient_func (
        hb_paint_funcs_t                *funcs,
        hb_paint_linear_gradient_func_t  func,
        void                            *user_data,
        hb_destroy_func_t                destroy)
    void hb_paint_funcs_set_radial_gradient_func(
        hb_paint_funcs_t                *funcs,
        hb_paint_radial_gradient_func_t  func,
        void                            *user_data,
        hb_destroy_func_t                destroy)
    void hb_paint_funcs_set_sweep_gradient_func(
        hb_paint_funcs_t               *funcs,
        hb_paint_sweep_gradient_func_t  func,
        void                           *user_data,
        hb_destroy_func_t               destroy)
    void hb_paint_funcs_set_push_group_func(
        hb_paint_funcs_t           *funcs,
        hb_paint_push_group_func_t  func,
        void                       *user_data,
        hb_destroy_func_t           destroy)
    void hb_paint_funcs_set_pop_group_func(
        hb_paint_funcs_t          *funcs,
        hb_paint_pop_group_func_t  func,
        void                       *user_data,
        hb_destroy_func_t           destroy)
    void hb_paint_funcs_set_custom_palette_color_func(
        hb_paint_funcs_t                     *funcs,
        hb_paint_custom_palette_color_func_t  func,
        void                                 *user_data,
        hb_destroy_func_t                     destroy)

    # hb-shape.h
    void hb_shape(
        hb_font_t* font,
        hb_buffer_t* buffer,
        const hb_feature_t* features, unsigned int num_features)

    hb_bool_t hb_shape_full(
        hb_font_t *font,
        hb_buffer_t *buffer,
        const hb_feature_t *features,
        unsigned int num_features,
        char ** shaper_list)


    # hb-map.h
    ctypedef struct hb_map_t:
        pass
    cdef hb_codepoint_t HB_MAP_VALUE_INVALID
    hb_map_t* hb_map_create()
    hb_map_t* hb_map_get_empty()
    hb_map_t* hb_map_reference(hb_map_t* map)
    void hb_map_destroy(hb_map_t* map)
    hb_bool_t hb_map_set_user_data(hb_map_t* map, hb_user_data_key_t* key, void* data, hb_destroy_func_t destroy, hb_bool_t replace)
    void* hb_map_get_user_data(const hb_map_t* map, hb_user_data_key_t* key)
    hb_bool_t hb_map_allocation_successful(const hb_map_t* map)
    hb_map_t* hb_map_copy(const hb_map_t* map)
    void hb_map_clear(hb_map_t* map)
    hb_bool_t hb_map_is_empty(const hb_map_t* map)
    unsigned int hb_map_get_population(const hb_map_t* map)
    hb_bool_t hb_map_is_equal(const hb_map_t* map, const hb_map_t* other)
    unsigned int hb_map_hash(const hb_map_t* map)
    void hb_map_set(hb_map_t* map, hb_codepoint_t key, hb_codepoint_t value)
    hb_codepoint_t hb_map_get(const hb_map_t* map, hb_codepoint_t key)
    void hb_map_del(hb_map_t* map, hb_codepoint_t key)
    hb_bool_t hb_map_has(const hb_map_t* map, hb_codepoint_t key)
    void hb_map_update(hb_map_t* map, const hb_map_t* other)
    hb_bool_t hb_map_next(const hb_map_t* map, int *idx, hb_codepoint_t *key, hb_codepoint_t *value)

    # hb-set.h
    ctypedef struct hb_set_t:
        pass
    cdef hb_codepoint_t HB_SET_VALUE_INVALID
    hb_set_t* hb_set_create()
    hb_set_t* hb_set_get_empty()
    hb_set_t* hb_set_reference(hb_set_t* set)
    void hb_set_destroy(hb_set_t* set)
    hb_bool_t hb_set_set_user_data(hb_set_t* set, hb_user_data_key_t* key, void* data, hb_destroy_func_t destroy, hb_bool_t replace)
    void* hb_set_get_user_data(const hb_set_t* set, hb_user_data_key_t* key)
    hb_bool_t hb_set_allocation_successful(const hb_set_t* set)
    hb_set_t* hb_set_copy(const hb_set_t* set)
    void hb_set_clear(hb_set_t* set)
    hb_bool_t hb_set_is_empty(const hb_set_t* set)
    void hb_set_invert(hb_set_t* set)
    hb_bool_t hb_set_is_inverted(const hb_set_t* set)
    hb_bool_t hb_set_has(const hb_set_t* set, hb_codepoint_t codepoint)
    void hb_set_add(hb_set_t* set, hb_codepoint_t codepoint)
    void hb_set_add_range(hb_set_t* set, hb_codepoint_t first, hb_codepoint_t last)
    void hb_set_add_sorted_array(hb_set_t* set, const hb_codepoint_t* sorted_codepoints, unsigned int num_codepoints)
    void hb_set_del(hb_set_t* set, hb_codepoint_t codepoint)
    void hb_set_del_range(hb_set_t* set, hb_codepoint_t first, hb_codepoint_t last)
    hb_bool_t hb_set_is_equal(const hb_set_t* set, const hb_set_t* other)
    unsigned int hb_set_hash(const hb_set_t* set)
    hb_bool_t hb_set_is_subset(const hb_set_t* set, const hb_set_t* larger_set)
    void hb_set_set(hb_set_t* set, const hb_set_t* other)
    void hb_set_union(hb_set_t* set, const hb_set_t* other)
    void hb_set_intersect(hb_set_t* set, const hb_set_t* other)
    void hb_set_subtract(hb_set_t* set, const hb_set_t* other)
    void hb_set_symmetric_difference(hb_set_t* set, const hb_set_t* other)
    unsigned int hb_set_get_population(const hb_set_t* set)
    hb_codepoint_t hb_set_get_min(const hb_set_t* set)
    hb_codepoint_t hb_set_get_max(const hb_set_t* set)
    hb_bool_t hb_set_next(const hb_set_t* set, hb_codepoint_t* codepoint)
    hb_bool_t hb_set_previous(const hb_set_t* set, hb_codepoint_t* codepoint)
    hb_bool_t hb_set_next_range(const hb_set_t* set, hb_codepoint_t* first, hb_codepoint_t* last)
    hb_bool_t hb_set_previous_range(const hb_set_t* set, hb_codepoint_t* first, hb_codepoint_t* last)
    unsigned int hb_set_next_many(const hb_set_t* set, hb_codepoint_t codepoint, hb_codepoint_t* out, unsigned int size)

    # hb-style.h
    ctypedef enum hb_style_tag_t:
        HB_STYLE_TAG_ITALIC
        HB_STYLE_TAG_OPTICAL_SIZE
        HB_STYLE_TAG_SLANT_ANGLE
        HB_STYLE_TAG_SLANT_RATIO
        HB_STYLE_TAG_WIDTH
        HB_STYLE_TAG_WEIGHT
    float hb_style_get_value(hb_font_t *font, hb_style_tag_t style_tag)

cdef extern from "hb-ot.h":
    # hb-ot-layout.h
    unsigned int hb_ot_layout_lookup_get_glyph_alternates(
        hb_face_t* face,
        unsigned lookup_index,
        hb_codepoint_t glyph,
        unsigned start_offset,
        unsigned * alternate_count,
        hb_codepoint_t *alternate_glyphs)
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

    hb_bool_t hb_ot_layout_has_glyph_classes(hb_face_t *face)
    hb_bool_t hb_ot_layout_has_positioning(hb_face_t *face)
    hb_bool_t hb_ot_layout_has_substitution(hb_face_t *face)

    ctypedef enum hb_ot_layout_glyph_class_t:
        HB_OT_LAYOUT_GLYPH_CLASS_UNCLASSIFIED
        HB_OT_LAYOUT_GLYPH_CLASS_BASE_GLYPH
        HB_OT_LAYOUT_GLYPH_CLASS_LIGATURE
        HB_OT_LAYOUT_GLYPH_CLASS_MARK
        HB_OT_LAYOUT_GLYPH_CLASS_COMPONENT
    hb_ot_layout_glyph_class_t hb_ot_layout_get_glyph_class(hb_face_t *face, hb_codepoint_t glyph)

    # hb-ot-font.h
    void hb_ot_font_set_funcs(hb_font_t* font)

    # hb-ot-name.h
    ctypedef unsigned int hb_ot_name_id_t
    ctypedef enum hb_ot_name_id_predefined_t:
        HB_OT_NAME_ID_COPYRIGHT
        HB_OT_NAME_ID_FONT_FAMILY
        HB_OT_NAME_ID_FONT_SUBFAMILY
        HB_OT_NAME_ID_UNIQUE_ID
        HB_OT_NAME_ID_FULL_NAME
        HB_OT_NAME_ID_VERSION_STRING
        HB_OT_NAME_ID_POSTSCRIPT_NAME
        HB_OT_NAME_ID_TRADEMARK
        HB_OT_NAME_ID_MANUFACTURER
        HB_OT_NAME_ID_DESIGNER
        HB_OT_NAME_ID_DESCRIPTION
        HB_OT_NAME_ID_VENDOR_URL
        HB_OT_NAME_ID_DESIGNER_URL
        HB_OT_NAME_ID_LICENSE
        HB_OT_NAME_ID_LICENSE_URL
        HB_OT_NAME_ID_TYPOGRAPHIC_FAMILY
        HB_OT_NAME_ID_TYPOGRAPHIC_SUBFAMILY
        HB_OT_NAME_ID_MAC_FULL_NAME
        HB_OT_NAME_ID_SAMPLE_TEXT
        HB_OT_NAME_ID_CID_FINDFONT_NAME
        HB_OT_NAME_ID_WWS_FAMILY
        HB_OT_NAME_ID_WWS_SUBFAMILY
        HB_OT_NAME_ID_LIGHT_BACKGROUND
        HB_OT_NAME_ID_DARK_BACKGROUND
        HB_OT_NAME_ID_VARIATIONS_PS_PREFIX
        HB_OT_NAME_ID_INVALID

    ctypedef struct hb_ot_name_entry_t:
        hb_ot_name_id_t name_id
        hb_language_t language

    const hb_ot_name_entry_t *hb_ot_name_list_names(
        hb_face_t *face,
        unsigned int *num_entries)  # OUT. May be NULL.
    unsigned int hb_ot_name_get_utf16(
        hb_face_t *face,
        hb_ot_name_id_t name_id,
        hb_language_t language,
        unsigned int *text_size,  # IN/OUT. May be NULL.
        uint16_t *text)  # OUT.
    unsigned int hb_ot_name_get_utf32(
        hb_face_t *face,
        hb_ot_name_id_t name_id,
        hb_language_t language,
        unsigned int *text_size,  # IN/OUT. May be NULL.
        uint32_t *text)  # OUT.
    unsigned int hb_ot_name_get_utf8(
        hb_face_t *face,
        hb_ot_name_id_t name_id,
        hb_language_t language,
        unsigned int *text_size,  # IN/OUT. May be NULL.
        char *text)  # OUT.

    # hb-ot-color.h
    hb_bool_t hb_ot_color_has_palettes(hb_face_t *face)
    unsigned int hb_ot_color_palette_get_count(hb_face_t *face)
    hb_ot_name_id_t hb_ot_color_palette_get_name_id(hb_face_t *face, unsigned int palette_index)
    hb_ot_name_id_t hb_ot_color_palette_color_get_name_id(hb_face_t *face, unsigned int color_index)
    ctypedef enum hb_ot_color_palette_flags_t:
        HB_OT_COLOR_PALETTE_FLAG_DEFAULT
        HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_LIGHT_BACKGROUND
        HB_OT_COLOR_PALETTE_FLAG_USABLE_WITH_DARK_BACKGROUND
    hb_ot_color_palette_flags_t hb_ot_color_palette_get_flags(hb_face_t *face, unsigned int palette_index)
    unsigned int hb_ot_color_palette_get_colors(
        hb_face_t *face,
        unsigned int palette_index,
        unsigned int start_offset,
        unsigned int *color_count,  # IN/OUT. May be NULL.
        hb_color_t *colors)  # OUT. May be NULL.

    hb_bool_t hb_ot_color_has_layers(hb_face_t *face)
    ctypedef struct hb_ot_color_layer_t:
        hb_codepoint_t glyph
        unsigned int color_index
    unsigned int hb_ot_color_glyph_get_layers(
        hb_face_t *face,
        hb_codepoint_t glyph,
        unsigned int start_offset,
        unsigned int *layer_count,  # IN/OUT. May be NULL.
        hb_ot_color_layer_t *layers)  # OUT. May be NULL.

    hb_bool_t hb_ot_color_has_paint(hb_face_t *face)
    hb_bool_t hb_ot_color_glyph_has_paint(hb_face_t *face, hb_codepoint_t glyph)

    hb_bool_t hb_ot_color_has_svg(hb_face_t *face)
    hb_blob_t *hb_ot_color_glyph_reference_svg(hb_face_t *face, hb_codepoint_t glyph)

    hb_bool_t hb_ot_color_has_png(hb_face_t *face)
    hb_blob_t *hb_ot_color_glyph_reference_png(hb_font_t *font, hb_codepoint_t glyph)

    # hb-ot-math.h
    ctypedef enum hb_ot_math_constant_t:
        HB_OT_MATH_CONSTANT_SCRIPT_PERCENT_SCALE_DOWN
        HB_OT_MATH_CONSTANT_SCRIPT_SCRIPT_PERCENT_SCALE_DOWN
        HB_OT_MATH_CONSTANT_DELIMITED_SUB_FORMULA_MIN_HEIGHT
        HB_OT_MATH_CONSTANT_DISPLAY_OPERATOR_MIN_HEIGHT
        HB_OT_MATH_CONSTANT_MATH_LEADING
        HB_OT_MATH_CONSTANT_AXIS_HEIGHT
        HB_OT_MATH_CONSTANT_ACCENT_BASE_HEIGHT
        HB_OT_MATH_CONSTANT_FLATTENED_ACCENT_BASE_HEIGHT
        HB_OT_MATH_CONSTANT_SUBSCRIPT_SHIFT_DOWN
        HB_OT_MATH_CONSTANT_SUBSCRIPT_TOP_MAX
        HB_OT_MATH_CONSTANT_SUBSCRIPT_BASELINE_DROP_MIN
        HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP
        HB_OT_MATH_CONSTANT_SUPERSCRIPT_SHIFT_UP_CRAMPED
        HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MIN
        HB_OT_MATH_CONSTANT_SUPERSCRIPT_BASELINE_DROP_MAX
        HB_OT_MATH_CONSTANT_SUB_SUPERSCRIPT_GAP_MIN
        HB_OT_MATH_CONSTANT_SUPERSCRIPT_BOTTOM_MAX_WITH_SUBSCRIPT
        HB_OT_MATH_CONSTANT_SPACE_AFTER_SCRIPT
        HB_OT_MATH_CONSTANT_UPPER_LIMIT_GAP_MIN
        HB_OT_MATH_CONSTANT_UPPER_LIMIT_BASELINE_RISE_MIN
        HB_OT_MATH_CONSTANT_LOWER_LIMIT_GAP_MIN
        HB_OT_MATH_CONSTANT_LOWER_LIMIT_BASELINE_DROP_MIN
        HB_OT_MATH_CONSTANT_STACK_TOP_SHIFT_UP
        HB_OT_MATH_CONSTANT_STACK_TOP_DISPLAY_STYLE_SHIFT_UP
        HB_OT_MATH_CONSTANT_STACK_BOTTOM_SHIFT_DOWN
        HB_OT_MATH_CONSTANT_STACK_BOTTOM_DISPLAY_STYLE_SHIFT_DOWN
        HB_OT_MATH_CONSTANT_STACK_GAP_MIN
        HB_OT_MATH_CONSTANT_STACK_DISPLAY_STYLE_GAP_MIN
        HB_OT_MATH_CONSTANT_STRETCH_STACK_TOP_SHIFT_UP
        HB_OT_MATH_CONSTANT_STRETCH_STACK_BOTTOM_SHIFT_DOWN
        HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_ABOVE_MIN
        HB_OT_MATH_CONSTANT_STRETCH_STACK_GAP_BELOW_MIN
        HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_SHIFT_UP
        HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_DISPLAY_STYLE_SHIFT_UP
        HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_SHIFT_DOWN
        HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_DISPLAY_STYLE_SHIFT_DOWN
        HB_OT_MATH_CONSTANT_FRACTION_NUMERATOR_GAP_MIN
        HB_OT_MATH_CONSTANT_FRACTION_NUM_DISPLAY_STYLE_GAP_MIN
        HB_OT_MATH_CONSTANT_FRACTION_RULE_THICKNESS
        HB_OT_MATH_CONSTANT_FRACTION_DENOMINATOR_GAP_MIN
        HB_OT_MATH_CONSTANT_FRACTION_DENOM_DISPLAY_STYLE_GAP_MIN
        HB_OT_MATH_CONSTANT_SKEWED_FRACTION_HORIZONTAL_GAP
        HB_OT_MATH_CONSTANT_SKEWED_FRACTION_VERTICAL_GAP
        HB_OT_MATH_CONSTANT_OVERBAR_VERTICAL_GAP
        HB_OT_MATH_CONSTANT_OVERBAR_RULE_THICKNESS
        HB_OT_MATH_CONSTANT_OVERBAR_EXTRA_ASCENDER
        HB_OT_MATH_CONSTANT_UNDERBAR_VERTICAL_GAP
        HB_OT_MATH_CONSTANT_UNDERBAR_RULE_THICKNESS
        HB_OT_MATH_CONSTANT_UNDERBAR_EXTRA_DESCENDER
        HB_OT_MATH_CONSTANT_RADICAL_VERTICAL_GAP
        HB_OT_MATH_CONSTANT_RADICAL_DISPLAY_STYLE_VERTICAL_GAP
        HB_OT_MATH_CONSTANT_RADICAL_RULE_THICKNESS
        HB_OT_MATH_CONSTANT_RADICAL_EXTRA_ASCENDER
        HB_OT_MATH_CONSTANT_RADICAL_KERN_BEFORE_DEGREE
        HB_OT_MATH_CONSTANT_RADICAL_KERN_AFTER_DEGREE
        HB_OT_MATH_CONSTANT_RADICAL_DEGREE_BOTTOM_RAISE_PERCENT

    ctypedef enum hb_ot_math_kern_t:
        HB_OT_MATH_KERN_TOP_RIGHT
        HB_OT_MATH_KERN_TOP_LEFT
        HB_OT_MATH_KERN_BOTTOM_RIGHT
        HB_OT_MATH_KERN_BOTTOM_LEFT

    ctypedef enum hb_ot_math_glyph_part_flags_t:
        HB_OT_MATH_GLYPH_PART_FLAG_EXTENDER


    ctypedef struct hb_ot_math_kern_entry_t:
        hb_position_t max_correction_height
        hb_position_t kern_value

    ctypedef struct hb_ot_math_glyph_variant_t:
        hb_codepoint_t glyph
        hb_position_t advance

    ctypedef struct hb_ot_math_glyph_part_t:
        hb_codepoint_t glyph
        hb_position_t start_connector_length
        hb_position_t end_connector_length
        hb_position_t full_advance
        hb_ot_math_glyph_part_flags_t flags

    hb_bool_t hb_ot_math_has_data(hb_face_t *face)

    hb_position_t hb_ot_math_get_constant(
        hb_font_t *font,
        hb_ot_math_constant_t constant)

    hb_position_t hb_ot_math_get_glyph_italics_correction(
        hb_font_t *font,
        hb_codepoint_t glyph)

    hb_position_t hb_ot_math_get_glyph_top_accent_attachment(
        hb_font_t *font,
        hb_codepoint_t glyph)

    hb_bool_t hb_ot_math_is_glyph_extended_shape(
        hb_face_t *face,
        hb_codepoint_t glyph)

    hb_position_t hb_ot_math_get_glyph_kerning(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_ot_math_kern_t kern,
        hb_position_t correction_height)

    unsigned int hb_ot_math_get_glyph_kernings(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_ot_math_kern_t kern,
        unsigned int start_offset,
        unsigned int *entries_count, # in/out
        hb_ot_math_kern_entry_t *kern_entries) # out

    unsigned int hb_ot_math_get_glyph_variants(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_direction_t direction,
        unsigned int start_offset,
        unsigned int *variants_count, # in/out
        hb_ot_math_glyph_variant_t *variants) # out

    hb_position_t hb_ot_math_get_min_connector_overlap(
        hb_font_t *font,
        hb_direction_t direction)

    unsigned int hb_ot_math_get_glyph_assembly(
        hb_font_t *font,
        hb_codepoint_t glyph,
        hb_direction_t direction,
        unsigned int start_offset,
        unsigned int *parts_count, # in/out
        hb_ot_math_glyph_part_t *parts, # out
        hb_position_t *italics_correction) # out

    # hb-ot-metrics.h
    ctypedef enum hb_ot_metrics_tag_t:
        HB_OT_METRICS_TAG_HORIZONTAL_ASCENDER
        HB_OT_METRICS_TAG_HORIZONTAL_DESCENDER
        HB_OT_METRICS_TAG_HORIZONTAL_LINE_GAP
        HB_OT_METRICS_TAG_HORIZONTAL_CLIPPING_ASCENT
        HB_OT_METRICS_TAG_HORIZONTAL_CLIPPING_DESCENT
        HB_OT_METRICS_TAG_VERTICAL_ASCENDER
        HB_OT_METRICS_TAG_VERTICAL_DESCENDER
        HB_OT_METRICS_TAG_VERTICAL_LINE_GAP
        HB_OT_METRICS_TAG_HORIZONTAL_CARET_RISE
        HB_OT_METRICS_TAG_HORIZONTAL_CARET_RUN
        HB_OT_METRICS_TAG_HORIZONTAL_CARET_OFFSET
        HB_OT_METRICS_TAG_VERTICAL_CARET_RISE
        HB_OT_METRICS_TAG_VERTICAL_CARET_RUN
        HB_OT_METRICS_TAG_VERTICAL_CARET_OFFSET
        HB_OT_METRICS_TAG_X_HEIGHT
        HB_OT_METRICS_TAG_CAP_HEIGHT
        HB_OT_METRICS_TAG_SUBSCRIPT_EM_X_SIZE
        HB_OT_METRICS_TAG_SUBSCRIPT_EM_Y_SIZE
        HB_OT_METRICS_TAG_SUBSCRIPT_EM_X_OFFSET
        HB_OT_METRICS_TAG_SUBSCRIPT_EM_Y_OFFSET
        HB_OT_METRICS_TAG_SUPERSCRIPT_EM_X_SIZE
        HB_OT_METRICS_TAG_SUPERSCRIPT_EM_Y_SIZE
        HB_OT_METRICS_TAG_SUPERSCRIPT_EM_X_OFFSET
        HB_OT_METRICS_TAG_SUPERSCRIPT_EM_Y_OFFSET
        HB_OT_METRICS_TAG_STRIKEOUT_SIZE
        HB_OT_METRICS_TAG_STRIKEOUT_OFFSET
        HB_OT_METRICS_TAG_UNDERLINE_SIZE
        HB_OT_METRICS_TAG_UNDERLINE_OFFSET

    hb_bool_t hb_ot_metrics_get_position(
        hb_font_t *font,
        hb_ot_metrics_tag_t metrics_tag,
        hb_position_t *position)

    void hb_ot_metrics_get_position_with_fallback(
        hb_font_t *font,
        hb_ot_metrics_tag_t metrics_tag,
        hb_position_t *position)

    float hb_ot_metrics_get_variation(
        hb_font_t *font,
        hb_ot_metrics_tag_t metrics_tag)

    hb_position_t hb_ot_metrics_get_x_variation(
        hb_font_t *font,
        hb_ot_metrics_tag_t metrics_tag)

    hb_position_t hb_ot_metrics_get_y_variation(
        hb_font_t *font,
        hb_ot_metrics_tag_t metrics_tag)

    # hb-ot-var.h
    ctypedef enum hb_ot_var_axis_flags_t:
        HB_OT_VAR_AXIS_FLAG_HIDDEN
        _HB_OT_VAR_AXIS_FLAG_MAX_VALUE

    ctypedef struct hb_ot_var_axis_info_t:
        unsigned int axis_index
        hb_tag_t tag
        hb_ot_name_id_t name_id
        hb_ot_var_axis_flags_t flags
        float min_value
        float default_value
        float max_value
        unsigned int reserved

    hb_bool_t hb_ot_var_has_data(hb_face_t *face)
    unsigned int hb_ot_var_get_axis_count(hb_face_t *face)
    unsigned int hb_ot_var_get_axis_infos(
        hb_face_t *face,
		unsigned int start_offset,
		unsigned int *axes_count, # IN/OUT
	    hb_ot_var_axis_info_t *axes_array) # OUT
    hb_bool_t hb_ot_var_find_axis_info(
        hb_face_t *face,
        hb_tag_t tag,
        hb_ot_var_axis_info_t *axis_info)

    unsigned int hb_ot_var_get_named_instance_count(hb_face_t *face)
    hb_ot_name_id_t hb_ot_var_named_instance_get_subfamily_name_id(
        hb_face_t *face,
        unsigned int instance_index)
    hb_ot_name_id_t hb_ot_var_named_instance_get_postscript_name_id(
        hb_face_t *face,
        unsigned int instance_index)
    unsigned int hb_ot_var_named_instance_get_design_coords(
        hb_face_t *face,
		unsigned int instance_index,
		unsigned int *coords_length, # IN/OUT
		float *coords) # OUT

    void hb_ot_var_normalize_variations(
        hb_face_t *face,
        const hb_variation_t *variations, # IN
        unsigned int variations_length,
        int *coords, # OUT
        unsigned int coords_length)
    void hb_ot_var_normalize_coords(
        hb_face_t *face,
        unsigned int coords_length,
        const float *design_coords, # IN
        int *normalized_coords) # OUT

cdef extern from "hb-subset-serialize.h":
    ctypedef struct hb_subset_serialize_link_t:
        unsigned int width
        unsigned int position
        unsigned int objidx
    ctypedef struct hb_subset_serialize_object_t:
        char *head
        char *tail
        unsigned int num_real_links
        hb_subset_serialize_link_t *real_links
        unsigned int num_virtual_links
        hb_subset_serialize_link_t *virtual_links

    hb_blob_t* hb_subset_serialize_or_fail(
        hb_tag_t table_tag,
        hb_subset_serialize_object_t* hb_objects,
        unsigned int num_hb_objs)

cdef extern from "hb-subset.h":
    ctypedef struct hb_subset_input_t:
        pass
    ctypedef struct hb_subset_plan_t:
        pass
    ctypedef enum hb_subset_flags_t:
        HB_SUBSET_FLAGS_DEFAULT
        HB_SUBSET_FLAGS_NO_HINTING
        HB_SUBSET_FLAGS_RETAIN_GIDS
        HB_SUBSET_FLAGS_DESUBROUTINIZE
        HB_SUBSET_FLAGS_NAME_LEGACY
        HB_SUBSET_FLAGS_SET_OVERLAPS_FLAG
        HB_SUBSET_FLAGS_PASSTHROUGH_UNRECOGNIZED
        HB_SUBSET_FLAGS_NOTDEF_OUTLINE
        HB_SUBSET_FLAGS_GLYPH_NAMES
        HB_SUBSET_FLAGS_NO_PRUNE_UNICODE_RANGES
        HB_SUBSET_FLAGS_NO_LAYOUT_CLOSURE
    ctypedef enum hb_subset_sets_t:
        HB_SUBSET_SETS_GLYPH_INDEX
        HB_SUBSET_SETS_UNICODE
        HB_SUBSET_SETS_NO_SUBSET_TABLE_TAG
        HB_SUBSET_SETS_DROP_TABLE_TAG
        HB_SUBSET_SETS_NAME_ID
        HB_SUBSET_SETS_NAME_LANG_ID
        HB_SUBSET_SETS_LAYOUT_FEATURE_TAG
        HB_SUBSET_SETS_LAYOUT_SCRIPT_TAG
    hb_subset_input_t* hb_subset_input_create_or_fail()
    hb_subset_input_t* hb_subset_input_reference(hb_subset_input_t* input)
    void hb_subset_input_destroy(hb_subset_input_t* input)
    hb_bool_t hb_subset_input_set_user_data(hb_subset_input_t* input, hb_user_data_key_t* key, void* data, hb_destroy_func_t destroy, hb_bool_t replace)
    void* hb_subset_input_get_user_data(const hb_subset_input_t* input, hb_user_data_key_t* key)
    void hb_subset_input_keep_everything(hb_subset_input_t* input)
    hb_set_t* hb_subset_input_unicode_set(hb_subset_input_t* input)
    hb_set_t* hb_subset_input_glyph_set(hb_subset_input_t* input)
    hb_set_t* hb_subset_input_set(hb_subset_input_t* input, hb_subset_sets_t set_type)
    hb_subset_flags_t hb_subset_input_get_flags(hb_subset_input_t* input)
    void hb_subset_input_set_flags(hb_subset_input_t* input, unsigned value)
    hb_bool_t hb_subset_input_pin_axis_to_default(hb_subset_input_t* input, hb_face_t* face, hb_tag_t axis_tag)
    hb_bool_t hb_subset_input_pin_axis_location(hb_subset_input_t* input, hb_face_t* face, hb_tag_t axis_tag, float axis_value)
    hb_face_t* hb_subset_preprocess(hb_face_t* source)
    hb_face_t* hb_subset_or_fail(hb_face_t* source, const hb_subset_input_t* input)
    hb_face_t* hb_subset_plan_execute_or_fail(hb_subset_plan_t* plan)
    hb_subset_plan_t* hb_subset_plan_create_or_fail(hb_face_t* face, const hb_subset_input_t* input)
    void hb_subset_plan_destroy(hb_subset_plan_t* plan)
    const hb_map_t* hb_subset_plan_old_to_new_glyph_mapping(const hb_subset_plan_t* plan)
    const hb_map_t* hb_subset_plan_new_to_old_glyph_mapping(const hb_subset_plan_t* plan)
    const hb_map_t* hb_subset_plan_unicode_to_old_glyph_mapping(const hb_subset_plan_t* plan)
    hb_subset_plan_t* hb_subset_plan_reference(hb_subset_plan_t* plan)
    hb_bool_t hb_subset_plan_set_user_data(hb_subset_plan_t* plan, hb_user_data_key_t* key, void* data, hb_destroy_func_t destroy, hb_bool_t replace)
    void* hb_subset_plan_get_user_data(const hb_subset_plan_t* plan, hb_user_data_key_t* key)
