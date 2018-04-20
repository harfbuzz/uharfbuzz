#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from io import open
import os


here = os.path.abspath(os.path.dirname(__file__))

# Get the long description from the README file
with open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

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
)


if __name__ == "__main__":
    import sys
    # cibuildwheel calls setup.py --name to get the package name, but
    # by then scikit-build has not been installed yet...
    if len(sys.argv) == 2 and sys.argv[1] == "--name":
        from setuptools import setup
    else:
        from skbuild import setup
    setup(**setup_params)
