// ============================================================
// C++20 Concepts
// ============================================================
// Concepts are named boolean predicates on template parameters.
// They constrain templates, improve error messages, and enable overloading.

#include <concepts>
#include <iostream>
#include <string>
#include <vector>
#include <ranges>
#include <numeric>

// ---- Defining concepts ------------------------------------------------------
// A concept is a constexpr bool expression on types.

// Simple type-trait concept
template<typename T>
concept Integral = std::is_integral_v<T>;

// Compound concept using &&, ||, !
template<typename T>
concept SignedIntegral = Integral<T> && std::is_signed_v<T>;

// Requires expression: check syntax validity without evaluating
template<typename T>
concept Printable = requires(T v) {
    { std::cout << v } -> std::same_as<std::ostream&>;  // expression must be valid with given return type
};

// Compound requires: multiple expressions must all be valid
template<typename T>
concept Container = requires(T c) {
    typename T::value_type;          // associated type must exist
    typename T::iterator;
    { c.begin() } -> std::same_as<typename T::iterator>;
    { c.end() }   -> std::same_as<typename T::iterator>;
    { c.size() }  -> std::convertible_to<size_t>;
    { c.empty() } -> std::same_as<bool>;
};

// ---- Using concepts ---------------------------------------------------------

// Shorthand: `Integral auto` in place of `auto`
Integral auto square(Integral auto n) { return n * n; }

// Requires clause: explicit constraint
template<typename T>
    requires SignedIntegral<T>
T abs_val(T n) { return n < 0 ? -n : n; }

// Alternatively, put the constraint directly on the template parameter
template<Container C>
auto containerSum(const C& c) {
    return std::accumulate(c.begin(), c.end(), typename C::value_type{});
}

// ---- Standard library concepts (from <concepts>) ----------------------------
// std::same_as<T, U>           : T and U are the same type
// std::convertible_to<From, To>: From is implicitly convertible to To
// std::derived_from<D, B>      : D is publicly derived from B
// std::invocable<F, Args...>   : F is callable with Args
// std::predicate<F, Args...>   : F is callable and returns bool
// std::equality_comparable<T>  : T has operator==
// std::totally_ordered<T>      : T has all comparison operators
// std::copyable<T>             : T is copyable
// std::regular<T>              : T is copyable + equality-comparable (value type)

template<std::invocable<int> F>
void applyToFive(F f) { std::cout << f(5) << "\n"; }

// ---- Concept-based overloading ----------------------------------------------
// The most constrained matching concept wins (no ambiguity).

template<std::integral T>
void describe(T) { std::cout << "integral\n"; }

template<std::floating_point T>
void describe(T) { std::cout << "floating point\n"; }

// Fallback for anything else
template<typename T>
    requires (!std::integral<T> && !std::floating_point<T>)
void describe(T) { std::cout << "other\n"; }

// ---- Subsumption ------------------------------------------------------------
// A more constrained concept subsumes a less constrained one.
// The compiler picks the most constrained overload.

template<std::regular T>
void process(T) { std::cout << "regular\n"; }  // less constrained

template<std::integral T>
void process(T) { std::cout << "integral\n"; } // more constrained — wins for int

// ---- Concepts and auto (abbreviated function templates) ----------------------
// `auto` in parameter position is sugar for an unconstrained template.
// `Concept auto` constrains it.

void printIfPrintable(Printable auto v) {
    std::cout << v << "\n";
}

// Lambdas can use concept-constrained auto too
auto sumAll = [](Container auto& c) {
    return containerSum(c);
};

// ---- requires in if constexpr -----------------------------------------------

template<typename T>
std::string stringify(T val) {
    if constexpr (requires { std::to_string(val); }) {
        return std::to_string(val);
    } else if constexpr (requires { val.to_string(); }) {
        return val.to_string();
    } else {
        return "(unstringable)";
    }
}

int main() {
    std::cout << "=== basic concepts ===\n";
    std::cout << square(7) << "\n";       // 49
    std::cout << abs_val(-5) << "\n";     // 5
    // abs_val(3.14);  // compile error: 3.14 is not SignedIntegral

    std::cout << "=== container concept ===\n";
    std::vector<int> v = {1, 2, 3, 4};
    std::cout << containerSum(v) << "\n"; // 10

    std::cout << "=== std concepts ===\n";
    applyToFive([](int x) { return x * x; });  // 25

    std::cout << "=== overloading ===\n";
    describe(42);       // integral
    describe(3.14);     // floating point
    describe("hello");  // other

    std::cout << "=== subsumption ===\n";
    process(42);         // integral (more constrained)
    process(std::string("hi")); // regular

    std::cout << "=== abbreviated templates ===\n";
    printIfPrintable(99);
    printIfPrintable("world");
    std::cout << sumAll(v) << "\n";

    std::cout << "=== requires in if constexpr ===\n";
    std::cout << stringify(42) << "\n";
    std::cout << stringify(3.14) << "\n";
    std::cout << stringify(std::vector<int>{}) << "\n";  // unstringable
}
