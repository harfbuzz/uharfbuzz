cdef class Set:
    """Data type for holding a set of integers. :class:`Set` is used to
    gather and contain glyph IDs, Unicode code points, and various other
    collections of discrete values.

    .. attribute:: INVALID_VALUE

       Unset set value.

       Wraps `HB_SET_VALUE_INVALID
       <https://harfbuzz.github.io/harfbuzz-hb-set.html#HB-SET-VALUE-INVALID:CAPS>`_.

    Wraps `hb_set_t
    <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-t>`_.
    """

    cdef hb_set_t* _hb_set

    INVALID_VALUE = HB_SET_VALUE_INVALID

    def __cinit__(self, *args, **kwargs):
        self._hb_set = NULL

    def __init__(self, init = set()):
        self._hb_set = hb_set_create()
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

        self.set(init)

    def __dealloc__(self):
        hb_set_destroy(self._hb_set)

    @staticmethod
    cdef Set from_ptr(hb_set_t* hb_set):
        """Create Set from a pointer, taking ownership of it."""

        cdef Set wrapper = Set.__new__(Set)
        wrapper._hb_set = hb_set
        return wrapper

    def copy(self) -> Set:
        """Allocate a copy of this set.

        :returns: Newly-allocated set.

        Wraps `hb_set_copy()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-copy>`_.
        """
        c = Set()
        c._hb_set = hb_set_copy(self._hb_set)
        return c

    def __copy__(self) -> Set:
        return self.copy()

    def clear(self):
        """Clears out the contents of this set.

        Wraps `hb_set_clear()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-clear>`_.
        """
        hb_set_clear(self._hb_set)

    def __bool__(self) -> bool:
        return not hb_set_is_empty(self._hb_set)

    def invert(self):
        """Inverts the contents of this set.

        Wraps `hb_set_invert()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-invert>`_.
        """
        hb_set_invert(self._hb_set)

    def is_inverted(self) -> bool:
        """Returns whether the set is inverted.

        :returns: ``True`` if the set is inverted, ``False`` otherwise.

        Wraps `hb_set_is_inverted()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-is-inverted>`_.
        """
        return hb_set_is_inverted(self._hb_set)

    def __contains__(self, c) -> bool:
        if type(c) != int:
            return False
        if c < 0 or c >= self.INVALID_VALUE:
            return False
        return hb_set_has(self._hb_set, c)

    def add(self, c: int):
        """Adds ``c`` to this set.

        Wraps `hb_set_add()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-add>`_.
        """
        hb_set_add(self._hb_set, c)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def add_range(self, first: int, last: int):
        """Adds all of the elements from ``first`` to ``last`` (inclusive)
        to this set.

        Wraps `hb_set_add_range()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-add-range>`_.
        """
        hb_set_add_range(self._hb_set, first, last)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def remove(self, c: int):
        """Removes ``c`` from this set, raising :class:`KeyError` if ``c``
        is not in the set.

        Wraps `hb_set_del()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-del>`_.
        """
        if not c in self:
            raise KeyError, c
        hb_set_del(self._hb_set, c)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def discard(self, c: int):
        """Removes ``c`` from this set if it is present.

        Wraps `hb_set_del()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-del>`_.
        """
        hb_set_del(self._hb_set, c)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def del_range(self, first: int, last: int):
        """Removes all of the elements from ``first`` to ``last`` (inclusive)
        from this set.

        If ``last`` is :attr:`INVALID_VALUE`, then all values greater than
        or equal to ``first`` are removed.

        Wraps `hb_set_del_range()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-del-range>`_.
        """
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
        """Tests whether this set is a subset of ``larger_set``.

        :returns: ``True`` if this set is a subset of (or equal to)
            ``larger_set``, ``False`` otherwise.

        Wraps `hb_set_is_subset()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-is-subset>`_.
        """
        return hb_set_is_subset(self._hb_set, larger_set._hb_set)

    def issuperset(self, smaller_set: Set) -> bool:
        """Tests whether ``smaller_set`` is a subset of this set.

        :returns: ``True`` if ``smaller_set`` is a subset of (or equal to)
            this set, ``False`` otherwise.

        Wraps `hb_set_is_subset()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-is-subset>`_.
        """
        return hb_set_is_subset(smaller_set._hb_set, self._hb_set)

    def _set(self, other: Set):
        hb_set_set(self._hb_set, other._hb_set)

    def set(self, other):
        """Makes the contents of this set equal to the contents of ``other``.

        :param other: Another :class:`Set`, or any iterable of integers.

        Wraps `hb_set_set()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-set>`_.
        """
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
        """Makes this set the union of itself and ``other``.

        :param other: Another :class:`Set`, or any iterable of integers.

        Wraps `hb_set_union()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-union>`_.
        """
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
        """Makes this set the intersection of itself and ``other``.

        Wraps `hb_set_intersect()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-intersect>`_.
        """
        hb_set_intersect(self._hb_set, other._hb_set)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def __iand__(self, other: Set):
        self.intersection_update(other)
        return self

    def difference_update(self, other: Set):
        """Subtracts the contents of ``other`` from this set.

        Wraps `hb_set_subtract()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-subtract>`_.
        """
        hb_set_subtract(self._hb_set, other._hb_set)
        if not hb_set_allocation_successful(self._hb_set):
            raise MemoryError()

    def __isub__(self, other: Set):
        self.difference_update(other)
        return self

    def symmetric_difference_update(self, other: Set):
        """Makes this set the symmetric difference of itself and ``other``.

        Wraps `hb_set_symmetric_difference()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-symmetric-difference>`_.
        """
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
        """The smallest element in the set, or :attr:`INVALID_VALUE` if the
        set is empty.

        :type: int

        Wraps `hb_set_get_min()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-get-min>`_.
        """
        return hb_set_get_min(self._hb_set)

    @property
    def max(self) -> int:
        """The largest element in the set, or :attr:`INVALID_VALUE` if the
        set is empty.

        :type: int

        Wraps `hb_set_get_max()
        <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-get-max>`_.
        """
        return hb_set_get_max(self._hb_set)

    def __iter__(self):
        return SetIter(self)

    def __repr__(self):
        if self.is_inverted():
            return "Set({...})"
        s = ', '.join(repr(v) for v in self)
        return ("Set({%s})" % s)

cdef class SetIter:
    """Iterator over the elements of a :class:`Set` in increasing order.

    Wraps `hb_set_next()
    <https://harfbuzz.github.io/harfbuzz-hb-set.html#hb-set-next>`_.
    """

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
