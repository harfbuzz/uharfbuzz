class GlyphFlags(IntFlag):
    """Flags for :class:`GlyphInfo`.

    .. attribute:: UNSAFE_TO_BREAK
       :value: 0x01

       Indicates that if input text is broken at the beginning of the cluster
       this glyph is part of, then both sides need to be re-shaped, as the
       result might be different. On the flip side, it means that when this
       flag is not present, then it is safe to break the glyph-run at the
       beginning of this cluster, and the two sides will represent the exact
       same result one would get if breaking input text at the beginning of
       this cluster and shaping the two sides separately. This can be used
       to optimize paragraph layout, by avoiding re-shaping of each line
       after line-breaking.

    .. attribute:: UNSAFE_TO_CONCAT
       :value: 0x02

       Indicates that if input text is changed on one side of the beginning
       of the cluster this glyph is part of, then the shaping results for
       the other side might change. Note that the absence of this flag
       will NOT by itself mean that it IS safe to concat text. Only two
       pieces of text both of which clear of this flag can be concatenated
       safely. This can be used to optimize paragraph layout, by avoiding
       re-shaping of each line after line-breaking, by limiting the
       reshaping to a small piece around the breaking position only, even
       if the breaking position carries the :attr:`UNSAFE_TO_BREAK` or
       when hyphenation or other text transformation happens at line-break
       position, in the following way:
       1. Iterate back from the line-break position until the first
       cluster start position that is NOT unsafe-to-concat,
       2. shape the segment from there till the end of line,
       3. check whether the resulting glyph-run also is clear of the
       unsafe-to-concat at its start-of-text position; if it is, just
       splice it into place and the line is shaped; If not, move on to a
       position further back that is clear of unsafe-to-concat and retry
       from there, and repeat.
       At the start of next line a similar algorithm can be implemented.
       That is:
       1. Iterate forward from the line-break position until the first
       cluster start position that is NOT unsafe-to-concat,
       2. shape the segment from beginning of the line to that position,
       3. check whether the resulting glyph-run also is clear of the
       unsafe-to-concat at its end-of-text position; if it is, just splice
       it into place and the beginning is shaped; If not, move on to a
       position further forward that is clear of unsafe-to-concat and
       retry up to there, and repeat.
       A slight complication will arise in the implementation of the
       algorithm above, because while our buffer API has a way to return
       flags for position corresponding to start-of-text, there is
       currently no position corresponding to end-of-text. This limitation
       can be alleviated by shaping more text than needed and looking for
       unsafe-to-concat flag within text clusters.
       The :attr:`UNSAFE_TO_BREAK` flag will always imply this flag. To
       use this flag, you must enable the buffer flag
       :attr:`BufferFlags.PRODUCE_UNSAFE_TO_CONCAT` during shaping,
       otherwise the buffer flag will not be reliably produced.

    .. attribute:: SAFE_TO_INSERT_TATWEEL
       :value: 0x04

       In scripts that use elongation (Arabic, Mongolian, Syriac, etc.),
       this flag signifies that it is safe to insert a U+0640 TATWEEL
       character before this cluster for elongation. This flag does not
       determine the script-specific elongation places, but only when it is
       safe to do the elongation without interrupting text shaping.

    Wraps `hb_glyph_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-glyph-flags-t>`_.
    """
    UNSAFE_TO_BREAK = HB_GLYPH_FLAG_UNSAFE_TO_BREAK
    UNSAFE_TO_CONCAT = HB_GLYPH_FLAG_UNSAFE_TO_CONCAT
    SAFE_TO_INSERT_TATWEEL = HB_GLYPH_FLAG_SAFE_TO_INSERT_TATWEEL

