# FindXercesC.cmake
#
# Custom find module that shadows CMake's built-in FindXercesC.cmake (this
# directory is on CMAKE_MODULE_PATH; see root CMakeLists.txt). Mirrors the
# structure of FindSndFile.cmake.
#
# Search order:
#   1. Already-set cache (XercesC_LIBRARY + XercesC_INCLUDE_DIR).
#   2. CONFIG-mode `find_package(XercesC CONFIG QUIET)` — picks up vcpkg,
#      Homebrew, anything that ships `XercesCConfig.cmake`.
#   3. Legacy MODULE-mode hunting (find_path / find_library) — covers
#      apt-installed system xerces, manual Unix builds.
#   4. (Windows only) FetchContent the official xerces-c source tarball
#      from Apache's archive and add_subdirectory it. Gated by
#      DISSCO_XERCES_FETCH_SOURCE (ON by default on Windows, OFF elsewhere
#      since brew / apt cover it). The build takes a few minutes cold; once
#      built, ccache makes reruns cheap.
#
# Always-set outputs on success:
#   XercesC_FOUND        - True
#   XercesC_INCLUDE_DIR  - Directory containing xercesc/util/PlatformUtils.hpp
#   XercesC_LIBRARY      - Path to the link library or target name
#   XercesC_LIBRARIES    - Same as XercesC_LIBRARY (list form, legacy var)
#   XercesC_VERSION      - Discovered version string (when knowable)
#   XercesC::XercesC     - Imported target consumers can link against
#   XERCESC_DLL          - (Windows only, prebuilt/FetchContent) Path to
#                          xerces-c_*.dll for downstream install() rules.

set(XercesC_FOUND FALSE)

