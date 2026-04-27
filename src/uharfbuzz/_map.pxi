cdef class Map:
    cdef hb_map_t* _hb_map

    INVALID_VALUE = HB_MAP_VALUE_INVALID

    def __cinit__(self, *args, **kwargs):
        self._hb_map = NULL

    def __init__(self, init = dict()):
        self._hb_map = hb_map_create()
        if not hb_map_allocation_successful(self._hb_map):
            raise MemoryError()

        self.update(init)

    def __dealloc__(self):
        hb_map_destroy(self._hb_map)

    @staticmethod
    cdef Map from_ptr(hb_map_t* hb_map):
        """Create Map from a pointer, taking ownership of it."""

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
