#include <stdio.h>
#include <string.h>

#if defined (_MSC_VER)
#define EXTERN __declspec (dllexport) extern
#else
#define EXTERN extern
#endif

extern "C" {

EXTERN void
_test_move_to (void *dfuncs,
               void *draw_data,
               void *st,
               float to_x,
               float to_y,
               char *user_data)
{
  sprintf (user_data + strlen (user_data), "M%g,%g", to_x, to_y);
}

EXTERN void
_test_line_to (void *dfuncs,
               void *draw_data,
               void *st,
               float to_x,
               float to_y,
               char *user_data)
{
  sprintf (user_data + strlen (user_data), "L%g,%g", to_x, to_y);
}

EXTERN void
_test_close_path (void *dfuncs,
                  void *draw_data,
                  void *st,
                  char *user_data)
{
  sprintf (user_data + strlen (user_data), "Z");
}

EXTERN void
_test_quadratic_to (void *dfuncs,
                    void *draw_data,
                    void *st,
                    float c1_x,
                    float c1_y,
                    float to_x,
                    float to_y,
                    char *user_data)
{
  sprintf (user_data + strlen (user_data), "Q%g,%g %g,%g", c1_x, c1_y, to_x, to_y);
}

EXTERN void
_test_cubic_to (void *dfuncs,
                void *draw_data,
                void *st,
                float c1_x,
                float c1_y,
                float c2_x,
                float c2_y,
                float to_x,
                float to_y,
                char *user_data)
{
  sprintf (user_data + strlen (user_data), "C%g,%g %g,%g %g,%g", c1_x, c1_y, c2_x, c2_y, to_x, to_y);
}

}
