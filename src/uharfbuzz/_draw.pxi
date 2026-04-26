cdef void _move_to_func(hb_draw_funcs_t *dfuncs,
                        void *draw_data,
                        hb_draw_state_t *st,
                        float to_x,
                        float to_y,
                        void *user_data) noexcept:
    m = <object>user_data
    m(to_x, to_y, <object>draw_data)

cdef void _line_to_func(hb_draw_funcs_t *dfuncs,
                        void *draw_data,
                        hb_draw_state_t *st,
                        float to_x,
                        float to_y,
                        void *user_data) noexcept:
    l = <object>user_data
    l(to_x, to_y, <object>draw_data)

cdef void _close_path_func(hb_draw_funcs_t *dfuncs,
                           void *draw_data,
                           hb_draw_state_t *st,
                           void *user_data) noexcept:
    cl = <object>user_data
    cl(<object>draw_data)

cdef void _quadratic_to_func(hb_draw_funcs_t *dfuncs,
                             void *draw_data,
                             hb_draw_state_t *st,
                             float c1_x,
                             float c1_y,
                             float to_x,
                             float to_y,
                             void *user_data) noexcept:
    q = <object>user_data
    q(c1_x, c1_y, to_x, to_y, <object>draw_data)

cdef void _cubic_to_func(hb_draw_funcs_t *dfuncs,
                         void *draw_data,
                         hb_draw_state_t *st,
                         float c1_x,
                         float c1_y,
                         float c2_x,
                         float c2_y,
                         float to_x,
                         float to_y,
                         void *user_data) noexcept:
    c = <object>user_data
    c(c1_x, c1_y, c2_x, c2_y, to_x, to_y, <object>draw_data)


cdef class DrawFuncs:
    cdef hb_draw_funcs_t* _hb_drawfuncs
    cdef object _move_to_func
    cdef object _line_to_func
    cdef object _cubic_to_func
    cdef object _quadratic_to_func
    cdef object _close_path_func

    def __cinit__(self):
        self._hb_drawfuncs = hb_draw_funcs_create()

    def __dealloc__(self):
        hb_draw_funcs_destroy(self._hb_drawfuncs)

    @deprecated("Font.draw_glyph()")
    def get_glyph_shape(self, font: Font, gid: int):
        font.draw_glyph(gid, self)

    @deprecated("Font.draw_glyph()")
    def draw_glyph(self, font: Font, gid: int, draw_data: object = None):
        font.draw_glyph(gid, self, draw_data)

    def set_move_to_func(self,
                         func: Callable[[
                             float,
                             float,
                             object,  # draw_data
                         ], None],
                         user_data: object = None):
        cdef hb_draw_move_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._move_to_func = None
            func_p = <hb_draw_move_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._move_to_func = func
            func_p = _move_to_func
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_move_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_line_to_func(self,
                         func: Callable[[
                             float,
                             float,
                             object,  # draw_data
                         ], None],
                         user_data: object = None):
        cdef hb_draw_line_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._line_to_func = None
            func_p = <hb_draw_line_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._line_to_func = func
            func_p = _line_to_func
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_line_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_cubic_to_func(self,
                          func: Callable[[
                             float,
                             float,
                             float,
                             float,
                             float,
                             float,
                             object,  # draw_data
                          ], None],
                          user_data: object = None):
        cdef hb_draw_cubic_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._cubic_to_func = None
            func_p = <hb_draw_cubic_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._cubic_to_func = func
            func_p = _cubic_to_func
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_cubic_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_quadratic_to_func(self,
                              func: Callable[[
                                 float,
                                 float,
                                 float,
                                 float,
                                 object,  # draw_data
                              ], None],
                              user_data: object = None):
        cdef hb_draw_quadratic_to_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._quadratic_to_func = None
            func_p = <hb_draw_quadratic_to_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._quadratic_to_func = func
            func_p = _quadratic_to_func
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_quadratic_to_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)

    def set_close_path_func(self,
                            func: Callable[[
                                object
                            ], None],
                            user_data: object = None):
        cdef hb_draw_close_path_func_t func_p
        cdef void *user_data_p
        if PyCapsule_IsValid(func, NULL):
            self._close_path_func = None
            func_p = <hb_draw_close_path_func_t>PyCapsule_GetPointer(func, NULL)
            if PyCapsule_IsValid(user_data, NULL):
                user_data_p = <void*>PyCapsule_GetPointer(user_data, NULL)
            else:
                user_data_p = <void*>user_data
        else:
            self._close_path_func = func
            func_p = _close_path_func
            assert user_data is None, "Pass draw_state to Font.draw_glyph"
            user_data_p = <void*>func
        hb_draw_funcs_set_close_path_func(
            self._hb_drawfuncs, func_p, user_data_p, NULL)
