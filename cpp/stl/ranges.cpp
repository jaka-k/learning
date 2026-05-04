// ============================================================
// C++20 Ranges
// ============================================================
// Ranges generalizes the iterator-pair interface.
// Views are lazy, composable transformations over sequences.
// Pipe syntax (|) lets you chain operations without intermediate containers.

#include <ranges>
#include <algorithm>
#include <iostream>
#include <vector>
#include <string>
#include <numeric>

namespace rv = std::views;   // shorthand

// ---- Basic range algorithms -------------------------------------------------
// std::ranges:: versions take a single range instead of begin/end pairs.
// They also support projections — a transform applied before comparison.

void rangeAlgorithms() {
    std::vector<int> v = {5, 3, 1, 4, 2};

    std::ranges::sort(v);                     // sorts in-place
    std::ranges::sort(v, std::greater<>{});   // descending

    // Projection: sort by absolute value without modifying the data
    std::vector<int> w = {-3, 1, -2, 4};
    std::ranges::sort(w, {}, [](int x) { return std::abs(x); });
    for (int x : w) std::cout << x << " "; std::cout << "\n"; // -1 -2 -3 4 or similar

    // find_if with projection
    struct Person { std::string name; int age; };
    std::vector<Person> people = {{"Alice", 30}, {"Bob", 25}, {"Carol", 35}};
    auto it = std::ranges::find_if(people, [](int age) { return age > 28; }, &Person::age);
    if (it != people.end()) std::cout << it->name << "\n";  // Alice
}

// ---- Views: lazy, composable transformations --------------------------------
// Views do not own data and do not copy.
// They are evaluated element by element only when iterated.

void basicViews() {
    std::vector<int> v = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};

    // filter: keep only elements matching a predicate
    auto evens = v | rv::filter([](int x) { return x % 2 == 0; });

    // transform: map each element through a function
    auto squares = v | rv::transform([](int x) { return x * x; });

    // Compose with |
    auto even_squares = v
        | rv::filter([](int x) { return x % 2 == 0; })
        | rv::transform([](int x) { return x * x; });

    std::cout << "even squares: ";
    for (int x : even_squares) std::cout << x << " ";
    std::cout << "\n";  // 4 16 36 64 100

    // take / drop
    auto first3 = v | rv::take(3);           // first 3 elements
    auto skip2  = v | rv::drop(2);           // skip first 2
    auto mid    = v | rv::drop(2) | rv::take(4); // elements 2..5

    // take_while / drop_while
    auto until5 = v | rv::take_while([](int x) { return x < 5; });

    std::cout << "until5: ";
    for (int x : until5) std::cout << x << " "; std::cout << "\n"; // 1 2 3 4
}

// ---- Useful views -----------------------------------------------------------

void moreViews() {
    // iota: infinite or bounded integer range
    auto first10 = rv::iota(1, 11);            // [1, 11) — 1 through 10
    auto naturals = rv::iota(0);               // infinite: 0, 1, 2, ...

    // Combine iota with take
    auto first5naturals = rv::iota(1) | rv::take(5);
    for (int x : first5naturals) std::cout << x << " "; std::cout << "\n"; // 1 2 3 4 5

    // reverse
    std::vector<int> v = {1, 2, 3, 4, 5};
    for (int x : v | rv::reverse) std::cout << x << " "; std::cout << "\n"; // 5 4 3 2 1

    // keys / values on map-like pairs
    std::vector<std::pair<std::string, int>> pairs = {{"a", 1}, {"b", 2}, {"c", 3}};
    for (auto& k : pairs | rv::keys)   std::cout << k << " "; std::cout << "\n"; // a b c
    for (auto  v : pairs | rv::values) std::cout << v << " "; std::cout << "\n"; // 1 2 3

    // enumerate (C++23 — use iota+zip for C++20)
    // for (auto [i, v] : rv::enumerate(v)) { ... }

    // zip (C++23)
    // std::vector<int> a = {1,2,3}, b = {4,5,6};
    // for (auto [x, y] : rv::zip(a, b)) { ... }
}

// ---- Materializing views into containers ------------------------------------
// Views are lazy; use ranges::to<> (C++23) or copy to materialize.

void materializing() {
    std::vector<int> v = {1, 2, 3, 4, 5, 6};

    // C++20 way: copy to vector
    auto filtered = v | rv::filter([](int x) { return x % 2 == 0; });
    std::vector<int> result(filtered.begin(), filtered.end());

    // Or: ranges::copy to back_inserter
    std::vector<int> result2;
    std::ranges::copy(v | rv::transform([](int x) { return x * 2; }),
                      std::back_inserter(result2));

    // C++23: ranges::to<vector>()
    // auto result3 = v | rv::filter(...) | std::ranges::to<std::vector>();

    std::cout << "materialized: ";
    for (int x : result) std::cout << x << " "; std::cout << "\n";
}

// ---- Range-based reduce and fold --------------------------------------------

void rangeReduction() {
    std::vector<int> v = {1, 2, 3, 4, 5};

    // Still use std::accumulate / std::reduce for aggregation
    int sum = std::accumulate(v.begin(), v.end(), 0);

    // Or with ranges::fold_left (C++23)
    // int sum = std::ranges::fold_left(v, 0, std::plus<>{});

    // Count elements matching predicate
    long n = std::ranges::count_if(v, [](int x) { return x > 2; });
    std::cout << "sum=" << sum << " count>2=" << n << "\n";
}

// ---- Custom range view ------------------------------------------------------
// A view is a range whose copy/move is O(1).
// Implement view_interface<T> for free range operations.

// Stride view (every N-th element) — already in C++23 as rv::stride
template<std::ranges::forward_range R>
auto stride_view_workaround(R&& r, int n) {
    // Simple workaround: filter using index
    std::vector<std::ranges::range_value_t<R>> result;
    int i = 0;
    for (auto& x : r) {
        if (i++ % n == 0) result.push_back(x);
    }
    return result;
}

int main() {
    std::cout << "=== range algorithms ===\n"; rangeAlgorithms();
    std::cout << "=== basic views ===\n";      basicViews();
    std::cout << "=== more views ===\n";       moreViews();
    std::cout << "=== materializing ===\n";    materializing();
    std::cout << "=== reduction ===\n";        rangeReduction();
    std::cout << "=== stride ===\n";
    std::vector<int> v = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    for (int x : stride_view_workaround(v, 3)) std::cout << x << " "; std::cout << "\n"; // 0 3 6 9
}
