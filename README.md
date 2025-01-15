[![Githun CI Status](https://github.com/harfbuzz/uharfbuzz/workflows/Build%20+%20Deploy/badge.svg)](https://github.com/harfbuzz/uharfbuzz/actions?query=workflow%3A%22Build+%2B+Deploy%22)
[![PyPI](https://img.shields.io/pypi/v/uharfbuzz.svg)](https://pypi.org/project/uharfbuzz)
[![Documentation Status](https://readthedocs.org/projects/uharfbuzz/badge/?version=stable)](https://uharfbuzz.readthedocs.io)

## uharfbuzz

Streamlined Cython bindings for the [HarfBuzz][hb] shaping engine.


### Example

```python
import sys

import uharfbuzz as hb


fontfile = sys.argv[1]
text = sys.argv[2]

blob = hb.Blob.from_file_path(fontfile)
face = hb.Face(blob)
font = hb.Font(face)

buf = hb.Buffer()
buf.add_str(text)
buf.guess_segment_properties()

features = {"kern": True, "liga": True}
hb.shape(font, buf, features)

infos = buf.glyph_infos
positions = buf.glyph_positions

for info, pos in zip(infos, positions):
    gid = info.codepoint
    glyph_name = font.glyph_to_string(gid)
    cluster = info.cluster
    x_advance = pos.x_advance
    x_offset = pos.x_offset
    y_offset = pos.y_offset
    print(f"{glyph_name} gid{gid}={cluster}@{x_advance},{y_offset}+{x_advance}")
```

### Installation

When building the uharfbuzz package, it automatically incorporates minimal HarfBuzz sources so you don't have to install the native HarfBuzz library.

However, if you want to use uharfbuzz with your system-provided HarfBuzz (e.g., if you built it from sources with custom configuration), you can set `USE_SYSTEM_LIBS=1` environment variable (see example below).

```shell
USE_SYSTEM_LIBS=1 pip install uharfbuzz --no-binary :uharfbuzz:
```

harfbuzz installation is found using `pkg-config`, so you must have harfbuzz's `.pc` files in your system.
If you've built it from sources, meson installs them automatically. Otherwise, you may want to install harfbuzz development package, like `harfbuzz-devel` on Fedora-derived distros.

### How to make a release

Use `git tag -a` to make a new annotated tag, or `git tag -s` for a GPG-signed annotated tag, if you prefer.

Name the new tag with with a leading ‘v’ followed by three MAJOR.MINOR.PATCH digits, like in semantic versioning. Look at the existing tags for examples.

In the tag message write some short release notes describing the changes since the previous tag. The subject line will be the release name and the message body will be the release notes.

Finally, push the tag to the remote repository (e.g. assuming upstream is called origin):

    $ git push origin v0.4.3

This will trigger the CI to build the distribution packages and upload them to the Python Package Index automatically, if all the tests pass successfully. The CI will also automatically create a new Github Release and use the content of the annotated git tag for the release notes.


[hb]: https://github.com/harfbuzz/harfbuzz