cdef class GlyphInfo:
    """The structure that holds information about the glyphs and their
    relation to input text.

    Wraps `hb_glyph_info_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-glyph-info-t>`_.
    """

    cdef hb_glyph_info_t _hb_glyph_info
    # could maybe store Buffer to prevent GC

    cdef set(self, hb_glyph_info_t info):
        self._hb_glyph_info = info

    @property
    def codepoint(self) -> int:
        """Either a Unicode code point (before shaping) or a glyph index
        (after shaping).
        """
        return self._hb_glyph_info.codepoint

    @property
    def cluster(self) -> int:
        """The index of the character in the original text that corresponds
        to this :class:`GlyphInfo`, or whatever the client passes to
        :meth:`Buffer.add_codepoints`. More than one :class:`GlyphInfo` can
        have the same ``cluster`` value, if they resulted from the same
        character (e.g. one to many glyph substitution), and when more than
        one character gets merged in the same glyph (e.g. many to one glyph
        substitution) the :class:`GlyphInfo` will have the smallest cluster
        value of them. By default some characters are merged into the same
        cluster (e.g. combining marks have the same cluster as their bases)
        even if they are separate glyphs, :attr:`Buffer.cluster_level` allows
        selecting more fine-grained cluster handling.
        """
        return self._hb_glyph_info.cluster

    @property
    def flags(self) -> GlyphFlags:
        """Glyph flags encoded within a :class:`GlyphInfo`.

        :type: GlyphFlags

        Wraps `hb_glyph_info_get_glyph_flags()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-glyph-info-get-glyph-flags>`_.
        """
        return GlyphFlags(self._hb_glyph_info.mask & HB_GLYPH_FLAG_DEFINED)


cdef class GlyphPosition:
    """The structure that holds the positions of the glyph in both horizontal
    and vertical directions. All positions in :class:`GlyphPosition` are
    relative to the current point.

    Wraps `hb_glyph_position_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-glyph-position-t>`_.
    """
    cdef hb_glyph_position_t _hb_glyph_position
    # could maybe store Buffer to prevent GC

    cdef set(self, hb_glyph_position_t position):
        self._hb_glyph_position = position

    @property
    def position(self) -> Tuple[int, int, int, int]:
        """A tuple of (:attr:`x_offset`, :attr:`y_offset`, :attr:`x_advance`,
        :attr:`y_advance`).
        """
        return (
            self._hb_glyph_position.x_offset,
            self._hb_glyph_position.y_offset,
            self._hb_glyph_position.x_advance,
            self._hb_glyph_position.y_advance
        )

    @property
    def x_advance(self) -> int:
        """How much the line advances after drawing this glyph when setting
        text in horizontal direction.
        """
        return self._hb_glyph_position.x_advance

    @property
    def y_advance(self) -> int:
        """How much the line advances after drawing this glyph when setting
        text in vertical direction.
        """
        return self._hb_glyph_position.y_advance

    @property
    def x_offset(self) -> int:
        """How much the glyph moves on the X-axis before drawing it, this
        should not affect how much the line advances.
        """
        return self._hb_glyph_position.x_offset

    @property
    def y_offset(self) -> int:
        """How much the glyph moves on the Y-axis before drawing it, this
        should not affect how much the line advances.
        """
        return self._hb_glyph_position.y_offset


