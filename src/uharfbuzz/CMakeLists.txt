cmake_minimum_required(VERSION 3.6.0)

project(uharfbuzz)

set(CYTHON_LINETRACE OFF
    CACHE BOOL "Enable linetrace compiler directive.")
mark_as_advanced(CYTHON_LINETRACE)

if (CYTHON_LINETRACE)
  set(CYTHON_FLAGS "${CYTHON_FLAGS} -Xlinetrace=True")
endif ()

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

if (CYTHON_LINETRACE)
  set_source_files_properties(
    _harfbuzz PROPERTIES COMPILE_DEFINITIONS CYTHON_TRACE_NOGIL=1
  )
endif ()

add_library(_harfbuzz MODULE ${_harfbuzz})

if (APPLE)
  find_library(APPLICATION_SERVICES_FRAMEWORK ApplicationServices)
  if (NOT APPLICATION_SERVICES_FRAMEWORK)
    message(FATAL_ERROR "HB_HAVE_CORETEXT was set, but we failed to find ApplicationServices, which is required")
  else ()
    target_link_libraries(_harfbuzz ${APPLICATION_SERVICES_FRAMEWORK})
  endif ()
endif ()

target_link_libraries(_harfbuzz ${HARFBUZZ_LIBRARY})
python_extension_module(_harfbuzz)

install(TARGETS _harfbuzz LIBRARY DESTINATION src/uharfbuzz/)
