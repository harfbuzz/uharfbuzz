project('foo', 'cython', 'cpp')

py = import('python').find_installation()
dep_py = py.dependency()

harfbuzz_includes = include_directories('harfbuzz/src')
harfbuzz = static_library(
    'harfbuzz',
    'harfbuzz/src/harfbuzz-subset.cc',
    'harfbuzz/src/hb-coretext.cc',
    'harfbuzz/src/hb-directwrite.cc',
    'harfbuzz/src/hb-uniscribe.cc',
    cpp_args: '-DHB_NO_MT=1 -DHB_EXPERIMENTAL_API=1',
    include_directories: harfbuzz_includes,
)

py.extension_module(
    'uharfbuzz',
    'src/uharfbuzz/_harfbuzz.pyx',
    dependencies: dep_py,
    include_directories: harfbuzz_includes,
    install: true,
    link_with: [harfbuzz],
    override_options: ['cython_language=cpp'],
)
