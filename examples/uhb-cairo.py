import argparse
import sys

import cairo
import uharfbuzz as hb


class State:
    cr: cairo.Context
    font: hb.Font
    drawfuncs: hb.DrawFuncs
    foreground: hb.Color

    def __init__(
        self,
        cr: cairo.Context,
        font: hb.Font,
        drawfuncs: hb.DrawFuncs,
        foreground: hb.Color,
    ):
        self.cr = cr
        self.font = font
        self.drawfuncs = drawfuncs
        self.foreground = foreground


# Draw functions
def move_to_func(
    x: float,
    y: float,
    cr: cairo.Context,
):
    cr.move_to(x, y)


def line_to_func(
    x: float,
    y: float,
    cr: cairo.Context,
):
    cr.line_to(x, y)


def cubic_to_func(
    c1x: float,
    c1y: float,
    c2x: float,
    c2y: float,
    x: float,
    y: float,
    cr: cairo.Context,
):
    cr.curve_to(c1x, c1y, c2x, c2y, x, y)


def close_path_func(cr: cairo.Context):
    cr.close_path()


# Paint functions
def composite_mode_to_cairo(mode: hb.PaintCompositeMode):
    if mode == hb.PaintCompositeMode.CLEAR:
        return cairo.Operator.CLEAR
    elif mode == hb.PaintCompositeMode.SRC:
        return cairo.Operator.SOURCE
    elif mode == hb.PaintCompositeMode.DEST:
        return cairo.Operator.DEST
    elif mode == hb.PaintCompositeMode.SRC_OVER:
        return cairo.Operator.OVER
    elif mode == hb.PaintCompositeMode.DEST_OVER:
        return cairo.Operator.DEST_OVER
    elif mode == hb.PaintCompositeMode.SRC_IN:
        return cairo.Operator.IN
    elif mode == hb.PaintCompositeMode.DEST_IN:
        return cairo.Operator.DEST_IN
    elif mode == hb.PaintCompositeMode.SRC_OUT:
        return cairo.Operator.OUT
    elif mode == hb.PaintCompositeMode.DEST_OUT:
        return cairo.Operator.DEST_OUT
    elif mode == hb.PaintCompositeMode.SRC_ATOP:
        return cairo.Operator.ATOP
    elif mode == hb.PaintCompositeMode.DEST_ATOP:
        return cairo.Operator.DEST_ATOP
    elif mode == hb.PaintCompositeMode.XOR:
        return cairo.Operator.XOR
    elif mode == hb.PaintCompositeMode.PLUS:
        return cairo.Operator.ADD
    elif mode == hb.PaintCompositeMode.SCREEN:
        return cairo.Operator.SCREEN
    elif mode == hb.PaintCompositeMode.OVERLAY:
        return cairo.Operator.OVERLAY
    elif mode == hb.PaintCompositeMode.DARKEN:
        return cairo.Operator.DARKEN
    elif mode == hb.PaintCompositeMode.LIGHTEN:
        return cairo.Operator.LIGHTEN
    elif mode == hb.PaintCompositeMode.COLOR_DODGE:
        return cairo.Operator.COLOR_DODGE
    elif mode == hb.PaintCompositeMode.COLOR_BURN:
        return cairo.Operator.COLOR_BURN
    elif mode == hb.PaintCompositeMode.HARD_LIGHT:
        return cairo.Operator.HARD_LIGHT
    elif mode == hb.PaintCompositeMode.SOFT_LIGHT:
        return cairo.Operator.SOFT_LIGHT
    elif mode == hb.PaintCompositeMode.DIFFERENCE:
        return cairo.Operator.DIFFERENCE
    elif mode == hb.PaintCompositeMode.EXCLUSION:
        return cairo.Operator.EXCLUSION
    elif mode == hb.PaintCompositeMode.MULTIPLY:
        return cairo.Operator.MULTIPLY
    elif mode == hb.PaintCompositeMode.HSL_HUE:
        return cairo.Operator.HSL_HUE
    elif mode == hb.PaintCompositeMode.HSL_SATURATION:
        return cairo.Operator.HSL_SATURATION
    elif mode == hb.PaintCompositeMode.HSL_COLOR:
        return cairo.Operator.HSL_COLOR
    elif mode == hb.PaintCompositeMode.HSL_LUMINOSITY:
        return cairo.Operator.HSL_LUMINOSITY
    else:
        raise ValueError(f"Unknown composite mode: {mode}")


def push_transform_func(
    xx: float,
    xy: float,
    yx: float,
    yy: float,
    dx: float,
    dy: float,
    state: State,
):
    cr = state.cr
    cr.save()
    cr.transform(cairo.Matrix(xx, xy, yx, yy, dx, dy))


def pop_transform_func(state: State):
    state.cr.restore()


def color_glyph_func(
    gid: int,
    state: State,
):
    print(f"color_glyph: {gid=}")
    return False


