#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from io import open
import os
import sys
from setuptools import Extension, setup
from Cython.Build import cythonize

here = os.path.abspath(os.path.dirname(__file__))

# Get the long description from the README file
with open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

extra_args = []
linetrace = False
if int(os.environ.get('CYTHON_LINETRACE', '0')):
    linetrace = True
    extra_args.append(('CYTHON_TRACE_NOGIL', '1'))

if int(os.environ.get('USE_SYSTEM_HARFBUZZ', '0')):
    extension = Extension(
        'uharfbuzz._harfbuzz',
        libraries = ['harfbuzz'],
        include_dirs = ['/usr/include/harfbuzz'],
        sources=['src/uharfbuzz/_harfbuzz.pyx']
    )
else:
    extension = Extension(
        'uharfbuzz._harfbuzz',
        define_macros=[('HB_NO_MT', '1')],
        include_dirs=['harfbuzz/src'],
        sources=['src/uharfbuzz/_harfbuzz.pyx', 'harfbuzz/src/harfbuzz.cc']
    )

setup_params = dict(
    name="uharfbuzz",
    use_scm_version={"write_to": "src/uharfbuzz/_version.py"},
    description="Streamlined Cython bindings for the harfbuzz shaping engine",
    long_description=long_description,
    long_description_content_type='text/markdown',
    author="Adrien Tétar",
    author_email="adri-from-59@hotmail.fr",
    url="https://github.com/trufont/uharfbuzz",
    license="Apache License 2.0",
    package_dir={"": "src"},
    packages=["uharfbuzz"],
    zip_safe=False,
    setup_requires=["setuptools_scm"],
    python_requires=">=3.5",
    ext_modules = cythonize(
        extension,
        annotate=bool(int(os.environ.get('CYTHON_ANNOTATE', '0'))),
        compiler_directives={"linetrace": linetrace}
    )
)


if __name__ == "__main__":
    setup(**setup_params)