class BufferFlags(IntFlag):
    """Flags for :class:`Buffer`.

    .. attribute:: DEFAULT
       :value: 0x00

       The default buffer flag.

    .. attribute:: BOT
       :value: 0x01

       Flag indicating that special handling of the beginning of text
       paragraph can be applied to this buffer. Should usually be set,
       unless you are passing to the buffer only part of the text without
       the full context.

    .. attribute:: EOT
       :value: 0x02

       Flag indicating that special handling of the end of text paragraph
       can be applied to this buffer, similar to :attr:`BOT`.

    .. attribute:: PRESERVE_DEFAULT_IGNORABLES
       :value: 0x04

       Flag indication that character with Default_Ignorable Unicode
       property should use the corresponding glyph from the font, instead of
       hiding them (done by replacing them with the space glyph and zeroing
       the advance width.) This flag takes precedence over
       :attr:`REMOVE_DEFAULT_IGNORABLES`.

    .. attribute:: REMOVE_DEFAULT_IGNORABLES
       :value: 0x08

       Flag indication that character with Default_Ignorable Unicode
       property should be removed from glyph string instead of hiding them
       (done by replacing them with the space glyph and zeroing the advance
       width.) :attr:`PRESERVE_DEFAULT_IGNORABLES` takes precedence over
       this flag.

    .. attribute:: DO_NOT_INSERT_DOTTED_CIRCLE
       :value: 0x10

       Flag indicating that a dotted circle should not be inserted in the
       rendering of incorrect character sequences (such at <0905 093E>).

    .. attribute:: VERIFY
       :value: 0x20

       Flag indicating that the :func:`shape` call and its variants should
       perform various verification processes on the results of the shaping
       operation on the buffer. If the verification fails, then either a
       buffer message is sent, if a message handler is installed on the
       buffer, or a message is written to standard error. In either case,
       the shaping result might be modified to show the failed output.

    .. attribute:: PRODUCE_UNSAFE_TO_CONCAT
       :value: 0x40

       Flag indicating that the :attr:`GlyphFlags.UNSAFE_TO_CONCAT`
       glyph-flag should be produced by the shaper. By default it will not
       be produced since it incurs a cost.

    .. attribute:: PRODUCE_SAFE_TO_INSERT_TATWEEL
       :value: 0x80

       Flag indicating that the :attr:`GlyphFlags.SAFE_TO_INSERT_TATWEEL`
       glyph-flag should be produced by the shaper. By default it will not
       be produced.

    Wraps `hb_buffer_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-flags-t>`_.
    """
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
    """Data type for holding HarfBuzz's clustering behavior options. The
    cluster level dictates one aspect of how HarfBuzz will treat non-base
    characters during shaping.

    :attr:`MONOTONE_GRAPHEMES` is the default, because it maintains backward
    compatibility with older versions of HarfBuzz. New client programs that
    do not need to maintain such backward compatibility are recommended to
    use :attr:`MONOTONE_CHARACTERS` instead of the default.

    .. attribute:: MONOTONE_GRAPHEMES
       :value: 0

       Return cluster values grouped by graphemes into monotone order.
       Non-base characters are merged into the cluster of the base character
       that precedes them. There is also cluster merging every time the
       clusters will otherwise become non-monotone.

    .. attribute:: MONOTONE_CHARACTERS
       :value: 1

       Return cluster values grouped into monotone order. Non-base
       characters are initially assigned their own cluster values, which are
       not merged into preceding base clusters. This allows HarfBuzz to
       perform additional operations like reorder sequences of adjacent
       marks. The output is still monotone, but the cluster values are more
       granular.

    .. attribute:: CHARACTERS
       :value: 2

       Don't group cluster values. Non-base characters are assigned their
       own cluster values, which are not merged into preceding base
       clusters. Moreover, the cluster values are not merged into monotone
       order. This is the most granular cluster level, and it is useful for
       clients that need to know the exact cluster values of each character,
       but is harder to use for clients, since clusters might appear in any
       order.

    .. attribute:: GRAPHEMES
       :value: 3

       Only group clusters, but don't enforce monotone order. Non-base
       characters are merged into the cluster of the base character that
       precedes them. This is similar to the Unicode Grapheme Cluster
       algorithm, but it is not exactly the same. The output is not forced
       to be monotone. This is useful for clients that want to use HarfBuzz
       as a cheap implementation of the Unicode Grapheme Cluster algorithm.

    .. attribute:: DEFAULT
       :value: MONOTONE_GRAPHEMES

       Default cluster level, equal to :attr:`MONOTONE_GRAPHEMES`.

    Wraps `hb_buffer_cluster_level_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-cluster-level-t>`_.
    """
    MONOTONE_GRAPHEMES = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
    MONOTONE_CHARACTERS = HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
    CHARACTERS = HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
    GRAPHEMES = HB_BUFFER_CLUSTER_LEVEL_GRAPHEMES
    DEFAULT = HB_BUFFER_CLUSTER_LEVEL_DEFAULT

class BufferContentType(IntEnum):
    """The type of :class:`Buffer` contents.

    .. attribute:: INVALID
       :value: 0

       Initial value for new buffer.

    .. attribute:: UNICODE
       :value: 1

       The buffer contains input characters (before shaping).

    .. attribute:: GLYPHS
       :value: 2

       The buffer contains output glyphs (after shaping).

    Wraps `hb_buffer_content_type_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-content-type-t>`_.
    """
    INVALID = HB_BUFFER_CONTENT_TYPE_INVALID
    UNICODE = HB_BUFFER_CONTENT_TYPE_UNICODE
    GLYPHS = HB_BUFFER_CONTENT_TYPE_GLYPHS

