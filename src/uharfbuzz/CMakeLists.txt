include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                    ${CMAKE_SOURCE_DIR}/third_party/harfbuzz/src)

add_cython_target(_harfbuzz)
add_library(_harfbuzz MODULE ${_harfbuzz})
target_link_libraries(_harfbuzz harfbuzz)
python_extension_module(_harfbuzz)

install(TARGETS _harfbuzz LIBRARY DESTINATION src/uharfbuzz/)
