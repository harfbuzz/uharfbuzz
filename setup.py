#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from skbuild import setup


setup(
    name="uharfbuzz",
    version="0.1.0.dev0",
    description="Streamlined Cython bindings for the harfbuzz shaping engine",
    author="Adrien Tétar",
    author_email="adri-from-59@hotmail.fr",
    url="https://github.com/trufont/uharfbuzz",
    license="Apache License 2.0",
    package_dir={"": "src"},
    packages=["uharfbuzz"],
    zip_safe=False,
)
