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
    const char* hb_version_string();

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

    void hb_blob_destroy(hb_blob_t* blob)

    const char* hb_blob_get_data(
        hb_blob_t *blob, unsigned int *length)

    unsigned int hb_blob_get_length(
        hb_blob_t *blob)

    hb_blob_t* hb_blob_get_empty()

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

    ctypedef enum hb_buffer_cluster_level_t:
        HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
        HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
        HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
        HB_BUFFER_CLUSTER_LEVEL_DEFAULT

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
    void hb_buffer_set_cluster_level(hb_buffer_t *buffer,
        hb_buffer_cluster_level_t cluster_level)
    hb_buffer_cluster_level_t hb_buffer_get_cluster_level(hb_buffer_t *buffer)
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

    hb_face_t* hb_face_get_empty()

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
    ctypedef hb_bool_t (*hb_font_get_font_extents_func_t) (
        hb_font_t *font, void *font_data,
        hb_font_extents_t *extents,
        void *user_data)
    ctypedef hb_font_get_font_extents_func_t hb_font_get_font_h_extents_func_t;
    ctypedef hb_font_get_font_extents_func_t hb_font_get_font_v_extents_func_t;
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
    void hb_font_funcs_set_font_h_extents_func(
        hb_font_funcs_t *ffuncs,
        hb_font_get_font_h_extents_func_t func,
        void *user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_set_font_v_extents_func(
        hb_font_funcs_t *ffuncs,
        hb_font_get_font_v_extents_func_t func,
        void *user_data, hb_destroy_func_t destroy)
    void hb_font_funcs_destroy(hb_font_funcs_t* ffuncs)

    hb_font_t* hb_font_create(hb_face_t* face)
    hb_font_t* hb_font_create_sub_font(hb_font_t* parent)
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
    void hb_font_set_variations(
        hb_font_t* font,
        const hb_variation_t* variations,
        unsigned int variations_length)
    hb_bool_t hb_font_get_glyph_name(
        hb_font_t* font,
        hb_codepoint_t glyph,
        char* name,
        unsigned int size)
    hb_bool_t hb_font_get_glyph_extents(
        hb_font_t* font,
        hb_codepoint_t glyph,
        hb_glyph_extents_t *extents)
    void hb_font_get_extents_for_direction(hb_font_t *font,
        hb_direction_t direction, hb_font_extents_t *extents)
    hb_bool_t hb_font_get_h_extents(hb_font_t *font, hb_font_extents_t *extents)
    hb_bool_t hb_font_get_v_extents(hb_font_t *font, hb_font_extents_t *extents)
    hb_bool_t hb_font_get_nominal_glyph(
        hb_font_t *font,
        hb_codepoint_t unicode,
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
    void hb_font_destroy(hb_font_t* font)

    ctypedef struct hb_draw_state_t:
       hb_bool_t path_open
       float path_start_x
       float path_start_y
       float current_x
       float current_y
       hb_var_num_t reserved1
       hb_var_num_t reserved2
       hb_var_num_t reserved3
       hb_var_num_t reserved4
       hb_var_num_t reserved5
       hb_var_num_t reserved6
       hb_var_num_t reserved7

    ctypedef struct hb_draw_funcs_t:
        pass

    ctypedef void (*hb_draw_move_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float to_x,
        float to_y,
        void *user_data);

    ctypedef void (*hb_draw_line_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float to_x,
        float to_y,
        void *user_data);

    ctypedef void (*hb_draw_quadratic_to_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        float control_x,
        float control_y,
        float to_x,
        float to_y,
        void *user_data);

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
        void *user_data);

    ctypedef void (*hb_draw_close_path_func_t) (
        hb_draw_funcs_t *dfuncs,
        void *draw_data,
        hb_draw_state_t *st,
        void *user_data);

    void hb_draw_funcs_set_move_to_func (
        hb_draw_funcs_t* dfuncs,
        hb_draw_move_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_line_to_func (
        hb_draw_funcs_t* dfuncs,
        hb_draw_line_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_quadratic_to_func (
        hb_draw_funcs_t* dfuncs,
        hb_draw_quadratic_to_func_t func,
        void *user_data,
        hb_destroy_func_t destroy)

    void hb_draw_funcs_set_cubic_to_func (
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

    void hb_font_get_glyph_shape(
        hb_font_t *font,
        hb_codepoint_t glyph,
        const hb_draw_funcs_t *dfuncs,
        void *draw_data)

    # hb-shape.h
    void hb_shape(
        hb_font_t* font,
        hb_buffer_t* buffer,
        const hb_feature_t* features, unsigned int num_features)

    hb_bool_t hb_shape_full (
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

    # hb-set.h
    ctypedef struct hb_set_t:
        pass
    cdef hb_codepoint_t HB_SET_VALUE_INVALID
    hb_set_t* hb_set_create();
    hb_set_t* hb_set_get_empty();
    hb_set_t* hb_set_reference(hb_set_t* set);
    void hb_set_destroy(hb_set_t* set);
    hb_bool_t hb_set_set_user_data(hb_set_t* set, hb_user_data_key_t* key, void* data, hb_destroy_func_t destroy, hb_bool_t replace);
    void* hb_set_get_user_data(const hb_set_t* set, hb_user_data_key_t* key);
    hb_bool_t hb_set_allocation_successful(const hb_set_t* set);
    hb_set_t* hb_set_copy(const hb_set_t* set);
    void hb_set_clear(hb_set_t* set);
    hb_bool_t hb_set_is_empty(const hb_set_t* set);
    void hb_set_invert(hb_set_t* set);
    hb_bool_t hb_set_has(const hb_set_t* set, hb_codepoint_t codepoint);
    void hb_set_add(hb_set_t* set, hb_codepoint_t codepoint);
    void hb_set_add_range(hb_set_t* set, hb_codepoint_t first, hb_codepoint_t last);
    void hb_set_add_sorted_array(hb_set_t* set, const hb_codepoint_t* sorted_codepoints, unsigned int num_codepoints);
    void hb_set_del(hb_set_t* set, hb_codepoint_t codepoint);
    void hb_set_del_range(hb_set_t* set, hb_codepoint_t first, hb_codepoint_t last);
    hb_bool_t hb_set_is_equal(const hb_set_t* set, const hb_set_t* other);
    unsigned int hb_set_hash(const hb_set_t* set);
    hb_bool_t hb_set_is_subset(const hb_set_t* set, const hb_set_t* larger_set);
    void hb_set_set(hb_set_t* set, const hb_set_t* other);
    void hb_set_union(hb_set_t* set, const hb_set_t* other);
    void hb_set_intersect(hb_set_t* set, const hb_set_t* other);
    void hb_set_subtract(hb_set_t* set, const hb_set_t* other);
    void hb_set_symmetric_difference(hb_set_t* set, const hb_set_t* other);
    unsigned int hb_set_get_population(const hb_set_t* set);
    hb_codepoint_t hb_set_get_min(const hb_set_t* set);
    hb_codepoint_t hb_set_get_max(const hb_set_t* set);
    hb_bool_t hb_set_next(const hb_set_t* set, hb_codepoint_t* codepoint);
    hb_bool_t hb_set_previous(const hb_set_t* set, hb_codepoint_t* codepoint);
    hb_bool_t hb_set_next_range(const hb_set_t* set, hb_codepoint_t* first, hb_codepoint_t* last);
    hb_bool_t hb_set_previous_range(const hb_set_t* set, hb_codepoint_t* first, hb_codepoint_t* last);
    unsigned int hb_set_next_many(const hb_set_t* set, hb_codepoint_t codepoint, hb_codepoint_t* out, unsigned int size);


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

cdef extern from "hb-subset-repacker.h":
    ctypedef struct hb_link_t:
        unsigned int width
        unsigned int position
        unsigned int objidx
    ctypedef struct hb_object_t:
        char *head
        char *tail
        unsigned int num_real_links
        hb_link_t *real_links
        unsigned int num_virtual_links
        hb_link_t *virtual_links

    hb_blob_t* hb_subset_repack_or_fail (
        hb_tag_t table_tag,
        hb_object_t* hb_objects,
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
        # Not supported yet: HB_SUBSET_FLAGS_PATCH_MODE
        # Not supported yet: HB_SUBSET_FLAGS_OMIT_GLYF
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
