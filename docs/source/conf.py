# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html


# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = "uharfbuzz"
copyright = "2024, Adrien Tétar"
author = "HarfBuzz Contributors"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "sphinx.ext.autodoc",
    "myst_parser",
]

# Cython emits parameter annotations as string forward references (e.g.
# `font: 'Font'`). Sphinx renders these as `~uharfbuzz._harfbuzz.Font` with
# the `~` displayed literally. Strip the qualifier ourselves.
import re as _re

_QUALIFIED_TYPE_RE = _re.compile(r"~?uharfbuzz(?:\._harfbuzz)?\.")


def _strip_module_prefix(app, what, name, obj, options, signature, return_annotation):
    if signature:
        signature = _QUALIFIED_TYPE_RE.sub("", signature)
    if return_annotation:
        return_annotation = _QUALIFIED_TYPE_RE.sub("", return_annotation)
    return signature, return_annotation


def setup(app):
    app.connect("autodoc-process-signature", _strip_module_prefix)

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"
