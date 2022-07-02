#!/usr/bin/env python3
import os
import platform
from io import open

from Cython.Build import cythonize
from setuptools import Extension, setup

here = os.path.abspath(os.path.dirname(__file__))

define_macros = [("HB_NO_MT", "1"), ("HB_EXPERIMENTAL_API", "1")]
linetrace = False
if int(os.environ.get("CYTHON_LINETRACE", "0")):
    linetrace = True
    define_macros.append(("CYTHON_TRACE_NOGIL", "1"))

extra_compile_args = []
extra_link_args = []
libraries = []
if platform.system() != "Windows":
    extra_compile_args.append("-std=c++11")
    define_macros.append(("HAVE_MMAP", "1"))
    define_macros.append(("HAVE_UNISTD_H", "1"))
    define_macros.append(("HAVE_SYS_MMAN_H", "1"))
else:
    define_macros.append(("HAVE_DIRECTWRITE", "1"))
    define_macros.append(("HAVE_UNISCRIBE", "1"))
    libraries += ["usp10", "gdi32", "user32", "rpcrt4", "dwrite"]

if platform.system() == "Darwin":
    define_macros.append(("HAVE_CORETEXT", "1"))
    extra_link_args.extend(["-framework", "ApplicationServices"])

extension = Extension(
    "uharfbuzz._harfbuzz",
    define_macros=define_macros,
    include_dirs=["harfbuzz/src"],
    sources=[
        "src/uharfbuzz/_harfbuzz.pyx",
        "harfbuzz/src/harfbuzz.cc",
        "harfbuzz/src/hb-subset-repacker.cc",
    ],
    language="c++",
    libraries=libraries,
    extra_compile_args=extra_compile_args,
    extra_link_args=extra_link_args,
)

setup(
    zip_safe=False,
    ext_modules=cythonize(
        extension,
        annotate=bool(int(os.environ.get("CYTHON_ANNOTATE", "0"))),
        compiler_directives={"linetrace": linetrace},
    ),
)
