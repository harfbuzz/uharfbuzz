cmake_minimum_required(VERSION 3.6.0)

project(uharfbuzz)

find_package(PythonInterp REQUIRED)
find_package(PythonLibs)
find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)

# we need to compile static harfuzz library with -fPIC so it can be
# included in the cython extension module
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory(third_party/harfbuzz)

add_subdirectory(src/uharfbuzz)
