cdef class Blob:
    cdef hb_blob_t* _hb_blob

    def __cinit__(self, bytes data = None):
        if data is not None:
            self._hb_blob = hb_blob_create(
                data, len(data), HB_MEMORY_MODE_DUPLICATE, NULL, NULL)
        else:
            self._hb_blob = hb_blob_get_empty()

    @staticmethod
    cdef Blob from_ptr(hb_blob_t* hb_blob):
        """Create Blob from a pointer taking ownership of a it."""

        cdef Blob wrapper = Blob.__new__(Blob)
        wrapper._hb_blob = hb_blob
        return wrapper

    @classmethod
    def from_file_path(cls, filename: Union[str, Path]) -> Blob:
        cdef bytes packed = os.fsencode(filename)
        cdef hb_blob_t* blob = hb_blob_create_from_file_or_fail(<char*>packed)
        if blob == NULL:
            raise HarfBuzzError(f"Failed to open: {filename}")
        cdef Blob inst = cls(None)
        inst._hb_blob = blob
        return inst

    def __dealloc__(self):
        hb_blob_destroy(self._hb_blob)

    def __len__(self) -> int:
        return hb_blob_get_length(self._hb_blob)

    def __bool__(self) -> bool:
        return len(self) > 0

    @property
    def data(self) -> bytes:
        """Return the blob's data as bytes."""
        if not self:
            return b""
        cdef unsigned int blob_length
        cdef const_char* blob_data = hb_blob_get_data(self._hb_blob, &blob_length)
        return blob_data[:blob_length]
