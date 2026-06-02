def subset_preprocess(face: Face) -> Face:
    """Preprocesses the face and attaches data that will be needed by the
    subsetter. Future subsetting operations can then use the precomputed
    data to speed up the subsetting operation.

    See `subset-preprocessing
    <https://github.com/harfbuzz/harfbuzz/blob/main/docs/subset-preprocessing.md>`_
    for more information.

    Note: the preprocessed face may contain sub-blobs that reference the
    memory backing the source :class:`Face`. Therefore in the case that
    this memory is not owned by the source face you will need to ensure
    that memory lives as long as the returned :class:`Face`.

    :returns: a new :class:`Face`.

    Wraps `hb_subset_preprocess()
    <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-preprocess>`_.
    """
    new_face = hb_subset_preprocess(face._hb_face)
    return Face.from_ptr(new_face)

def subset(face: Face, input: SubsetInput) -> Face:
    """Subsets a font according to provided input.

    :raises RuntimeError: If the subset operation fails or the face has no
        glyphs.

    Wraps `hb_subset_or_fail()
    <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-or-fail>`_.
    """
    new_face = hb_subset_or_fail(face._hb_face, input._hb_input)
    if new_face == NULL:
        raise RuntimeError("Subsetting failed")
    return Face.from_ptr(new_face)

class SubsetInputSets(IntEnum):
    """List of sets that can be configured on the subset input.

    .. attribute:: GLYPH_INDEX

       The set of glyph indexes to retain in the subset.

    .. attribute:: UNICODE

       The set of unicode codepoints to retain in the subset.

    .. attribute:: NO_SUBSET_TABLE_TAG

       The set of table tags which specifies tables that should not be
       subsetted.

    .. attribute:: DROP_TABLE_TAG

       The set of table tags which specifies tables which will be dropped
       in the subset.

    .. attribute:: NAME_ID

       The set of name ids that will be retained.

    .. attribute:: NAME_LANG_ID

       The set of name lang ids that will be retained.

    .. attribute:: LAYOUT_FEATURE_TAG

       The set of layout feature tags that will be retained in the subset.

    .. attribute:: LAYOUT_SCRIPT_TAG

       The set of layout script tags that will be retained in the subset.
       Defaults to all tags.

    Wraps `hb_subset_sets_t
    <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-sets-t>`_.
    """
    GLYPH_INDEX = HB_SUBSET_SETS_GLYPH_INDEX
    UNICODE = HB_SUBSET_SETS_UNICODE
    NO_SUBSET_TABLE_TAG = HB_SUBSET_SETS_NO_SUBSET_TABLE_TAG
    DROP_TABLE_TAG = HB_SUBSET_SETS_DROP_TABLE_TAG
    NAME_ID = HB_SUBSET_SETS_NAME_ID
    NAME_LANG_ID = HB_SUBSET_SETS_NAME_LANG_ID
    LAYOUT_FEATURE_TAG = HB_SUBSET_SETS_LAYOUT_FEATURE_TAG
    LAYOUT_SCRIPT_TAG = HB_SUBSET_SETS_LAYOUT_SCRIPT_TAG