def push_clip_glyph_func(
    gid: int,
    state: State,
):
    cr = state.cr
    cr.save()
    cr.new_path()
    state.font.draw_glyph(gid, state.drawfuncs, cr)
    cr.close_path()
    cr.clip()
    return False


def push_clip_rectangle_func(
    xmin: float,
    ymin: float,
    xmax: float,
    ymax: float,
    state: State,
):
    cr = state.cr
    cr.save()
    cr.rectangle(xmin, ymin, xmax - xmin, ymax - ymin)
    cr.clip()


def pop_clip_func(state: State):
    state.cr.restore()


def color_func(color: hb.Color, is_foreground: bool, state: State):
    cr = state.cr
    if is_foreground:
        color = state.foreground
        alpha = color.alpha * state.foreground.alpha
    else:
        color = color
        alpha = color.alpha

    cr.set_source_rgba(
        color.red / 255,
        color.green / 255,
        color.blue / 255,
        alpha / 255,
    )
    cr.paint()


def image_func(
    image: hb.Blob,
    width: int,
    height: int,
    format: str,
    slant: float,
    extents: hb.GlyphExtents,
    state: State,
):
    raise NotImplementedError("image_func")
    return False


def get_color_stops(color_line: hb.ColorLine, state: State):
    stops = []
    for stop in color_line.color_stops:
        if stop.is_foreground:
            color = state.foreground
            alpha = stop.color.alpha * color.alpha
        else:
            color = stop.color
            alpha = stop.color.alpha
        stops.append([stop.offset, color, alpha])
    return stops


def normalize_color_line(color_line: hb.ColorLine, state: State):
    stops = get_color_stops(color_line, state)
    min_offset = min(stop[0] for stop in stops)
    max_offset = max(stop[0] for stop in stops)

    if min_offset != max_offset:
        for i, stop in enumerate(stops):
            stops[i][0] = (stop[0] - min_offset) / (max_offset - min_offset)

    return min_offset, max_offset, stops


def reduce_anchors(
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    x2: float,
    y2: float,
):
    q2x = x2 - x0
    q2y = y2 - y0
    q1x = x1 - x0
    q1y = y1 - y0

    s = q2x * q2x + q2y * q2y
    if s < 0.000001:
        return x0, y0, x1, y1

    k = (q2x * q1x + q2y * q1y) / s
    return x0, y0, x1 - k * q2x, y1 - k * q2y


def linear_gradient_func(
    color_line: hb.ColorLine,
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    x2: float,
    y2: float,
    state: State,
):
    min_offset, max_offset, stops = normalize_color_line(color_line, state)

    xx0, yy0, xx1, yy1 = reduce_anchors(x0, y0, x1, y1, x2, y2)
    xxx0 = xx0 + min_offset * (xx1 - xx0)
    yyy0 = yy0 + min_offset * (yy1 - yy0)
    xxx1 = xx0 + max_offset * (xx1 - xx0)
    yyy1 = yy0 + max_offset * (yy1 - yy0)

    gradient = cairo.LinearGradient(xxx0, yyy0, xxx1, yyy1)
    gradient.set_extend(color_line.extend)

    for stop in stops:
        offset, color, alpha = stop
        gradient.add_color_stop_rgba(
            offset,
            color.red / 255,
            color.green / 255,
            color.blue / 255,
            alpha / 255,
        )

    cr = state.cr
    cr.set_source(gradient)
    cr.paint()


def radial_gradient_func(
    color_line: hb.ColorLine,
    x0: float,
    y0: float,
    r0: float,
    x1: float,
    y1: float,
    r1: float,
    state: State,
):
    min_offset, max_offset, stops = normalize_color_line(color_line, state)

    xx0 = x0 + min_offset * (x1 - x0)
    yy0 = y0 + min_offset * (y1 - y0)
    xx1 = x0 + max_offset * (x1 - x0)
    yy1 = y0 + max_offset * (y1 - y0)
    rr0 = r0 + min_offset * (r1 - r0)
    rr1 = r0 + max_offset * (r1 - r0)

    gradient = cairo.RadialGradient(xx0, yy0, rr0, xx1, yy1, rr1)
    gradient.set_extend(color_line.extend)

    for stop in stops:
        offset, color, alpha = stop
        gradient.add_color_stop_rgba(
            offset,
            color.red / 255,
            color.green / 255,
            color.blue / 255,
            alpha / 255,
        )

    cr = state.cr
    cr.set_source(gradient)
    cr.paint()


def sweep_gradient_func(
    color_line: hb.ColorLine,
    x0: float,
    y0: float,
    start_angle: float,
    end_angle: float,
    state: State,
):
    raise NotImplementedError("sweep_gradient_func")


def push_group_func(state: State):
    cr = state.cr
    cr.save()
    cr.push_group()


def pop_group_func(
    mode: hb.PaintCompositeMode,
    state: State,
):
    cr = state.cr
    cr.pop_group_to_source()
    cr.set_operator(composite_mode_to_cairo(mode))
    cr.paint()
    cr.restore()