class BufferSerializeFormat(IntEnum):
    """The buffer serialization and de-serialization format used in
    :meth:`Buffer.serialize`.

    .. attribute:: TEXT

       A human-readable, plain text format.

    .. attribute:: JSON

       A machine-readable JSON format.

    .. attribute:: INVALID

       Invalid format.

    Wraps `hb_buffer_serialize_format_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-serialize-format-t>`_.
    """
    TEXT = HB_BUFFER_SERIALIZE_FORMAT_TEXT
    JSON = HB_BUFFER_SERIALIZE_FORMAT_JSON
    INVALID = HB_BUFFER_SERIALIZE_FORMAT_INVALID

class BufferSerializeFlags(IntFlag):
    """Flags that control what glyph information are serialized in
    :meth:`Buffer.serialize`.

    .. attribute:: DEFAULT
       :value: 0x00

       Serialize glyph names, clusters and positions.

    .. attribute:: NO_CLUSTERS
       :value: 0x01

       Do not serialize glyph cluster.

    .. attribute:: NO_POSITIONS
       :value: 0x02

       Do not serialize glyph position information.

    .. attribute:: NO_GLYPH_NAMES
       :value: 0x04

       Do not serialize glyph name.

    .. attribute:: GLYPH_EXTENTS
       :value: 0x08

       Serialize glyph extents.

    .. attribute:: GLYPH_FLAGS
       :value: 0x10

       Serialize glyph flags.

    .. attribute:: NO_ADVANCES
       :value: 0x20

       Do not serialize glyph advances, glyph offsets will reflect absolute
       glyph positions.

       Note: when this flag is used with a partial range of the buffer
       (i.e. ``start`` is not 0), calculating the absolute positions has a
       cost proportional to ``start``. If the buffer is serialized in many
       small chunks, this can lead to quadratic behavior. It is recommended
       to use a larger ``buf_size`` to minimize this cost.

    Wraps `hb_buffer_serialize_flags_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-serialize-flags-t>`_.
    """
    DEFAULT = HB_BUFFER_SERIALIZE_FLAG_DEFAULT
    NO_CLUSTERS = HB_BUFFER_SERIALIZE_FLAG_NO_CLUSTERS
    NO_POSITIONS = HB_BUFFER_SERIALIZE_FLAG_NO_POSITIONS
    NO_GLYPH_NAMES = HB_BUFFER_SERIALIZE_FLAG_NO_GLYPH_NAMES
    GLYPH_EXTENTS = HB_BUFFER_SERIALIZE_FLAG_GLYPH_EXTENTS
    GLYPH_FLAGS = HB_BUFFER_SERIALIZE_FLAG_GLYPH_FLAGS
    NO_ADVANCES = HB_BUFFER_SERIALIZE_FLAG_NO_ADVANCES
    DEFINED = HB_BUFFER_SERIALIZE_FLAG_DEFINED

