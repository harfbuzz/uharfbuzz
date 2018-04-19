#!/usr/bin/python3

import uharfbuzz as hb
import sys


with open(sys.argv[1], 'rb') as fontfile:
    fontdata = fontfile.read()

text = sys.argv[2]

face = hb.Face.create(fontdata)
font = hb.Font.create(face)
upem = face.upem

font.scale = (upem, upem)
hb.ot_font_set_funcs(font)

buf = hb.Buffer.create()

def debug_message(msg):
    print(msg)
    return True

buf.set_message_func(debug_message)

buf.add_str(text)
buf.guess_segment_properties()

features = {"kern": True, "liga": True}
hb.shape(font, buf, features)

infos = buf.glyph_infos
positions = buf.glyph_positions

for info, pos in zip(infos, positions):
    gid = info.codepoint
    cluster = info.cluster
    x_advance = pos.x_advance
    x_offset = pos.x_offset
    y_offset = pos.y_offset
    print(f"gid{gid}={cluster}@{x_advance},{x_offset}+{y_offset}")
