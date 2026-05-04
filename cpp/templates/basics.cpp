// ============================================================
// Templates — Basics to Advanced
// ============================================================
// Templates generate code at compile time for each set of arguments used.
// Zero-cost abstraction: no runtime overhead, but compile time increases.

#include <iostream>
#include <string>
#include <vector>
#include <type_traits>
#include <algorithm>

// ---- Function templates -----------------------------------------------------

template<typename T>
T max2(T a, T b) { return a < b ? b : a; }

// Explicit instantiation (rare — usually implicit):
// template int max2<int>(int, int);

// Multiple type parameters
template<typename T, typename U>
auto add(T a, U b) -> decltype(a + b) { return a + b; }  // C++11 trailing return
// C++14: just `auto add(T a, U b) { return a + b; }` — deduced return type

// Template with non-type parameter
template<int N, typename T>
T power(T base) {
    if constexpr (N == 0) return T{1};          // if constexpr: compile-time branch
    else if constexpr (N % 2 == 0) {
        auto half = power<N/2>(base);
        return half * half;
    } else {
        return base * power<N-1>(base);
    }
}

// ---- Class templates ---------------------------------------------------------

template<typename T, size_t Capacity>
class FixedVector {
public:
    void push_back(const T& v) {
        if (size_ >= Capacity) throw std::out_of_range("full");
        data_[size_++] = v;
    }
    T& operator[](size_t i) { return data_[i]; }
    size_t size() const { return size_; }

private:
    T data_[Capacity]{};
    size_t size_ = 0;
};

// ---- Template specialization ------------------------------------------------
// Full specialization: provide a completely different implementation for one type.

template<typename T>
struct TypeName { static const char* get() { return "unknown"; } };

template<> struct TypeName<int>    { static const char* get() { return "int"; } };
template<> struct TypeName<double> { static const char* get() { return "double"; } };
template<> struct TypeName<char*>  { static const char* get() { return "char*"; } };

// Partial specialization: specialize on a pattern (only for class templates)
template<typename T>
struct TypeName<T*> { static const char* get() { return "pointer"; } };

template<typename T>
struct TypeName<std::vector<T>> { static const char* get() { return "vector<T>"; } };

// ---- SFINAE (Substitution Failure Is Not An Error) --------------------------
// When template argument substitution fails, the overload is silently removed
// rather than causing a hard error. Enables overload selection based on traits.

// C++11 style: std::enable_if
template<typename T, typename = std::enable_if_t<std::is_integral_v<T>>>
void printInt(T v) { std::cout << "integral: " << v << "\n"; }

template<typename T, typename = std::enable_if_t<std::is_floating_point_v<T>>>
void printFloat(T v) { std::cout << "float: " << v << "\n"; }

// C++17 style: if constexpr — often cleaner than SFINAE
template<typename T>
void printAny(T v) {
    if constexpr (std::is_integral_v<T>)        std::cout << "integral: " << v << "\n";
    else if constexpr (std::is_floating_point_v<T>) std::cout << "float: " << v << "\n";
    else                                         std::cout << "other\n";
}

// ---- Type traits ------------------------------------------------------------
// <type_traits> provides predicates and transformations at compile time.

template<typename T>
void describeType() {
    std::cout << "is_const=" << std::is_const_v<T>
              << " is_pointer=" << std::is_pointer_v<T>
              << " is_class=" << std::is_class_v<T>
              << " is_trivially_copyable=" << std::is_trivially_copyable_v<T>
              << "\n";
}

// std::decay<T>: removes const/ref/array/function decays (like what auto does)
// std::remove_reference<T>::type: strips & or &&
// std::conditional<cond, A, B>::type: ternary for types

template<typename T>
using Decay = std::decay_t<T>;   // alias template for brevity

// ---- Template template parameters -------------------------------------------
// A parameter that is itself a template

template<template<typename> class Container, typename T>
Container<T> makeContainerOf(T val, int n) {
    Container<T> c;
    for (int i = 0; i < n; ++i) c.push_back(val);
    return c;
}

int main() {
    std::cout << "=== function template ===\n";
    std::cout << max2(3, 7) << "\n";           // T=int deduced
    std::cout << max2(3.0, 7.0) << "\n";       // T=double deduced
    std::cout << add(1, 2.5) << "\n";          // T=int, U=double

    std::cout << "=== non-type template ===\n";
    std::cout << power<10>(2) << "\n";         // 2^10 = 1024, computed at compile time

    std::cout << "=== class template ===\n";
    FixedVector<int, 4> fv;
    fv.push_back(1); fv.push_back(2);
    std::cout << fv[0] << " " << fv[1] << "\n";

    std::cout << "=== specialization ===\n";
    std::cout << TypeName<int>::get() << "\n";          // int
    std::cout << TypeName<double>::get() << "\n";       // double
    std::cout << TypeName<float*>::get() << "\n";       // pointer
    std::cout << TypeName<std::vector<int>>::get() << "\n"; // vector<T>

    std::cout << "=== SFINAE / if constexpr ===\n";
    printInt(42);
    printFloat(3.14);
    printAny(42);
    printAny(3.14f);
    printAny(std::string("hi"));

    std::cout << "=== type traits ===\n";
    describeType<const int*>();

    std::cout << "=== template template ===\n";
    auto v = makeContainerOf<std::vector>(0, 3);
    std::cout << "size=" << v.size() << "\n";
}