def custom_palette_color_func(color_index: int, is_foreground: bool, state: State):
    raise NotImplementedError("custom_palette_color_func")
    return None


def parse_color(color: str):
    if color.startswith("#"):
        color = color[1:]
    if len(color) == 6:
        color = color + "ff"
    if len(color) != 8:
        raise ValueError(f"Invalid color: {color}")
    r, g, b, a = (
        int(color[:2], 16),
        int(color[2:4], 16),
        int(color[4:6], 16),
        int(color[6:8], 16),
    )
    return hb.Color(r, g, b, a)


def parse_features(string: str):
    features = {}
    for feature in string.split(","):
        feature = feature.split("=")
        name = feature[0]
        if len(feature) == 1:
            value = 1
        else:
            value = feature[1]
        features[name] = value


def create_paint_funcs():
    paintfuncs = hb.PaintFuncs()
    paintfuncs.set_push_transform_func(push_transform_func)
    paintfuncs.set_pop_transform_func(pop_transform_func)
    paintfuncs.set_color_glyph_func(color_glyph_func)
    paintfuncs.set_push_clip_glyph_func(push_clip_glyph_func)
    paintfuncs.set_push_clip_rectangle_func(push_clip_rectangle_func)
    paintfuncs.set_pop_clip_func(pop_clip_func)
    paintfuncs.set_color_func(color_func)
    paintfuncs.set_linear_gradient_func(linear_gradient_func)
    paintfuncs.set_radial_gradient_func(radial_gradient_func)
    paintfuncs.set_sweep_gradient_func(sweep_gradient_func)
    paintfuncs.set_image_func(image_func)
    paintfuncs.set_push_group_func(push_group_func)
    paintfuncs.set_pop_group_func(pop_group_func)
    return paintfuncs


def create_draw_funcs():
    drawfuncs = hb.DrawFuncs()
    drawfuncs.set_move_to_func(move_to_func)
    drawfuncs.set_line_to_func(line_to_func)
    drawfuncs.set_cubic_to_func(cubic_to_func)
    drawfuncs.set_close_path_func(close_path_func)
    return drawfuncs


def main(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("font")
    parser.add_argument("text")
    parser.add_argument(
        "-o",
        "--output-file",
        type=argparse.FileType("wb"),
        default=sys.stdout.buffer,
        help="Set output file-name (default: stdout)",
    )
    parser.add_argument(
        "-y",
        "--face-index",
        metavar="index",
        type=int,
        default=0,
        help="Set face index (default: 0)",
    )
    parser.add_argument(
        "--font-size",
        type=int,
        default=256,
        help="Set font size (default: 256)",
    )
    parser.add_argument(
        "--direction",
        metavar="ltr/rtl/ttb/btt",
        help="Set text direction (default: auto)",
    )
    parser.add_argument(
        "--script",
        metavar="--script=ISO-15924 tag",
        help="Set text script (default: auto)",
    )
    parser.add_argument(
        "--language",
        metavar="BCP 47 tag",
        help="Set text language (default: $LANG)",
    )
    parser.add_argument(
        "--features",
        metavar="list",
        default="",
        help="Comma-separated list of font features",
    )
    parser.add_argument(
        "--foreground",
        help="Set foreground color (default: #000000)",
        default="#000000",
    )
    args = parser.parse_args(argv)

    features = parse_features(args.features)
    foreground = parse_color(args.foreground)
    paintfuncs = create_paint_funcs()
    drawfuncs = create_draw_funcs()

    blob = hb.Blob.from_file_path(args.font)
    face = hb.Face(blob)
    font = hb.Font(face)

    if args.font_size:
        font.scale = (args.font_size, args.font_size)

    buf = hb.Buffer()
    buf.add_str(args.text)

    if args.direction:
        buf.direction = args.direction
    if args.script:
        buf.script = args.script
    if args.language:
        buf.language = args.language
    buf.guess_segment_properties()

    extents = font.get_font_extents("LTR")

    hb.shape(font, buf, features)
    infos, positions = buf.glyph_infos, buf.glyph_positions

    margin = extents.ascender / 10

    width = sum(pos.x_advance for pos in positions) + margin * 2
    height = extents.ascender - extents.descender + extents.line_gap + margin * 2
    with cairo.SVGSurface(args.output_file, width, height) as surface:
        cr = cairo.Context(surface)
        cr.transform(cairo.Matrix(1, 0, 0, -1, margin, extents.ascender + margin))
        state = State(cr, font, drawfuncs, foreground)
        for info, pos in zip(infos, positions):
            cr.save()
            cr.translate(pos.x_offset, pos.y_offset)
            font.paint_glyph(info.codepoint, paintfuncs, state)
            cr.restore()
            cr.translate(pos.x_advance, 0)


if __name__ == "__main__":
    main()
