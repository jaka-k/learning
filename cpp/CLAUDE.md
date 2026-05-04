# C++ Learning Project

## Instructions

This folder contains files for learning modern C++ in depth. When adding to or expanding this project, follow these guidelines:

- Create subdirectories by topic (e.g., `memory/`, `templates/`, `classes/`, `stl/`, `concurrency/`, `modern/`, `cmake/`)
- In each subdir, create `.cpp` files that serve the purpose of learning C++ in and out
- Do a little bit of the basics, but **mostly focus on advanced stuff**
- Add a lot of inline comments explaining specific APIs and patterns
- Add a `cmake/` folder explaining CMake concepts
- If a topic is too large for inline comments, add a `.md` file explaining it
- Files should be runnable examples with `main()` functions where possible
- Target C++20 unless a feature is specific to an earlier or later standard

## Project Structure

```
cpp/
├── CLAUDE.md                  ← this file
├── memory/                    ← smart pointers, move semantics, RAII, memory model
├── templates/                 ← function/class templates, variadic, SFINAE, concepts
├── classes/                   ← rule of five, inheritance, virtual dispatch, CRTP
├── stl/                       ← containers, algorithms, iterators, C++20 ranges
├── concurrency/               ← threads, atomics, async/futures, memory ordering
├── modern/                    ← lambdas, type system, structured bindings, coroutines
└── cmake/                     ← CMake build system explained
```

## C++-specific focus areas

- The **rule of 0/3/5**: when to write (or suppress) special member functions
- **Move semantics**: lvalue vs rvalue references, `std::move` vs `std::forward`
- **Templates**: SFINAE, `if constexpr`, C++20 concepts, variadic packs, fold expressions
- **RAII**: every resource is owned by an object; destructors guarantee cleanup
- **Smart pointers**: `unique_ptr` (exclusive), `shared_ptr` (shared), `weak_ptr` (non-owning)
- **`const` correctness**: `const` on variables, pointers, references, and member functions
- **Undefined behavior**: what it is, how to avoid it, the rules the compiler assumes
- **Memory model**: relaxed vs acquire/release vs seq_cst atomics
- **C++20 features**: concepts, ranges, coroutines, `std::format`, `std::span`, modules
