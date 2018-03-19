cmake_minimum_required(VERSION 3.6.0)

project(uharfbuzz)

find_package(PythonInterp REQUIRED)
find_package(PythonLibs)
find_package(PythonExtensions REQUIRED)
find_package(Cython REQUIRED)

find_library(HARFBUZZ_LIBRARY harfbuzz
             PATHS ${CMAKE_INSTALL_PREFIX}/lib
             NO_DEFAULT_PATH)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                    ${CMAKE_INSTALL_PREFIX}/include/harfbuzz)

add_cython_target(_harfbuzz)
add_library(_harfbuzz MODULE ${_harfbuzz})
target_link_libraries(_harfbuzz ${HARFBUZZ_LIBRARY})
python_extension_module(_harfbuzz)

install(TARGETS _harfbuzz LIBRARY DESTINATION src/uharfbuzz/)