class SubsetFlags(IntFlag):
    """List of boolean properties that can be configured on the subset input.

    .. attribute:: DEFAULT

       All flags at their default value of false.

    .. attribute:: NO_HINTING

       If set hinting instructions will be dropped in the produced subset.
       Otherwise hinting instructions will be retained.

    .. attribute:: RETAIN_GIDS

       If set glyph indices will not be modified in the produced subset.
       If glyphs are dropped their indices will be retained as an empty
       glyph.

    .. attribute:: DESUBROUTINIZE

       If set and subsetting a CFF font the subsetter will attempt to
       remove subroutines from the CFF glyphs.

    .. attribute:: NAME_LEGACY

       If set non-unicode name records will be retained in the subset.

    .. attribute:: SET_OVERLAPS_FLAG

       If set the subsetter will set the ``OVERLAP_SIMPLE`` flag on each
       simple glyph.

    .. attribute:: PASSTHROUGH_UNRECOGNIZED

       If set the subsetter will not drop unrecognized tables and instead
       pass them through untouched.

    .. attribute:: NOTDEF_OUTLINE

       If set the notdef glyph outline will be retained in the final
       subset.

    .. attribute:: GLYPH_NAMES

       If set the PS glyph names will be retained in the final subset.

    .. attribute:: NO_PRUNE_UNICODE_RANGES

       If set then the unicode ranges in ``OS/2`` will not be recalculated.

    .. attribute:: NO_LAYOUT_CLOSURE

       If set do not perform glyph closure on layout substitution rules
       (``GSUB``).

    Wraps `hb_subset_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-flags-t>`_.
    """
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
    """Things that change based on the input. Characters to keep, etc.

    Wraps `hb_subset_input_t
    <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-t>`_.
    """

    cdef hb_subset_input_t* _hb_input

    def __cinit__(self):
        self._hb_input = hb_subset_input_create_or_fail()
        if self._hb_input is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._hb_input is not NULL:
            hb_subset_input_destroy(self._hb_input)

    def subset(self, source: Face) -> Face:
        """Subsets ``source`` according to this input. Equivalent to calling
        :func:`subset` with ``source`` and this input.
        """
        return subset(source, self)

    def keep_everything(self):
        """Configure input object to keep everything in the font face. That
        is, all Unicodes, glyphs, names, layout items, glyph names, etc.

        The input can be tailored afterwards by the caller.

        Wraps `hb_subset_input_keep_everything()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-keep-everything>`_.
        """
        hb_subset_input_keep_everything(self._hb_input)

    def pin_all_axes_to_default(self, face: Face) -> bool:
        """Pin all axes to default locations in this subset input object.

        All axes in a font must be pinned. Additionally, ``CFF2`` table, if
        present, will be de-subroutinized.

        :returns: ``True`` if success, ``False`` otherwise.

        Wraps `hb_subset_input_pin_all_axes_to_default()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-pin-all-axes-to-default>`_.
        """
        return hb_subset_input_pin_all_axes_to_default(self._hb_input, face._hb_face)

    def pin_axis_to_default(self, face: Face, tag: str) -> bool:
        """Pin an axis to its default location in this subset input object.

        All axes in a font must be pinned. Additionally, ``CFF2`` table, if
        present, will be de-subroutinized.

        :param tag: Tag of the axis to be pinned.

        :returns: ``True`` if success, ``False`` otherwise.

        Wraps `hb_subset_input_pin_axis_to_default()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-pin-axis-to-default>`_.
        """
        hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        return hb_subset_input_pin_axis_to_default(
            self._hb_input, face._hb_face, hb_tag
        )

    def pin_axis_location(self, face: Face, tag: str, value: float) -> bool:
        """Pin an axis to a fixed location in this subset input object.

        All axes in a font must be pinned. Additionally, ``CFF2`` table, if
        present, will be de-subroutinized.

        :param tag: Tag of the axis to be pinned.
        :param value: Location on the axis to be pinned at.

        :returns: ``True`` if success, ``False`` otherwise.

        Wraps `hb_subset_input_pin_axis_location()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-pin-axis-location>`_.
        """
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
        """Restricting the range of variation on an axis in this subset input
        object. New min/default/max values will be clamped if they're not
        within the ``fvar`` axis range.

        If the ``fvar`` axis default value is not within the new range, the
        new default value will be changed to the new min or max value,
        whichever is closer to the ``fvar`` axis default.

        Note: input min value can not be bigger than input max value. If
        the input default value is not within the new min/max range, it'll
        be clamped.

        :param tag: Tag of the axis.
        :param min_value: Minimum value of the axis variation range to set,
            if ``None`` the existing min will be used.
        :param max_value: Maximum value of the axis variation range to set,
            if ``None`` the existing max will be used.
        :param def_value: Default value of the axis variation range to set,
            if ``None`` the existing default will be used.

        :returns: ``True`` if success, ``False`` otherwise.

        Wraps `hb_subset_input_set_axis_range()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-set-axis-range>`_.
        """
        cdef hb_tag_t hb_tag = hb_tag_from_string(tag.encode("ascii"), -1)
        min_value = NAN if min_value is None else min_value
        max_value = NAN if max_value is None else max_value
        def_value = NAN if def_value is None else def_value
        return hb_subset_input_set_axis_range(
            self._hb_input, face._hb_face, hb_tag, min_value, max_value, def_value
        )

    def get_axis_range(self, tag: str) -> Tuple[float | None, float | None, float | None] | None:
        """Gets the axis range assigned by previous calls to
        :meth:`set_axis_range`.

        :param tag: Tag of the axis.

        :returns: ``(min, max, default)`` triple if a range has been set
            for this axis tag, ``None`` otherwise. Each component is
            ``None`` only if it was previously set to ``None`` (NaN) via
            :meth:`set_axis_range`.

        Wraps `hb_subset_input_get_axis_range()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-get-axis-range>`_.
        """
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
        """The set of Unicode code points to retain. The caller should modify
        the set as needed.

        :type: Set

        Wraps `hb_subset_input_unicode_set()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-unicode-set>`_.
        """
        return Set.from_ptr(hb_set_reference (hb_subset_input_unicode_set(self._hb_input)))

    @property
    def glyph_set(self) -> Set[int]:
        """The set of glyph IDs to retain. The caller should modify the set
        as needed.

        :type: Set

        Wraps `hb_subset_input_glyph_set()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-glyph-set>`_.
        """
        return Set.from_ptr(hb_set_reference (hb_subset_input_glyph_set(self._hb_input)))

    def sets(self, set_type : SubsetInputSets) -> Set:
        """Gets the set of the specified type.

        Wraps `hb_subset_input_set()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-set>`_.
        """
        return Set.from_ptr(hb_set_reference (hb_subset_input_set(self._hb_input, set_type)))

    @property
    def no_subset_table_tag_set(self) -> Set:
        """Shortcut for ``sets(SubsetInputSets.NO_SUBSET_TABLE_TAG)``.

        :type: Set
        """
        return self.sets(SubsetInputSets.NO_SUBSET_TABLE_TAG)

    @property
    def drop_table_tag_set(self) -> Set:
        """Shortcut for ``sets(SubsetInputSets.DROP_TABLE_TAG)``.

        :type: Set
        """
        return self.sets(SubsetInputSets.DROP_TABLE_TAG)

    @property
    def name_id_set(self) -> Set[int]:
        """Shortcut for ``sets(SubsetInputSets.NAME_ID)``.

        :type: Set
        """
        return self.sets(SubsetInputSets.NAME_ID)

    @property
    def name_lang_id_set(self) -> Set[int]:
        """Shortcut for ``sets(SubsetInputSets.NAME_LANG_ID)``.

        :type: Set
        """
        return self.sets(SubsetInputSets.NAME_LANG_ID)

    @property
    def layout_feature_tag_set(self) -> Set:
        """Shortcut for ``sets(SubsetInputSets.LAYOUT_FEATURE_TAG)``.

        :type: Set
        """
        return self.sets(SubsetInputSets.LAYOUT_FEATURE_TAG)

    @property
    def layout_script_tag_set(self) -> Set:
        """Shortcut for ``sets(SubsetInputSets.LAYOUT_SCRIPT_TAG)``.

        :type: Set
        """
        return self.sets(SubsetInputSets.LAYOUT_SCRIPT_TAG)

    @property
    def flags(self) -> SubsetFlags:
        """All of the subsetting flags in the input object.

        :type: SubsetFlags

        Wraps `hb_subset_input_get_flags()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-get-flags>`_
        and `hb_subset_input_set_flags()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-input-set-flags>`_.
        """
        cdef unsigned subset_flags = hb_subset_input_get_flags(self._hb_input)
        return SubsetFlags(subset_flags)

    @flags.setter
    def flags(self, flags: SubsetFlags):
        hb_subset_input_set_flags(self._hb_input, int(flags))


