// ============================================================
// Modern C++ Type System
// ============================================================
// C++11/14/17/20 features that make the type system expressive and safe.

#include <iostream>
#include <optional>
#include <variant>
#include <any>
#include <string>
#include <typeinfo>
#include <type_traits>
#include <cassert>

// ---- auto and decltype -------------------------------------------------------
// auto: deduces type from the initializer (like val in Swift/Kotlin)
// decltype(expr): gives the type of an expression without evaluating it

void autoAndDecltype() {
    auto x = 42;            // int
    auto d = 3.14;          // double
    auto s = std::string("hi");  // std::string

    // auto strips top-level const and ref; use auto& or const auto& to preserve
    std::vector<int> v = {1, 2, 3};
    auto& ref = v[0];       // int&
    const auto& cref = v;   // const vector<int>&

    // decltype: exact type including references and const
    int y = 5;
    decltype(y) z = y;      // int
    decltype((y)) w = y;    // int& — (y) is an lvalue expression

    // decltype(auto): deduce with reference/const preservation
    auto get = [&v]() -> decltype(auto) { return v[0]; };  // returns int&
    get() = 99;
    std::cout << v[0] << "\n";  // 99
}

// ---- std::optional<T> -------------------------------------------------------
// Represents a value that may or may not be present.
// Replaces: sentinel values (-1, nullptr), bool+out-param pairs, exceptions for "no value".

std::optional<int> parseInt(const std::string& s) {
    try { return std::stoi(s); }
    catch (...) { return std::nullopt; }
}

void optionalExample() {
    auto v1 = parseInt("42");
    auto v2 = parseInt("oops");

    if (v1) std::cout << "parsed: " << *v1 << "\n";
    std::cout << v2.value_or(-1) << "\n";  // default if empty

    // Monadic operations (C++23): optional chaining
    // auto result = parseInt("42").transform([](int x) { return x * 2; });

    // Avoid exception overhead: optional is a value type on the stack
    // Creating nullopt never allocates; *opt on empty is UB (use value() for checked access)
    // opt.value() throws std::bad_optional_access if empty
}

// ---- std::variant<Ts...> ----------------------------------------------------
// A type-safe union: holds exactly one of its alternative types at a time.
// No undefined behavior (unlike raw union). Replaces tagged unions.

using Shape = std::variant<struct Circle, struct Rect>;
struct Circle { double r; };
struct Rect   { double w, h; };

double area(const Shape& s) {
    return std::visit([](auto&& shape) -> double {
        using T = std::decay_t<decltype(shape)>;
        if constexpr (std::is_same_v<T, Circle>) return 3.14159 * shape.r * shape.r;
        else if constexpr (std::is_same_v<T, Rect>) return shape.w * shape.h;
    }, s);
}

void variantExample() {
    Shape s = Circle{5.0};
    std::cout << "area=" << area(s) << "\n";  // 78.5

    s = Rect{3.0, 4.0};
    std::cout << "area=" << area(s) << "\n";  // 12.0

    // Access by type (throws std::bad_variant_access if wrong type)
    std::cout << "width=" << std::get<Rect>(s).w << "\n";

    // get_if: returns pointer or nullptr (no exception)
    if (auto* r = std::get_if<Rect>(&s)) {
        std::cout << "is Rect: " << r->w << "x" << r->h << "\n";
    }

    // index(): returns the 0-based index of the active type
    std::cout << "index=" << s.index() << "\n";  // 1 (Rect is second in variant)
}

// ---- Overloaded visitor pattern for variant ---------------------------------
// Utility to compose multiple lambdas into a single visitor.

template<typename... Ts>
struct overloaded : Ts... { using Ts::operator()...; };

template<typename... Ts>
overloaded(Ts...) -> overloaded<Ts...>;  // deduction guide

void overloadedVisitor() {
    using Val = std::variant<int, double, std::string>;
    Val v = "hello";

    std::visit(overloaded{
        [](int i)               { std::cout << "int: " << i << "\n"; },
        [](double d)            { std::cout << "double: " << d << "\n"; },
        [](const std::string& s){ std::cout << "string: " << s << "\n"; },
    }, v);
}

// ---- std::any ---------------------------------------------------------------
// Type-erased container for any copyable type.
// More flexible than variant but with runtime overhead and no type safety.

void anyExample() {
    std::any a = 42;
    std::cout << std::any_cast<int>(a) << "\n";  // 42

    a = std::string("hello");
    std::cout << std::any_cast<std::string>(a) << "\n";

    // Wrong type throws std::bad_any_cast
    try { std::any_cast<int>(a); }
    catch (const std::bad_any_cast& e) { std::cout << e.what() << "\n"; }

    // Check before casting
    if (a.type() == typeid(std::string)) {
        std::cout << "is string\n";
    }

    a.reset();   // empty any
    std::cout << "has_value=" << a.has_value() << "\n";
}

// ---- std::string_view (C++17) -----------------------------------------------
// Non-owning, read-only view of a contiguous char sequence.
// Avoids copies when you just need to read a string.
// WARNING: must not outlive the underlying string.

#include <string_view>

void processName(std::string_view name) {
    std::cout << "name[0..2]=" << name.substr(0, 3) << "\n";
    std::cout << "starts_with A: " << name.starts_with('A') << "\n";
}

void stringViewExample() {
    std::string s = "Alice";
    processName(s);           // no copy; view into s
    processName("Bob");       // view into string literal
    processName(s.substr(0, 3));  // DANGER if processName stored the view beyond this expr
}

// ---- if constexpr and compile-time branching --------------------------------

template<typename T>
void printTyped(T val) {
    if constexpr (std::is_integral_v<T>)
        std::cout << "int: " << val << " hex=" << std::hex << val << std::dec << "\n";
    else if constexpr (std::is_floating_point_v<T>)
        std::cout << "float: " << val << "\n";
    else
        std::cout << "other: " << val << "\n";
    // Each branch is only compiled for matching types — dead branches aren't checked
}

int main() {
    std::cout << "=== auto/decltype ===\n"; autoAndDecltype();
    std::cout << "=== optional ===\n";      optionalExample();
    std::cout << "=== variant ===\n";       variantExample();
    std::cout << "=== overloaded ===\n";    overloadedVisitor();
    std::cout << "=== any ===\n";           anyExample();
    std::cout << "=== string_view ===\n";   stringViewExample();
    std::cout << "=== if constexpr ===\n";
    printTyped(42);
    printTyped(3.14);
    printTyped(std::string("hi"));
}
