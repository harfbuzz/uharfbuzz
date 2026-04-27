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
        """Create Set from a pointer, taking ownership of it."""

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
