# CMake

CMake is the de-facto build system generator for C++. It generates native build files (Makefiles, Ninja files, Visual Studio projects, Xcode projects) from a `CMakeLists.txt` description. CMake ≥ 3.15 with "modern CMake" practices (target-based) is standard.

## Core Concepts

### Targets
Everything in modern CMake revolves around **targets** — libraries or executables. Each target carries its own properties (compile flags, include paths, link dependencies). You add dependencies between targets instead of setting global variables.

```cmake
add_library(mylib STATIC src/foo.cpp src/bar.cpp)
add_executable(myapp src/main.cpp)
target_link_libraries(myapp PRIVATE mylib)
```

### `PRIVATE` / `PUBLIC` / `INTERFACE`
These control how properties propagate through the dependency graph:

| Keyword     | Visible to | Visible to dependents |
|-------------|------------|-----------------------|
| `PRIVATE`   | this target| no                    |
| `PUBLIC`    | this target| yes                   |
| `INTERFACE` | no         | yes                   |

Use `PRIVATE` by default. Use `PUBLIC` when your header files `#include` headers from a dependency. Use `INTERFACE` for header-only libraries.

### Include directories
```cmake
# OLD (global — avoid):
include_directories(include/)

# MODERN (target-scoped):
target_include_directories(mylib
    PUBLIC  include/       # consumers also get this path
    PRIVATE src/           # only this target
)
```

### Compile options and definitions
```cmake
target_compile_options(mylib PRIVATE -Wall -Wextra -Wpedantic)
target_compile_definitions(mylib PRIVATE MY_FEATURE=1)
```

### C++ standard
```cmake
target_compile_features(myapp PRIVATE cxx_std_20)
# OR globally:
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)   # disable compiler-specific extensions
```

## Common Patterns

### Out-of-source builds
Always build in a separate directory (never in the source tree):
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
```

### Build types
- `Debug`         — no optimization, debug info (`-O0 -g`)
- `Release`       — full optimization (`-O3 -DNDEBUG`)
- `RelWithDebInfo`— optimized with debug info (`-O2 -g -DNDEBUG`)
- `MinSizeRel`    — optimize for size (`-Os`)

### Finding packages
```cmake
find_package(OpenSSL REQUIRED)
target_link_libraries(myapp PRIVATE OpenSSL::SSL OpenSSL::Crypto)
```
`find_package` looks for `FindXxx.cmake` or `XxxConfig.cmake`. Modern packages ship with config files.

### FetchContent — download dependencies at configure time
```cmake
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
)
FetchContent_MakeAvailable(googletest)
target_link_libraries(myapp PRIVATE GTest::gtest_main)
```

### Installing and packaging
```cmake
install(TARGETS mylib myapp
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
install(DIRECTORY include/ DESTINATION include)
```

### Testing with CTest
```cmake
enable_testing()
add_test(NAME mytest COMMAND myapp --test)
# Or with GoogleTest:
include(GoogleTest)
gtest_discover_tests(myapp)
```

## Project Layout
```
project/
├── CMakeLists.txt        ← root (project(), find_package, subdirs)
├── CMakePresets.json     ← preset build configs (C++23)
├── src/
│   ├── CMakeLists.txt    ← defines library/executable targets
│   └── *.cpp
├── include/
│   └── project/
│       └── *.h
├── tests/
│   ├── CMakeLists.txt
│   └── *.cpp
└── third_party/          ← or use FetchContent
```

## Generator Expressions
Evaluated at build or install time (not configure time):
```cmake
# Different flags per build type:
target_compile_options(mylib PRIVATE
    $<$<CONFIG:Debug>:-O0 -g>
    $<$<CONFIG:Release>:-O3>
)

# Only for a specific compiler:
target_compile_options(mylib PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wshadow>
)
```

## Useful Variables
| Variable | Meaning |
|---|---|
| `CMAKE_SOURCE_DIR` | Root of the source tree |
| `CMAKE_BINARY_DIR` | Root of the build tree |
| `CMAKE_CURRENT_SOURCE_DIR` | Directory of the current CMakeLists.txt |
| `PROJECT_SOURCE_DIR` | Source dir of the most recent `project()` |
| `CMAKE_BUILD_TYPE` | Debug / Release / etc. |
| `BUILD_SHARED_LIBS` | If ON, `add_library` defaults to SHARED |

## Quick Reference
```bash
cmake -S . -B build                    # configure
cmake --build build                    # build
cmake --build build --target mylib     # build specific target
ctest --test-dir build                 # run tests
cmake --install build --prefix /usr/local  # install
```
