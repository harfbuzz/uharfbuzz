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

    def pin_all_axes_to_default(self, face: Face) -> bool:
        return hb_subset_input_pin_all_axes_to_default(self._hb_input, face._hb_face)

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

    def set_axis_range(self,
                       face: Face,
                       tag: str,
                       min_value: float | None = None,
                       max_value: float | None = None,
                       def_value: float | None = None) -> bool:
        cdef hb_tag_t hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        min_value = NAN if min_value is None else min_value
        max_value = NAN if max_value is None else max_value
        def_value = NAN if def_value is None else def_value
        return hb_subset_input_set_axis_range(
            self._hb_input, face._hb_face, hb_tag, min_value, max_value, def_value
        )

    def get_axis_range(self, tag: str) -> Tuple[float | None, float | None | float | None] | None:
        cdef hb_tag_t hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        cdef float axis_min_value, axis_max_value, axis_def_value
        if hb_subset_input_get_axis_range(self._hb_input, hb_tag,
            &axis_min_value, &axis_max_value, &axis_def_value):
            min_value = None if isnan(axis_min_value) else axis_min_value
            max_value = None if isnan(axis_max_value) else axis_max_value
            def_value = None if isnan(axis_def_value) else axis_def_value
            return min_value, max_value, def_value
        return None

    @property
    def unicode_set(self) -> Set[int]:
        return Set.from_ptr(hb_set_reference (hb_subset_input_unicode_set(self._hb_input)))

    @property
    def glyph_set(self) -> Set[int]:
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
    def name_id_set(self) -> Set[int]:
        return self.sets(SubsetInputSets.NAME_ID)

    @property
    def name_lang_id_set(self) -> Set[int]:
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
    def flags(self, flags: SubsetFlags):
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
