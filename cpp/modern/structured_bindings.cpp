// ============================================================
// Structured Bindings and Modern Initialization
// ============================================================
// Structured bindings (C++17) let you unpack tuples, pairs, arrays,
// and structs into named variables in a single declaration.

#include <iostream>
#include <tuple>
#include <map>
#include <array>
#include <string>
#include <utility>

// ---- Structured bindings with pair ------------------------------------------

void pairBinding() {
    std::pair<int, std::string> p = {42, "hello"};
    auto& [id, name] = p;       // id and name are references to p.first and p.second
    name = "world";              // modifies p.second
    std::cout << p.second << "\n";  // world

    // Useful with insert() return value
    std::map<std::string, int> m;
    auto [it, inserted] = m.insert({"key", 1});
    std::cout << "inserted=" << inserted << " val=" << it->second << "\n";
}

// ---- Structured bindings with tuple -----------------------------------------

std::tuple<int, double, std::string> getRecord() {
    return {1, 3.14, "pi"};
}

void tupleBinding() {
    auto [id, val, label] = getRecord();
    std::cout << id << " " << val << " " << label << "\n";

    // Ignore elements with _ (by convention; not a language feature)
    auto [a, b, c] = getRecord();
    (void)b;  // suppress unused warning

    // With const ref (avoid copying large tuples)
    const auto& [x, y, z] = getRecord();
    std::cout << x << "\n";
}

// ---- Structured bindings with array -----------------------------------------

void arrayBinding() {
    int arr[3] = {10, 20, 30};
    auto [a, b, c] = arr;   // copies each element
    std::cout << a << " " << b << " " << c << "\n";

    std::array<int, 4> sa = {1, 2, 3, 4};
    auto& [w, x, y, z] = sa;   // references to array elements
    w = 99;
    std::cout << sa[0] << "\n";  // 99
}

// ---- Structured bindings with structs ---------------------------------------
// Works automatically for aggregates (no user-provided constructors).

struct Point3D { double x, y, z; };

void structBinding() {
    Point3D p{1.0, 2.0, 3.0};
    auto [x, y, z] = p;    // copies
    auto& [rx, ry, rz] = p; // references
    rx = 99.0;
    std::cout << p.x << "\n";  // 99
}

// ---- Range-for with structured bindings -------------------------------------

void rangeForBinding() {
    std::map<std::string, int> scores = {{"Alice", 95}, {"Bob", 87}, {"Carol", 92}};

    for (const auto& [name, score] : scores) {
        std::cout << name << ": " << score << "\n";
    }

    // With index using enumerate workaround
    int i = 0;
    for (const auto& [name, score] : scores) {
        std::cout << i++ << ": " << name << "\n";
    }
}

// ---- Custom structured binding support --------------------------------------
// Implement get<N>, tuple_size, and tuple_element specializations.

struct NamedPoint {
    double x, y;
    std::string label;
};

// Specialize tuple traits for NamedPoint
namespace std {
    template<> struct tuple_size<NamedPoint> : std::integral_constant<size_t, 3> {};
    template<> struct tuple_element<0, NamedPoint> { using type = double; };
    template<> struct tuple_element<1, NamedPoint> { using type = double; };
    template<> struct tuple_element<2, NamedPoint> { using type = std::string; };
}

template<size_t I>
auto& get(NamedPoint& p) {
    if constexpr (I == 0) return p.x;
    else if constexpr (I == 1) return p.y;
    else return p.label;
}

template<size_t I>
const auto& get(const NamedPoint& p) {
    if constexpr (I == 0) return p.x;
    else if constexpr (I == 1) return p.y;
    else return p.label;
}

void customBinding() {
    NamedPoint np{1.0, 2.0, "origin"};
    auto& [x, y, label] = np;
    label = "renamed";
    std::cout << np.label << "\n";  // renamed
}

// ---- if/switch with initializer (C++17) -------------------------------------
// Like `for (init; cond)` but for if and switch.

void ifWithInitializer() {
    std::map<std::string, int> m = {{"a", 1}};

    // Old: two statements; `it` leaks into enclosing scope
    // auto it = m.find("a"); if (it != m.end()) { ... }

    // New: `it` scoped to the if block
    if (auto it = m.find("a"); it != m.end()) {
        std::cout << "found: " << it->second << "\n";
    }

    // switch with init
    switch (auto v = m.count("a"); v) {
        case 0: std::cout << "absent\n"; break;
        case 1: std::cout << "present\n"; break;
    }
}

// ---- std::tie for pre-C++17 unpacking and comparison ------------------------

void tieExample() {
    int a, b;
    std::tie(a, b) = std::make_pair(3, 7);   // C++11 way
    std::cout << a << " " << b << "\n";

    // Ignoring elements
    std::tie(a, std::ignore) = std::make_pair(10, 99);
    std::cout << "a=" << a << "\n";

    // Lexicographic comparison using tie
    struct Version { int major, minor, patch; };
    auto cmp = [](const Version& a, const Version& b) {
        return std::tie(a.major, a.minor, a.patch) <
               std::tie(b.major, b.minor, b.patch);
    };
    Version v1{1, 2, 3}, v2{1, 3, 0};
    std::cout << "v1 < v2: " << cmp(v1, v2) << "\n";  // 1
}

int main() {
    std::cout << "=== pair binding ===\n";    pairBinding();
    std::cout << "=== tuple binding ===\n";   tupleBinding();
    std::cout << "=== array binding ===\n";   arrayBinding();
    std::cout << "=== struct binding ===\n";  structBinding();
    std::cout << "=== range-for ===\n";       rangeForBinding();
    std::cout << "=== custom binding ===\n";  customBinding();
    std::cout << "=== if init ===\n";         ifWithInitializer();
    std::cout << "=== tie ===\n";             tieExample();
}
