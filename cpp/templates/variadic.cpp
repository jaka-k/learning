// ============================================================
// Variadic Templates and Fold Expressions
// ============================================================
// Variadic templates accept an arbitrary number of type/value parameters.
// They are the foundation of std::tuple, std::variant, printf replacements, etc.

#include <iostream>
#include <string>
#include <tuple>
#include <utility>
#include <sstream>

// ---- Parameter pack basics --------------------------------------------------
// `typename... Ts` declares a type pack; `Ts... args` expands it.
// `sizeof...(Ts)` gives the pack size at compile time.

template<typename... Ts>
void printAll(Ts... args) {
    // Pack expansion with initializer_list trick (C++11/14):
    (void)std::initializer_list<int>{ (std::cout << args << " ", 0)... };
    std::cout << "\n";
}

// ---- Recursive unpacking (pre-C++17 style) ----------------------------------
// Base case handles zero args; recursive case peels off the first arg.

void printRecursive() {}   // base case: empty pack

template<typename T, typename... Rest>
void printRecursive(T first, Rest... rest) {
    std::cout << first;
    if constexpr (sizeof...(rest) > 0) { std::cout << ", "; printRecursive(rest...); }
    else std::cout << "\n";
}

// ---- Fold expressions (C++17) -----------------------------------------------
// A fold collapses a pack over a binary operator.
// Unary right fold: (pack op ...)
// Unary left fold:  (... op pack)
// Binary right fold: (pack op ... op init)
// Binary left fold:  (init op ... op pack)

template<typename... Ts>
auto sum(Ts... args) {
    return (args + ...);    // unary right fold: a + (b + (c + ...))
}

template<typename... Ts>
auto product(Ts... args) {
    return (args * ...);    // unary right fold
}

template<typename... Ts>
void printFold(Ts... args) {
    // Binary left fold with << : (std::cout << ... << args)
    (std::cout << ... << args);
    std::cout << "\n";
}

template<typename... Ts>
bool allTrue(Ts... args) {
    return (... && args);   // unary left fold — short-circuits
}

template<typename T, typename... Ts>
bool anyOf(T val, Ts... candidates) {
    return ((val == candidates) || ...);  // unary right fold
}

// ---- std::apply and index sequences -----------------------------------------
// index_sequence lets you expand a tuple element by element.

template<typename Tuple, size_t... Is>
void printTupleImpl(const Tuple& t, std::index_sequence<Is...>) {
    ((std::cout << (Is == 0 ? "" : ", ") << std::get<Is>(t)), ...);
    std::cout << "\n";
}

template<typename... Ts>
void printTuple(const std::tuple<Ts...>& t) {
    printTupleImpl(t, std::index_sequence_for<Ts...>{});
}

// ---- Perfect-forwarding variadic factory ------------------------------------
// std::forward<Args>(args)... expands the pack, forwarding each arg correctly.

template<typename T, typename... Args>
T make(Args&&... args) {
    return T(std::forward<Args>(args)...);
}

// ---- Collecting types: type list manipulation --------------------------------
// A type list is just a struct that holds a parameter pack.

template<typename...> struct TypeList {};

template<typename List> struct Head;
template<typename T, typename... Rest>
struct Head<TypeList<T, Rest...>> { using type = T; };

template<typename List> struct Tail;
template<typename T, typename... Rest>
struct Tail<TypeList<T, Rest...>> { using type = TypeList<Rest...>; };

template<typename List> struct Size;
template<typename... Ts>
struct Size<TypeList<Ts...>> : std::integral_constant<size_t, sizeof...(Ts)> {};

// ---- Practical: type-safe printf replacement --------------------------------

template<typename... Args>
std::string format(std::string_view fmt, Args&&... args) {
    std::ostringstream oss;
    size_t i = 0;
    auto processArg = [&](const auto& arg) {
        while (i < fmt.size()) {
            if (fmt[i] == '{' && i + 1 < fmt.size() && fmt[i+1] == '}') {
                oss << arg;
                i += 2;
                return;
            }
            oss << fmt[i++];
        }
    };
    (processArg(args), ...);  // fold over comma operator
    oss << fmt.substr(i);
    return oss.str();
}

int main() {
    std::cout << "=== pack expansion ===\n";
    printAll(1, "hello", 3.14, 'x');

    std::cout << "=== recursive ===\n";
    printRecursive(1, "two", 3.0);

    std::cout << "=== fold expressions ===\n";
    std::cout << sum(1, 2, 3, 4, 5) << "\n";    // 15
    std::cout << product(1, 2, 3, 4) << "\n";   // 24
    printFold("hello", " ", "world", "!");
    std::cout << allTrue(true, true, true) << "\n";  // 1
    std::cout << anyOf(3, 1, 2, 3, 4) << "\n";       // 1

    std::cout << "=== tuple print ===\n";
    printTuple(std::make_tuple(42, "hello", 3.14));

    std::cout << "=== make factory ===\n";
    auto s = make<std::string>(5, 'x');
    std::cout << s << "\n";   // xxxxx

    std::cout << "=== type list ===\n";
    using MyList = TypeList<int, double, char>;
    std::cout << "size=" << Size<MyList>::value << "\n";   // 3
    // Head<MyList>::type is int; Tail<MyList>::type is TypeList<double, char>

    std::cout << "=== format ===\n";
    std::cout << format("Hello {} you are {} years old", "Alice", 30) << "\n";
}
