cmake_minimum_required(VERSION 3.20)
project(cpp_learning VERSION 0.1.0 LANGUAGES CXX)

# ---- Global settings --------------------------------------------------------
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)   # disable GNU extensions; enforce standard C++

# Export compile_commands.json for clang-based tooling (clangd, clang-tidy)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ---- Helper: add a self-contained learning executable -----------------------
# Usage: add_example(NAME memory/smart_pointers)
function(add_example NAME)
    # Derive a clean target name from the path (replace / with _)
    string(REPLACE "/" "_" target "${NAME}")
    add_executable(${target} ${NAME}.cpp)
    target_compile_options(${target} PRIVATE
        -Wall -Wextra -Wpedantic
        $<$<CONFIG:Debug>:-g -O0 -fsanitize=address,undefined>
        $<$<CONFIG:Release>:-O2>
    )
    # Link sanitizers when in Debug mode
    target_link_options(${target} PRIVATE
        $<$<CONFIG:Debug>:-fsanitize=address,undefined>
    )
endfunction()

# ---- Register all learning examples -----------------------------------------
add_example(NAME memory/smart_pointers)
add_example(NAME memory/move_semantics)
add_example(NAME memory/raii)

add_example(NAME templates/basics)
add_example(NAME templates/variadic)
add_example(NAME templates/concepts)

add_example(NAME classes/rule_of_five)
add_example(NAME classes/inheritance)
add_example(NAME classes/crtp)

add_example(NAME stl/containers)
add_example(NAME stl/algorithms)
add_example(NAME stl/ranges)

add_example(NAME concurrency/threads)
add_example(NAME concurrency/atomics)
add_example(NAME concurrency/async)

add_example(NAME modern/lambdas)
add_example(NAME modern/type_system)
add_example(NAME modern/structured_bindings)

# ---- CTest integration -------------------------------------------------------
# Each example doubles as a smoke test: if it exits 0, it passes.
enable_testing()

foreach(name
    memory_smart_pointers memory_move_semantics memory_raii
    templates_basics templates_variadic templates_concepts
    classes_rule_of_five classes_inheritance classes_crtp
    stl_containers stl_algorithms stl_ranges
    concurrency_threads concurrency_atomics concurrency_async
    modern_lambdas modern_type_system modern_structured_bindings
)
    add_test(NAME ${name} COMMAND ${name})
    set_tests_properties(${name} PROPERTIES TIMEOUT 10)
endforeach()

# ---- Usage ------------------------------------------------------------------
# Configure:  cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
# Build all:  cmake --build build -j$(nproc)
# Run tests:  ctest --test-dir build --output-on-failure
# One file:   cmake --build build --target memory_smart_pointers
#             ./build/memory_smart_pointers
