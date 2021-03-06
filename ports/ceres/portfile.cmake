# Common Ambient Variables:
#   CURRENT_BUILDTREES_DIR    = ${VCPKG_ROOT_DIR}\buildtrees\${PORT}
#   CURRENT_PACKAGES_DIR      = ${VCPKG_ROOT_DIR}\packages\${PORT}_${TARGET_TRIPLET}
#   CURRENT_PORT DIR          = ${VCPKG_ROOT_DIR}\ports\${PORT}
#   PORT                      = current port name (zlib, etc)
#   TARGET_TRIPLET            = current triplet (x86-windows, x64-windows-static, etc)
#   VCPKG_CRT_LINKAGE         = C runtime linkage type (static, dynamic)
#   VCPKG_LIBRARY_LINKAGE     = target library linkage type (static, dynamic)
#   VCPKG_ROOT_DIR            = <C:\path\to\current\vcpkg>
#   VCPKG_TARGET_ARCHITECTURE = target architecture (x64, x86, arm)
#

if(VCPKG_CRT_LINKAGE STREQUAL "static")
    message(FATAL_ERROR "Ceres does not currently support static CRT linkage")
endif()

include(vcpkg_common_functions)

set(VCPKG_PLATFORM_TOOLSET "v140") # Force VS2015 because VS2017 compiler return internal error
# eigen3\eigen\src\core\redux.h(237): fatal error C1001: An internal error has occurred in the compiler. [internal\ceres\ceres.vcxproj]

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ceres-solver/ceres-solver
    REF 1.12.0
    SHA512 4b4cba5627fbd80a626e8a31d9f561d6cee1c8345970304e4b5b163a9dcadc6d636257d1046ecede00781a11229ef671ee89c3e7e6baf15f49f63f36e6a2ebe1
    HEAD_REF master
)

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        ${CMAKE_CURRENT_LIST_DIR}/fix-find-packages.patch
)

# Ninja crash compiler with error:
# "fatal error C1001: An internal error has occurred in the compiler. (compiler file 'f:\dd\vctools\compiler\utc\src\p2\main.c', line 255)"

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DEXPORT_BUILD_DIR=ON
        -DBUILD_EXAMPLES=OFF
        -DBUILD_TESTING=OFF
        -DCXSPARSE=ON
        -DEIGENSPARSE=ON
        -DSUITESPARSE=ON
        -DGFLAGS_PREFER_EXPORTED_GFLAGS_CMAKE_CONFIGURATION=OFF # TheiaSfm doesn't work well with this
        -DGLOG_PREFER_EXPORTED_GLOG_CMAKE_CONFIGURATION=OFF # TheiaSfm doesn't work well with this
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH "CMake")

vcpkg_copy_pdbs()

# Changes target search path
file(READ ${CURRENT_PACKAGES_DIR}/share/ceres/CeresConfig.cmake CERES_TARGETS)
string(REPLACE "get_filename_component(CURRENT_ROOT_INSTALL_DIR\n    \${CERES_CURRENT_CONFIG_DIR}/../"
               "get_filename_component(CURRENT_ROOT_INSTALL_DIR\n    \${CERES_CURRENT_CONFIG_DIR}/../../" CERES_TARGETS "${CERES_TARGETS}")
file(WRITE ${CURRENT_PACKAGES_DIR}/share/ceres/CeresConfig.cmake "${CERES_TARGETS}")

# Clean
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)

# Handle copyright of suitesparse and metis
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/ceres)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/ceres/LICENSE ${CURRENT_PACKAGES_DIR}/share/ceres/copyright)