cdef class Buffer:
    """Input and output buffers.

    Buffers serve a dual role in HarfBuzz; before shaping, they hold the
    input characters that are passed to :func:`shape`, and after shaping they
    hold the output glyphs.

    The input buffer is a sequence of Unicode codepoints, with associated
    attributes such as direction and script. The output buffer is a sequence
    of glyphs, with associated attributes such as position and cluster.

    .. attribute:: DEFAULT_REPLACEMENT_CODEPOINT
       :value: 0xFFFD

       The default code point for replacing invalid characters in a given
       encoding. Set to U+FFFD REPLACEMENT CHARACTER.

       Wraps `HB_BUFFER_REPLACEMENT_CODEPOINT_DEFAULT
       <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#HB-BUFFER-REPLACEMENT-CODEPOINT-DEFAULT:CAPS>`_.

    Wraps `hb_buffer_t
    <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-t>`_.
    """

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

    @classmethod
    @deprecated("Buffer()", since="0.10.0")
    def create(cls) -> Buffer:
        cdef Buffer inst = cls()
        return inst

    def __len__(self) -> int:
        return hb_buffer_get_length(self._hb_buffer)

    def reset(self):
        """Resets the buffer to its initial status, as if it was just newly
        created.

        Wraps `hb_buffer_reset()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-reset>`_.
        """
        hb_buffer_reset (self._hb_buffer)

    def clear_contents(self):
        """Similar to :meth:`reset`, but does not clear the Unicode functions
        and the replacement code point.

        Wraps `hb_buffer_clear_contents()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-clear-contents>`_.
        """
        hb_buffer_clear_contents(self._hb_buffer)

    @property
    def direction(self) -> str:
        """The text flow direction of the buffer. No shaping can happen
        without setting buffer direction, and it controls the visual
        direction for the output glyphs; for RTL direction the glyphs will be
        reversed. Many layout features depend on the proper setting of the
        direction, for example, reversing RTL text before shaping, then
        shaping with LTR direction is not the same as keeping the text in
        logical order and shaping with RTL direction.

        Wraps `hb_buffer_get_direction()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-direction>`_
        / `hb_buffer_set_direction()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-direction>`_.
        """
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
        """The buffer glyph information array. The value is valid as long as
        the buffer has not been modified.

        :type: list[GlyphInfo]

        Wraps `hb_buffer_get_glyph_infos()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-glyph-infos>`_.
        """
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
        """The buffer glyph position array. The value is valid as long as the
        buffer has not been modified.

        If the buffer did not have positions before, the positions will be
        initialized to zeros, unless this property is accessed from within a
        buffer message callback (see :meth:`set_message_func`), in which case
        ``None`` is returned.

        :type: list[GlyphPosition] | None

        Wraps `hb_buffer_get_glyph_positions()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-glyph-positions>`_.
        """
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
        """The language of the buffer, as a BCP 47 language tag.

        Languages are crucial for selecting which OpenType feature to apply
        to the buffer which can result in applying language-specific
        behaviour. Languages are orthogonal to the scripts, and though they
        are related, they are different concepts and should not be confused
        with each other.

        Wraps `hb_buffer_get_language()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-language>`_
        / `hb_buffer_set_language()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-language>`_.
        """
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
        """The script of the buffer, as an ISO 15924 script tag.

        Script is crucial for choosing the proper shaping behaviour for
        scripts that require it (e.g. Arabic) and the which OpenType features
        defined in the font to be applied.

        Wraps `hb_buffer_get_script()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-script>`_
        / `hb_buffer_set_script()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-script>`_.
        """
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
        """The :class:`BufferFlags` of the buffer.

        :type: BufferFlags

        Wraps `hb_buffer_get_flags()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-flags>`_
        / `hb_buffer_set_flags()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-flags>`_.
        """
        level = hb_buffer_get_flags(self._hb_buffer)
        return BufferFlags(level)

    @flags.setter
    def flags(self, value: BufferFlags):
        level = BufferFlags(value)
        hb_buffer_set_flags(self._hb_buffer, level)

    @property
    def cluster_level(self) -> BufferClusterLevel:
        """The cluster level of the buffer. The :class:`BufferClusterLevel`
        dictates one aspect of how HarfBuzz will treat non-base characters
        during shaping.

        :type: BufferClusterLevel

        Wraps `hb_buffer_get_cluster_level()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-cluster-level>`_
        / `hb_buffer_set_cluster_level()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-cluster-level>`_.
        """
        level = hb_buffer_get_cluster_level(self._hb_buffer)
        return BufferClusterLevel(level)

    @cluster_level.setter
    def cluster_level(self, value: BufferClusterLevel):
        level = BufferClusterLevel(value)
        hb_buffer_set_cluster_level(self._hb_buffer, level)

    @property
    def content_type(self) -> BufferContentType:
        """The type of buffer contents. Buffers are either empty, contain
        characters (before shaping), or contain glyphs (the result of
        shaping).

        :type: BufferContentType

        Wraps `hb_buffer_get_content_type()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-content-type>`_
        / `hb_buffer_set_content_type()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-content-type>`_.
        """
        level = hb_buffer_get_content_type(self._hb_buffer)
        return BufferContentType(level)

    @content_type.setter
    def content_type(self, value: BufferContentType):
        level = BufferContentType(value)
        hb_buffer_set_content_type(self._hb_buffer, level)

    @property
    def replacement_codepoint(self) -> int:
        """The codepoint that replaces invalid entries for a given encoding
        when adding text to the buffer.

        Default is :attr:`DEFAULT_REPLACEMENT_CODEPOINT`.

        Wraps `hb_buffer_get_replacement_codepoint()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-replacement-codepoint>`_
        / `hb_buffer_set_replacement_codepoint()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-replacement-codepoint>`_.
        """
        return hb_buffer_get_replacement_codepoint(self._hb_buffer)

    @replacement_codepoint.setter
    def replacement_codepoint(self, value: int):
        hb_buffer_set_replacement_codepoint(self._hb_buffer, value)

    @property
    def invisible_glyph(self) -> int:
        """The codepoint that replaces invisible characters in the shaping
        result. If set to zero (default), the glyph for the U+0020 SPACE
        character is used. Otherwise, this value is used verbatim.

        Wraps `hb_buffer_get_invisible_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-invisible-glyph>`_
        / `hb_buffer_set_invisible_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-invisible-glyph>`_.
        """
        return hb_buffer_get_invisible_glyph(self._hb_buffer)

    @invisible_glyph.setter
    def invisible_glyph(self, value: int):
        hb_buffer_set_invisible_glyph(self._hb_buffer, value)

    @property
    def not_found_glyph(self) -> int:
        """The codepoint that replaces characters not found in the font
        during shaping.

        The not-found glyph defaults to zero, sometimes known as the
        ``.notdef`` glyph. This API allows for differentiating the two.

        Wraps `hb_buffer_get_not_found_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-get-not-found-glyph>`_
        / `hb_buffer_set_not_found_glyph()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-not-found-glyph>`_.
        """
        return hb_buffer_get_not_found_glyph(self._hb_buffer)

    @not_found_glyph.setter
    def not_found_glyph(self, value: int):
        hb_buffer_set_not_found_glyph(self._hb_buffer, value)

    def set_language_from_ot_tag(self, value: str):
        """Sets the language of the buffer from an OpenType language tag.

        Wraps `hb_ot_tag_to_language()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-tag-to-language>`_
        + `hb_buffer_set_language()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-language>`_.
        """
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        hb_buffer_set_language(
            self._hb_buffer, hb_ot_tag_to_language(hb_tag_from_string(cstr, -1)))

    def set_script_from_ot_tag(self, value: str):
        """Sets the script of the buffer from an OpenType script tag.

        Wraps `hb_ot_tag_to_script()
        <https://harfbuzz.github.io/harfbuzz-hb-ot-layout.html#hb-ot-tag-to-script>`_
        + `hb_buffer_set_script()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-script>`_.
        """
        cdef bytes packed = value.encode()
        cdef char* cstr = packed
        hb_buffer_set_script(
            self._hb_buffer, hb_ot_tag_to_script(hb_tag_from_string(cstr, -1)))

    def add_codepoints(self, codepoints: List[int],
                       item_offset: int = 0, item_length: int = -1):
        """Appends characters from ``codepoints`` to the buffer.

        The ``item_offset`` is the position of the first character from
        ``codepoints`` that will be appended, and ``item_length`` is the
        number of characters. When shaping part of a larger text (e.g. a run
        of text from a paragraph), instead of passing just the substring
        corresponding to the run, it is preferable to pass the whole
        paragraph and specify the run start and length as ``item_offset`` and
        ``item_length``, respectively, to give HarfBuzz the full context to
        be able, for example, to do cross-run Arabic shaping or properly
        handle combining marks at start of run.

        This method does not check the validity of ``codepoints``, it is up
        to the caller to ensure it contains valid Unicode scalar values. In
        contrast, :meth:`add_utf8` and :meth:`add_str` perform sanity-check
        on the input.

        :param codepoints: A sequence of Unicode code points to append.
        :param item_offset: The offset of the first code point to add to the
            buffer.
        :param item_length: The number of code points to add to the buffer,
            or ``-1`` to add the rest of ``codepoints``.

        :raises MemoryError: If memory allocation fails.

        Wraps `hb_buffer_add_codepoints()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-add-codepoints>`_.
        """
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
                 item_offset: int = 0, item_length: int = -1):
        """Appends UTF-8 ``text`` to the buffer.

        Replaces invalid UTF-8 characters with the buffer replacement code
        point, see :attr:`replacement_codepoint`.

        :param text: UTF-8 encoded text to append.
        :param item_offset: The offset of the first character to add to the
            buffer.
        :param item_length: The number of characters to add to the buffer,
            or ``-1`` to add the rest of ``text``.

        :raises MemoryError: If memory allocation fails.

        Wraps `hb_buffer_add_utf8()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-add-utf8>`_.
        """
        hb_buffer_add_utf8(
            self._hb_buffer, text, len(text), item_offset, item_length)
        if not hb_buffer_allocation_successful(self._hb_buffer):
            raise MemoryError()

    def add_str(self, text: str,
                item_offset: int = 0, item_length: int = -1):
        """Appends ``text`` to the buffer.

        Replaces invalid characters with the buffer replacement code point,
        see :attr:`replacement_codepoint`.

        :param text: Text to append.
        :param item_offset: The offset of the first character to add to the
            buffer.
        :param item_length: The number of characters to add to the buffer,
            or ``-1`` to add the rest of ``text``.

        :raises MemoryError: If memory allocation fails.

        Wraps `hb_buffer_add_utf32()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-add-utf32>`_.
        """
        cdef Py_UCS4* ucs4_buffer
        cdef Py_ssize_t text_length

        ucs4_buffer = PyUnicode_AsUCS4Copy(text)
        if ucs4_buffer == NULL:
            raise MemoryError()
        try:
            text_length = PyUnicode_GetLength(text)
            if text_length == -1:
                raise ValueError("Invalid Unicode string")
            hb_buffer_add_utf32(
                self._hb_buffer,
                <uint32_t*>ucs4_buffer,
                text_length,
                item_offset,
                item_length
            )
            if not hb_buffer_allocation_successful(self._hb_buffer):
                raise MemoryError()
        finally:
            PyMem_Free(ucs4_buffer)

    def guess_segment_properties(self):
        """Sets unset buffer segment properties based on buffer Unicode
        contents. If the buffer is not empty, it must have content type
        :attr:`BufferContentType.UNICODE`.

        If the buffer script is not set, it will be set to the Unicode script
        of the first character in the buffer that has a script other than
        ``COMMON``, ``INHERITED``, and ``UNKNOWN``.

        Next, if the buffer direction is not set, it will be set to the
        natural horizontal direction of the buffer script.

        Finally, if the buffer language is not set, it will be set to the
        process's default language.

        Wraps `hb_buffer_guess_segment_properties()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-guess-segment-properties>`_.
        """
        hb_buffer_guess_segment_properties(self._hb_buffer)

    def set_message_func(self, callback: Callable[str]):
        """Sets the implementation function for the buffer's message
        callback.

        The callback is called with a message describing what step of the
        shaping process will be performed. Returning ``False`` from this
        callback will skip this shaping step and move to the next one.

        Wraps `hb_buffer_set_message_func()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-set-message-func>`_.
        """
        self._message_callback = callback
        hb_buffer_set_message_func(self._hb_buffer, msgcallback, <void*>callback, NULL)

    def serialize(self,
                  font: Font,
                  format: BufferSerializeFormat = BufferSerializeFormat.TEXT,
                  flags: BufferSerializeFlags = BufferSerializeFlags.DEFAULT) -> str:
        """Serializes the buffer into a textual representation of its
        content, whether Unicode codepoints or glyph identifiers and
        positioning information. This is useful for showing the contents of
        the buffer, for example during debugging.

        :param font: The :class:`Font` used to shape this buffer, needed to
            read glyph names and extents.
        :param format: The :class:`BufferSerializeFormat` to use for
            formatting the output.
        :param flags: The :class:`BufferSerializeFlags` that control what
            glyph properties to serialize.

        :returns: The serialized buffer contents.

        Wraps `hb_buffer_serialize()
        <https://harfbuzz.github.io/harfbuzz-hb-buffer.html#hb-buffer-serialize>`_.
        """
        cdef unsigned int num_glyphs = hb_buffer_get_length(self._hb_buffer)
        cdef unsigned int start = 0
        cdef char cstr[STATIC_ARRAY_SIZE]
        cdef unsigned int consumed
        cdef bytes packed = b""

        while start < num_glyphs:
            start += hb_buffer_serialize(
                self._hb_buffer,
                start,
                num_glyphs,
                cstr,
                STATIC_ARRAY_SIZE,
                &consumed,
                font._hb_font,
                format,
                flags
            )
            if consumed == 0:
                break
            packed += cstr[:consumed]

        return packed.decode()
