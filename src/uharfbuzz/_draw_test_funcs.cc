#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>

#include "hb.h"

#if defined (_MSC_VER)
#define EXTERN __declspec (dllexport) extern
#else
#define EXTERN extern
#endif

extern "C" {

EXTERN void
_test_move_to (void *dfuncs,
               char *draw_data,
               void *st,
               float to_x,
               float to_y,
               void *user_data)
{
  sprintf (draw_data + strlen (draw_data), "M%g,%g", to_x, to_y);
}

EXTERN void
_test_line_to (void *dfuncs,
               char *draw_data,
               void *st,
               float to_x,
               float to_y,
               void *user_data)
{
  sprintf (draw_data + strlen (draw_data), "L%g,%g", to_x, to_y);
}

EXTERN void
_test_close_path (void *dfuncs,
                  char *draw_data,
                  void *st,
                  void *user_data)
{
  sprintf (draw_data + strlen (draw_data), "Z");
}

EXTERN void
_test_quadratic_to (void *dfuncs,
                    char *draw_data,
                    void *st,
                    float c1_x,
                    float c1_y,
                    float to_x,
                    float to_y,
                    void *user_data)
{
  sprintf (draw_data + strlen (draw_data), "Q%g,%g %g,%g", c1_x, c1_y, to_x, to_y);
}

EXTERN void
_test_cubic_to (void *dfuncs,
                char *draw_data,
                void *st,
                float c1_x,
                float c1_y,
                float c2_x,
                float c2_y,
                float to_x,
                float to_y,
                void *user_data)
{
  sprintf (draw_data + strlen (draw_data), "C%g,%g %g,%g %g,%g", c1_x, c1_y, c2_x, c2_y, to_x, to_y);
}

typedef struct {
  int level;
  char *string;
} paint_data_t;

EXTERN void*
_test_paint_data_create (size_t size)
{
  paint_data_t *data = (paint_data_t *)calloc (1, sizeof (paint_data_t));
  data->string = (char *)calloc (size, sizeof (char));
  return data;
}

EXTERN void
_test_paint_data_destroy (void *paint_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;
  free (data->string);
  free (data);
}

EXTERN char *
_test_paint_data_get_string (void *paint_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;
  return data->string;
}

static void
print (paint_data_t *data,
       const char *format,
       ...)
{
  va_list args;

  sprintf (data->string + strlen (data->string), "%*s", 2 * data->level, "");

  va_start (args, format);
  vsprintf (data->string + strlen (data->string), format, args);
  va_end (args);

  sprintf (data->string + strlen (data->string), "\n");
}

EXTERN void
_test_push_transform (hb_paint_funcs_t *funcs,
                void *paint_data,
                float xx, float yx,
                float xy, float yy,
                float dx, float dy,
                void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "start transform %.3g %.3g %.3g %.3g %.3g %.3g", xx, yx, xy, yy, dx, dy);
  data->level++;
}

EXTERN void
_test_pop_transform (hb_paint_funcs_t *funcs,
               void *paint_data,
               void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  data->level--;
  print (data, "end transform");
}

EXTERN hb_bool_t
_test_paint_color_glyph (hb_paint_funcs_t *funcs,
                   void *paint_data,
                   hb_codepoint_t glyph,
                   hb_font_t *font,
                   void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "paint color glyph %u; acting as failed", glyph);

  return false;
}

EXTERN void
_test_push_clip_glyph (hb_paint_funcs_t *funcs,
                 void *paint_data,
                 hb_codepoint_t glyph,
                 hb_font_t *font,
                 void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "start clip glyph %u", glyph);
  data->level++;
}

EXTERN void
_test_push_clip_rectangle (hb_paint_funcs_t *funcs,
                     void *paint_data,
                     float xmin, float ymin, float xmax, float ymax,
                     void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "start clip rectangle %.3g %.3g %.3g %.3g", xmin, ymin, xmax, ymax);
  data->level++;
}

EXTERN void
_test_pop_clip (hb_paint_funcs_t *funcs,
          void *paint_data,
          void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  data->level--;
  print (data, "end clip");
}