cdef class SubsetPlan:
    """Contains information about how the subset operation will be
    executed. Such as mappings from the old glyph ids to the new ones in
    the subset.

    Constructing a :class:`SubsetPlan` computes a plan for subsetting the
    supplied ``face`` according to the provided ``input``. The plan
    describes which tables and glyphs should be retained.

    Wraps `hb_subset_plan_t
    <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-plan-t>`_.
    """

    cdef hb_subset_plan_t* _hb_plan

    def __cinit__(self, face: Face, input: SubsetInput):
        self._hb_plan = hb_subset_plan_create_or_fail(face._hb_face, input._hb_input)
        if self._hb_plan is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._hb_plan is not NULL:
            hb_subset_plan_destroy(self._hb_plan)

    def execute(self) -> Face:
        """Executes this subsetting plan.

        :returns: A new :class:`Face` containing the generated font subset.

        :raises RuntimeError: If the subsetting operation fails.

        Wraps `hb_subset_plan_execute_or_fail()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-plan-execute-or-fail>`_.
        """
        new_face = hb_subset_plan_execute_or_fail(self._hb_plan)
        if new_face == NULL:
            raise RuntimeError("Subsetting failed")
        return Face.from_ptr(new_face)

    @property
    def old_to_new_glyph_mapping(self) -> Map:
        """The mapping between glyphs in the original font to glyphs in the
        subset that will be produced by this plan.

        :type: Map

        Wraps `hb_subset_plan_old_to_new_glyph_mapping()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-plan-old-to-new-glyph-mapping>`_.
        """
        return Map.from_ptr(hb_map_reference (<hb_map_t*>hb_subset_plan_old_to_new_glyph_mapping(self._hb_plan)))

    @property
    def new_to_old_glyph_mapping(self) -> Map:
        """The mapping between glyphs in the subset that will be produced by
        this plan and the glyph in the original font.

        :type: Map

        Wraps `hb_subset_plan_new_to_old_glyph_mapping()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-plan-new-to-old-glyph-mapping>`_.
        """
        return Map.from_ptr(hb_map_reference (<hb_map_t*>hb_subset_plan_new_to_old_glyph_mapping(self._hb_plan)))

    @property
    def unicode_to_old_glyph_mapping(self) -> Map:
        """The mapping between codepoints in the original font and the
        associated glyph id in the original font.

        :type: Map

        Wraps `hb_subset_plan_unicode_to_old_glyph_mapping()
        <https://harfbuzz.github.io/harfbuzz-hb-subset.html#hb-subset-plan-unicode-to-old-glyph-mapping>`_.
        """
        return Map.from_ptr(hb_map_reference (<hb_map_t*>hb_subset_plan_unicode_to_old_glyph_mapping(self._hb_plan)))
