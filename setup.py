#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import platform
from io import open
from typing import List

import pkgconfig
from Cython.Build import cythonize
from setuptools import Extension, setup


def bool_from_environ(key: str):
    value = os.environ.get(key)
    if not value:
        return False
    if value == "1":
        return True
    if value == "0":
        return False
    raise ValueError(
        f"Environment variable {key} has invalid value {value}. Please set it to 1, 0 or an empty string"
    )


here = os.path.abspath(os.path.dirname(__file__))

# Get the long description from the README file
with open(os.path.join(here, "README.md"), encoding="utf-8") as f:
    long_description = f.read()

use_system_libraries = bool_from_environ("USE_SYSTEM_LIBS")
use_cython_linetrace = bool_from_environ("CYTHON_LINETRACE")
use_cython_annotate = bool_from_environ("CYTHON_ANNOTATE")


def _configure_extensions_with_system_libs() -> List[Extension]:
    include_dirs = []
    define_macros = []
    libraries = []
    library_dirs = []

    harfbuzz_components = ["harfbuzz-subset"]
    for harfbuzz_component in harfbuzz_components:
        harfbuzz_component_configuration = pkgconfig.parse(harfbuzz_component)
        include_dirs += harfbuzz_component_configuration["include_dirs"]
        define_macros += harfbuzz_component_configuration["define_macros"]
        libraries += harfbuzz_component_configuration["libraries"]
        library_dirs += harfbuzz_component_configuration["library_dirs"]

    if use_cython_linetrace:
        define_macros.append(("CYTHON_TRACE_NOGIL", "1"))

    extension = Extension(
        "uharfbuzz._harfbuzz",
        define_macros=define_macros,
        include_dirs=include_dirs,
        sources=[
            "src/uharfbuzz/_harfbuzz.pyx",
        ],
        language="c++",
        libraries=libraries,
        library_dirs=library_dirs,
    )

    extension_test = Extension(
        "uharfbuzz._harfbuzz_test",
        define_macros=define_macros,
        include_dirs=include_dirs,
        sources=[
            "src/uharfbuzz/_draw_test_funcs.cc",
            "src/uharfbuzz/_harfbuzz_test.pyx",
        ],
        language="c++",
        libraries=libraries,
        library_dirs=library_dirs,
    )

    return [extension, extension_test]


def _configure_extensions_with_vendored_libs() -> List[Extension]:
    # We build with HB_EXPERIMENTAL_API to enable experimental HarfBuzz features
    # like VARC table support, but we must not use any experimental APIs as it
    # will break linking with system HarfBuzz that is built without these APIs.
    define_macros = [("HB_NO_MT", "1"), ("HB_EXPERIMENTAL_API", "1")]
    if use_cython_linetrace:
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
            "harfbuzz/src/harfbuzz-subset.cc",
            "harfbuzz/src/hb-coretext.cc",
            "harfbuzz/src/hb-coretext-font.cc",
            "harfbuzz/src/hb-coretext-shape.cc",
            "harfbuzz/src/hb-directwrite.cc",
            "harfbuzz/src/hb-directwrite-font.cc",
            "harfbuzz/src/hb-directwrite-shape.cc",
            "harfbuzz/src/hb-uniscribe.cc",
            "src/uharfbuzz/_harfbuzz.pyx",
        ],
        language="c++",
        libraries=libraries,
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
    )

    extension_test = Extension(
        "uharfbuzz._harfbuzz_test",
        define_macros=define_macros,
        include_dirs=["harfbuzz/src"],
        sources=[
            "src/uharfbuzz/_draw_test_funcs.cc",
            "src/uharfbuzz/_harfbuzz_test.pyx",
        ],
        language="c++",
        libraries=libraries,
        extra_compile_args=extra_compile_args,
        extra_link_args=extra_link_args,
    )

    return [extension, extension_test]


def configure_extensions() -> List[Extension]:
    if use_system_libraries:
        return _configure_extensions_with_system_libs()
    else:
        return _configure_extensions_with_vendored_libs()


setup(
    name="uharfbuzz",
    use_scm_version={"write_to": "src/uharfbuzz/_version.py"},
    description="Streamlined Cython bindings for the harfbuzz shaping engine",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Adrien Tétar",
    author_email="adri-from-59@hotmail.fr",
    url="https://github.com/trufont/uharfbuzz",
    license="Apache License 2.0",
    package_dir={"": "src"},
    packages=["uharfbuzz"],
    zip_safe=False,
    setup_requires=["setuptools_scm"],
    python_requires=">=3.5",
    ext_modules=cythonize(
        configure_extensions(),
        annotate=use_cython_annotate,
        compiler_directives={"linetrace": use_cython_linetrace},
    ),
)
