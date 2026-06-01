cdef class Blob:
    """Binary data containers.

    Blobs wrap a chunk of binary data to handle lifecycle management of data
    while it is passed between client and HarfBuzz. Blobs are primarily used
    to create font faces, but also to access font face tables, as well as
    pass around other binary data.

    :param data: The binary data to wrap. If ``None`` or empty, the empty
        blob is returned.

    Wraps `hb_blob_t
    <https://harfbuzz.github.io/harfbuzz-hb-blob.html#hb-blob-t>`_.
    """

    cdef hb_blob_t* _hb_blob

    def __cinit__(self, bytes data = None):
        if data is not None:
            self._hb_blob = hb_blob_create(
                data, len(data), HB_MEMORY_MODE_DUPLICATE, NULL, NULL)
        else:
            self._hb_blob = hb_blob_get_empty()

    @staticmethod
    cdef Blob from_ptr(hb_blob_t* hb_blob):
        """Create Blob from a pointer, taking ownership of it."""

        cdef Blob wrapper = Blob.__new__(Blob)
        wrapper._hb_blob = hb_blob
        return wrapper

    @classmethod
    def from_file_path(cls, filename: Union[str, Path]) -> Blob:
        """Creates a new blob containing the data from the specified file.

        The filename is passed directly to the system on all platforms, except
        on Windows, where the filename is interpreted as UTF-8. Only if the
        filename is not valid UTF-8, it will be interpreted according to the
        system codepage.

        :param filename: A filename.

        :returns: A new :class:`Blob` with the content of the file.

        :raises HarfBuzzError: If the file cannot be opened or read.

        Wraps `hb_blob_create_from_file_or_fail()
        <https://harfbuzz.github.io/harfbuzz-hb-blob.html#hb-blob-create-from-file-or-fail>`_.
        """
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
        """Fetches the data from a blob.

        :type: bytes

        Wraps `hb_blob_get_data()
        <https://harfbuzz.github.io/harfbuzz-hb-blob.html#hb-blob-get-data>`_.
        """
        if not self:
            return b""
        cdef unsigned int blob_length
        cdef const_char* blob_data = hb_blob_get_data(self._hb_blob, &blob_length)
        return blob_data[:blob_length]