# Helper: after a successful CONFIG-mode find_package, derive the legacy
# singular vars (XercesC_LIBRARY, XercesC_INCLUDE_DIR) the project consumes.
#
# Two flavors of XercesCConfig.cmake exist in the wild:
#   - The "old" / FindXercesC-compatible flavor sets XercesC_INCLUDE_DIRS
#     and XercesC_LIBRARIES (plural) directly. Homebrew ships this, with
#     XercesC::XercesC as an INTERFACE IMPORTED wrapping xerces_xerces-c.
#   - The "new" upstream flavor only defines the XercesC::XercesC target
#     and leaves the legacy vars unset. vcpkg ships this.
#
# We try the plural vars first, then fall back to extracting from the
# target's interface properties; in either case the target itself is what
# downstream linkers actually use.
function(_dissco_xerces_extract_from_target)
    if(NOT TARGET XercesC::XercesC)
        return()
    endif()

    # Path 1 — plural vars set by old-flavor config.
    if(XercesC_INCLUDE_DIRS AND XercesC_LIBRARIES)
        list(GET XercesC_INCLUDE_DIRS 0 _inc)
        set(XercesC_INCLUDE_DIR "${_inc}"                PARENT_SCOPE)
        set(XercesC_LIBRARY     "${XercesC_LIBRARIES}"   PARENT_SCOPE)
        set(XercesC_FOUND       TRUE                     PARENT_SCOPE)
        return()
    endif()

    # Path 2 — query the imported target. INTERFACE imported targets
    # don't have IMPORTED_LOCATION; fall back to the target name itself
    # (CMake resolves it at link time).
    get_target_property(_inc XercesC::XercesC INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(_type XercesC::XercesC TYPE)

    set(_loc "")
    if(NOT _type STREQUAL "INTERFACE_LIBRARY")
        foreach(_cfg IMPORTED_LOCATION_RELEASE IMPORTED_LOCATION_RELWITHDEBINFO
                     IMPORTED_LOCATION_MINSIZEREL IMPORTED_LOCATION_DEBUG
                     IMPORTED_LOCATION)
            get_target_property(_loc XercesC::XercesC ${_cfg})
            if(_loc AND NOT _loc STREQUAL "_loc-NOTFOUND")
                break()
            endif()
        endforeach()
    endif()
    if(NOT _loc OR _loc STREQUAL "_loc-NOTFOUND")
        # INTERFACE library — link via the target name and let CMake resolve.
        set(_loc "XercesC::XercesC")
    endif()

    if(_inc AND _loc)
        # _inc may be a list (generator-expression-flavored); take the
        # first concrete path for the legacy singular var.
        list(GET _inc 0 _first_inc)
        set(XercesC_INCLUDE_DIR "${_first_inc}" PARENT_SCOPE)
        set(XercesC_LIBRARY     "${_loc}"       PARENT_SCOPE)
        set(XercesC_FOUND       TRUE            PARENT_SCOPE)
    endif()
endfunction()

# Helper: derive XercesC_VERSION by grepping XercesVersion.hpp.
function(_dissco_xerces_extract_version include_dir out_var)
    set(_hdr "${include_dir}/xercesc/util/XercesVersion.hpp")
    if(NOT EXISTS "${_hdr}")
        return()
    endif()
    file(STRINGS "${_hdr}" _maj REGEX "^#define[ \t]+XERCES_VERSION_MAJOR[ \t]+[0-9]+")
    file(STRINGS "${_hdr}" _min REGEX "^#define[ \t]+XERCES_VERSION_MINOR[ \t]+[0-9]+")
    file(STRINGS "${_hdr}" _rev REGEX "^#define[ \t]+XERCES_VERSION_REVISION[ \t]+[0-9]+")
    string(REGEX MATCH "[0-9]+" _maj "${_maj}")
    string(REGEX MATCH "[0-9]+" _min "${_min}")
    string(REGEX MATCH "[0-9]+" _rev "${_rev}")
    if(_maj AND _min AND _rev)
        set(${out_var} "${_maj}.${_min}.${_rev}" PARENT_SCOPE)
    endif()
endfunction()

# (1) Pre-set by user / parent project — trust it.
if(XercesC_INCLUDE_DIR AND XercesC_LIBRARY)
    set(XercesC_LIBRARIES "${XercesC_LIBRARY}")
    set(XercesC_FOUND TRUE)
endif()

# (2) CONFIG mode — vcpkg, brew, distros shipping XercesCConfig.cmake.
if(NOT XercesC_FOUND)
    find_package(XercesC CONFIG QUIET)
    if(XercesC_FOUND)
        _dissco_xerces_extract_from_target()
        if(XercesC_FOUND)
            message(STATUS "FindXercesC: using CONFIG-mode XercesC::XercesC (${XercesC_LIBRARY})")
        endif()
    endif()
endif()

# (3) Legacy MODULE-mode path hunting. Same shape as CMake's built-in.
if(NOT XercesC_FOUND)
    find_path(XercesC_INCLUDE_DIR xercesc/util/PlatformUtils.hpp
        HINTS
            "/usr/local/opt/xerces-c/include"
            "/opt/homebrew/opt/xerces-c/include"
        PATHS /usr/local/include /usr/include
    )
    find_library(XercesC_LIBRARY
        NAMES xerces-c xerces-c_3 xerces-c_3_2 xerces-c_3_3
        HINTS
            "/usr/local/opt/xerces-c/lib"
            "/opt/homebrew/opt/xerces-c/lib"
        PATHS /usr/local/lib /usr/lib
    )
    if(XercesC_INCLUDE_DIR AND XercesC_LIBRARY)
        set(XercesC_FOUND TRUE)
        message(STATUS "FindXercesC: legacy MODULE-mode find — ${XercesC_LIBRARY}")
        if(NOT TARGET XercesC::XercesC)
            add_library(XercesC::XercesC UNKNOWN IMPORTED)
            set_target_properties(XercesC::XercesC PROPERTIES
                IMPORTED_LOCATION "${XercesC_LIBRARY}"
                INTERFACE_INCLUDE_DIRECTORIES "${XercesC_INCLUDE_DIR}"
            )
        endif()
    endif()
endif()

# (4) Windows FetchContent fallback: build xerces-c from source.
option(DISSCO_XERCES_FETCH_SOURCE
    "On Windows, build xerces-c from upstream source when no local install is found."
    ON)

if(NOT XercesC_FOUND AND WIN32 AND DISSCO_XERCES_FETCH_SOURCE)
    # Pinned to 3.2.5 — the latest in the 3.2.x series the project
    # requires. SHA verified against the archive. Bump deliberately.
    set(_xerces_url "https://archive.apache.org/dist/xerces/c/3/sources/xerces-c-3.2.5.tar.gz")
    set(_xerces_sha "545cfcce6c4e755207bd1f27e319241e50e37c0c27250f11cda116018f1ef0f5")

    # xerces-c's CMakeLists pulls in BUILD_TESTING, etc.; keep its build
    # narrow and quiet so we don't pollute our targets/test output.
    set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
    set(BUILD_TESTING     OFF CACHE BOOL "" FORCE)
    set(xerces-c_BUILD_SAMPLES OFF CACHE BOOL "" FORCE)
    set(xerces-c_BUILD_TESTS   OFF CACHE BOOL "" FORCE)

    include(FetchContent)
    FetchContent_Declare(xerces_c
        URL      "${_xerces_url}"
        URL_HASH "SHA256=${_xerces_sha}"
    )
    FetchContent_MakeAvailable(xerces_c)

    # xerces-c's CMakeLists defines a target literally named `xerces-c`
    # (lowercase, hyphenated). Alias it so consumers can write the
    # conventional XercesC::XercesC.
    if(TARGET xerces-c AND NOT TARGET XercesC::XercesC)
        add_library(XercesC::XercesC ALIAS xerces-c)
    endif()

    # Headers live in two places: source tree (manual headers) and build
    # tree (generated config.h, version header). Expose both via the
    # target's interface — xerces-c's CMakeLists already does this, but
    # belt-and-suspenders for non-target consumers.
    set(XercesC_INCLUDE_DIR
        "${xerces_c_SOURCE_DIR}/src;${xerces_c_BINARY_DIR}/src"
        CACHE PATH "" FORCE)
    # Set XercesC_LIBRARY to the target name; CMake resolves it at link time.
    set(XercesC_LIBRARY xerces-c CACHE STRING "" FORCE)
    set(XercesC_FOUND TRUE)

    # Locate the built DLL — needed for install() so it ships alongside
    # LASSIE.exe / CMOD.exe. The path uses a generator expression because
    # the DLL doesn't exist yet at configure time.
    set(XERCESC_DLL "$<TARGET_FILE:xerces-c>" CACHE STRING "" FORCE)

    message(STATUS "FindXercesC: FetchContent built xerces-c from ${_xerces_url}")
endif()

# Fill in derived outputs.
if(XercesC_FOUND)
    set(XercesC_LIBRARIES "${XercesC_LIBRARY}")
    if(NOT XercesC_VERSION)
        # XercesC_INCLUDE_DIR is a list when FetchContent was used; the
        # first entry (source tree) is where the version header lives.
        list(GET XercesC_INCLUDE_DIR 0 _first_inc)
        _dissco_xerces_extract_version("${_first_inc}" XercesC_VERSION)
    endif()
endif()

mark_as_advanced(XercesC_INCLUDE_DIR XercesC_LIBRARY XERCESC_DLL)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(XercesC
    REQUIRED_VARS XercesC_LIBRARY XercesC_INCLUDE_DIR
    VERSION_VAR XercesC_VERSION
)