EXTERN void
_test_paint_color (hb_paint_funcs_t *funcs,
             void *paint_data,
             hb_bool_t use_foreground,
             hb_color_t color,
             void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "solid %d %d %d %d",
         hb_color_get_red (color),
         hb_color_get_green (color),
         hb_color_get_blue (color),
         hb_color_get_alpha (color));
}

EXTERN hb_bool_t
_test_paint_image (hb_paint_funcs_t *funcs,
             void *paint_data,
             hb_blob_t *blob,
             unsigned int width,
             unsigned int height,
             hb_tag_t format,
             float slant,
             hb_glyph_extents_t *extents,
             void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;
  char buf[5] = { 0, };

  hb_tag_to_string (format, buf);
  print (data, "image type %s size %u %u slant %.3g extents %d %d %d %d\n",
         buf, width, height, slant,
         extents->x_bearing, extents->y_bearing, extents->width, extents->height);

  return true;
}

static void
print_color_line (paint_data_t *data,
                  hb_color_line_t *color_line)
{
  hb_color_stop_t *stops;
  unsigned int len;

  len = hb_color_line_get_color_stops (color_line, 0, NULL, NULL);
  stops = (hb_color_stop_t *)malloc (len * sizeof (hb_color_stop_t));
  hb_color_line_get_color_stops (color_line, 0, &len, stops);

  print (data, "colors %d", hb_color_line_get_extend (color_line));
  data->level += 1;
  for (unsigned int i = 0; i < len; i++)
    print (data, "%.3g %d %d %d %d",
           stops[i].offset,
           hb_color_get_red (stops[i].color),
           hb_color_get_green (stops[i].color),
           hb_color_get_blue (stops[i].color),
           hb_color_get_alpha (stops[i].color));
  data->level -= 1;

  free (stops);
}

EXTERN void
_test_paint_linear_gradient (hb_paint_funcs_t *funcs,
                       void *paint_data,
                       hb_color_line_t *color_line,
                       float x0, float y0,
                       float x1, float y1,
                       float x2, float y2,
                       void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "linear gradient");
  data->level += 1;
  print (data, "p0 %.3g %.3g", x0, y0);
  print (data, "p1 %.3g %.3g", x1, y1);
  print (data, "p2 %.3g %.3g", x2, y2);

  print_color_line (data, color_line);
  data->level -= 1;
}

EXTERN void
_test_paint_radial_gradient (hb_paint_funcs_t *funcs,
                       void *paint_data,
                       hb_color_line_t *color_line,
                       float x0, float y0, float r0,
                       float x1, float y1, float r1,
                       void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "radial gradient");
  data->level += 1;
  print (data, "p0 %.3g %.3g radius %.3g", x0, y0, r0);
  print (data, "p1 %.3g %.3g radius %.3g", x1, y1, r1);

  print_color_line (data, color_line);
  data->level -= 1;
}

EXTERN void
_test_paint_sweep_gradient (hb_paint_funcs_t *funcs,
                      void *paint_data,
                      hb_color_line_t *color_line,
                      float cx, float cy,
                      float start_angle,
                      float end_angle,
                      void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;

  print (data, "sweep gradient");
  data->level++;
  print (data, "center %.3g %.3g", cx, cy);
  print (data, "angles %.3g %.3g", start_angle, end_angle);

  print_color_line (data, color_line);
  data->level -= 1;
}

EXTERN void
_test_push_group (hb_paint_funcs_t *funcs,
            void *paint_data,
            void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;
  print (data, "push group");
  data->level++;
}

EXTERN void
_test_pop_group (hb_paint_funcs_t *funcs,
           void *paint_data,
           hb_paint_composite_mode_t mode,
           void *user_data)
{
  paint_data_t *data = (paint_data_t *)paint_data;
  data->level--;
  print (data, "pop group mode %d", mode);
}

EXTERN hb_bool_t
_test_custom_palette_color(hb_paint_funcs_t *funcs,
                           void *paint_data,
                           unsigned int color_index,
                           hb_color_t *color,
                           void *user_data)
{
  return false;
}

}
