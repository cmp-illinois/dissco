Building on Windows 
=================
(WIP, not yet building without some hacking)

What is marked as not yet supported (denoted by ❌ and understood as referring to the entire line/paragraph) will be supported, soon.

We intend to offer static binaries at some point.

Preliminary Requirements
--------------------------

The following are *necessary* to compile CMOD and LASS:

- git
- Visual Studio 2022,
- A C/C++ compiler (like MSVC `cl`),
- cmake >= 3.25,
<!-- - muparser >= 2.X -->

To compile with LASSIE, the following is *necessary*:

- (🟡) Qt >= 6.8

`libsndfile` and `xerces-c` are **not** prerequisites on Windows — `cmake-modules/FindSndFile.cmake` downloads the official libsndfile prebuilt binary release on first configure, and `cmake-modules/FindXercesC.cmake` builds xerces-c 3.2.5 from source via FetchContent. The first configure therefore takes a few minutes longer than a typical "all dependencies present" build; subsequent configures hit the FetchContent cache.

Note: There are definitely other ways to compile DISSCO on Windows (e.g. providing libsndfile / xerces-c via vcpkg or a system install — both Find modules will detect a pre-existing install via CONFIG mode and skip the download/build), but the FetchContent path is the one tested in CI.

Installing requirements and recommendations:
--------------------------------------------

<!-- *For all methods*, it's worth keeping in mind that we statically link `muparser`, meaning you don't need to worry about installing it. Please report any issues related to muparser during compilation. -->

You should [install Visual Studio 2022](https://visualstudio.microsoft.com/) from Microsoft and, in the process, install the Microsoft Visual C/C++ compilers and CMake. You will need to run all the commands given hereafter in **Developer PowerShell**, which you can access either within a VS project or through the PowerShell script provided at `C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1`.

If you didn't install CMake during the VS install or don't want to install through VS, you can get an installer [from CMake directly](https://cmake.org/download/).

Installing DISSCO
-----------------
Just `git clone` this repo; explicitly:

    git clone https://github.com/cmp-illinois/DISSCO-2.2.0.git

Building
--------

From the project's root directory, run:

    cmake -S . -B build -G Ninja
    cmake --build build

The first configure pulls in libsndfile (download) and xerces-c (download + build), so it takes longer than the macOS / Linux equivalents. After that, incremental builds are normal.

By running this command in `build`, one generates a so-called *out-of-source* (OOS) build. The alternative, an in-source build, is heavily discouraged (including [by the CMake maintainers](https://cmake.org/cmake/help/book/mastering-cmake/chapter/Getting%20Started.html#directory-structure)), and the root `CMakeLists.txt` reflects this distaste. The rationale is that OOS builds minimize clutter and collect all build files in one directory, whereas in-source builds put build files virtually everywhere. (This is bad.)

From `build`, you can clean `build` using `cmake --build . --target clean`. Alternatively, you can do `rmdir /s build` from outside of `build`.

Building a release installer
----------------------------
The release pipeline produces an NSIS installer `.exe` that bundles `LASSIE.exe`, `CMOD.exe`, the Qt runtime, and writes registry entries for the `.dissco` file association.

Extra requirement: **NSIS** (Nullsoft Scriptable Install System).

    choco install nsis

Then from Developer PowerShell at the project root:

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
    cmake --build build --parallel
    cmake --build build --target package

This produces `build/DISSCO-<version>-Windows.exe`. Under the hood:

- CPack's NSIS generator wraps the install tree into a single-file installer.
- `windeployqt` runs at install time against the installed `LASSIE.exe` and copies the Qt DLLs + platform plugins next to it.
- The installer writes `HKLM\Software\Classes\.dissco` registry entries so `.dissco` files open LASSIE on double-click immediately after install (system-wide). If the file-association branch (`claude/sad-hermann-4b5591`) is merged, LASSIE.exe will additionally self-register per-user (HKCU) on first launch — both layers describe the same ProgID.
- The installer also installs a Start Menu shortcut and an optional desktop shortcut.

The icon (`packaging/windows/LASSIE.ico`) is a placeholder; regenerate it from updated artwork via `packaging/windows/make-ico.sh`.

**Code signing:** unsigned `.exe` installers trigger Windows SmartScreen warnings on download. Production releases should be signed with an EV or OV code-signing certificate. The GitHub Actions release workflow has a clean place to wire signtool in once the certificate is provisioned.