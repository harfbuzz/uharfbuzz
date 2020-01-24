cmake_minimum_required(VERSION 3.6.0)

project(uharfbuzz_skbuild)

include(ExternalProject)

set(HARFBUZZ_VERSION "2.6.4")
set(HARFBUZZ_SHA256 "9413b8d96132d699687ef914ebb8c50440efc87b3f775d25856d7ec347c03c12")

# download, configure, build and install harbfuzz static library
ExternalProject_Add(
    harfbuzz
    URL "https://github.com/harfbuzz/harfbuzz/releases/download/${HARFBUZZ_VERSION}/harfbuzz-${HARFBUZZ_VERSION}.tar.xz"
    URL_HASH SHA256=${HARFBUZZ_SHA256}
    CMAKE_CACHE_ARGS
      -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
      -DCMAKE_CONFIGURATION_TYPES:STRING=${CMAKE_CONFIGURATION_TYPES}
      -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
      -DHB_BUILD_TESTS:BOOL=OFF
      -DHB_BUILD_SUBSET:BOOL=OFF
    # use a shorter prefix to fit in the Windows paths' 260-char limit
    PREFIX hb
)

# this allows to use a step from an external project as a dependency of
# another target. We want to install the harbuzz library before the
# uharfbuzz module reaches its configure step
ExternalProject_Add_StepTargets(harfbuzz install)

# build the Cython wrapper as an external project, and pass down to it all
# the cmake variables set by scikit-build in the top-level CMakeLists.txt
ExternalProject_Add(
    uharfbuzz
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/src/uharfbuzz
    CMAKE_CACHE_ARGS
      -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
      -DCMAKE_CONFIGURATION_TYPES:STRING=${CMAKE_CONFIGURATION_TYPES}
      -DPYTHON_EXECUTABLE:FILEPATH=${PYTHON_EXECUTABLE}
      -DPYTHON_VERSION_STRING:STRING=${PYTHON_VERSION_STRING}
      -DPYTHON_INCLUDE_DIR:PATH=${PYTHON_INCLUDE_DIR}
      -DPYTHON_LIBRARY:FILEPATH=${PYTHON_LIBRARY}
      -DCYTHON_ANNOTATE:BOOL=${CYTHON_ANNOTATE}
      -DCYTHON_FLAGS:STRING=${CYTHON_FLAGS}
      -DCYTHON_LINETRACE:BOOL=${CYTHON_LINETRACE}
      -DSKBUILD:BOOL=${SKBUILD}
      -DCMAKE_MODULE_PATH:PATH=${CMAKE_MODULE_PATH}
    DEPENDS harfbuzz-install
    BUILD_ALWAYS 1
    DOWNLOAD_COMMAND ""
    UPDATE_COMMAND ""
    PATCH_COMMAND ""
    INSTALL_COMMAND ""
)
ExternalProject_Get_Property(uharfbuzz BINARY_DIR)

# This adds an "install" target in the top-level directory, that
# simply includes the install rules associated with the inner build
install(SCRIPT ${BINARY_DIR}/cmake_install.cmake)
