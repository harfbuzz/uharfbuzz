#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from io import open
import os
import sys


here = os.path.abspath(os.path.dirname(__file__))

# Get the long description from the README file
with open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

cmake_args = []
for option in ("CYTHON_LINETRACE", "CYTHON_ANNOTATE"):
    value = os.environ.get(option)
    if value is not None and bool(int(value)):
        cmake_args.append("-D{}:BOOL=TRUE".format(option))

# On Mac, require OSX >= 10.9 so we can use te new libc++ targeting C++11
if sys.platform == "darwin":
    cmake_args.append("-DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.9")

setup_params = dict(
    name="uharfbuzz",
    use_scm_version=True,
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
    cmake_args=cmake_args,
    python_requires=">=3.5",
)


if __name__ == "__main__":
    import sys
    # cibuildwheel calls setup.py --name to get the package name; no need
    # to require scikit-build at that stage: it will be installed later with
    # the rest of the build requirements. Also, creating an sdist can be done
    # with plain setuptools since there is no cmake involved there, and we
    # generate the manifest using setuptools_scm anyway.
    args = sys.argv[1:]
    if len(args) == 1 and {"--name", "sdist"}.intersection(args):
        from setuptools import setup
    else:
        from skbuild import setup
    setup(**setup_params)
