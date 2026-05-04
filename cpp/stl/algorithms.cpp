// ============================================================
// STL Algorithms
// ============================================================
// Algorithms operate on iterator ranges [begin, end).
// They work on any container with compatible iterators.
// C++17 adds parallel execution policies; C++20 adds range-based overloads.

#include <algorithm>
#include <numeric>
#include <functional>
#include <iostream>
#include <vector>
#include <string>
#include <iterator>

// ---- Sorting ----------------------------------------------------------------

void sortingAlgos() {
    std::vector<int> v = {5, 3, 1, 4, 2};

    std::sort(v.begin(), v.end());          // O(n log n), not stable
    std::sort(v.begin(), v.end(), std::greater<int>{}); // descending

    std::vector<std::pair<int,std::string>> pairs = {{2,"b"}, {1,"a"}, {2,"a"}};
    std::stable_sort(pairs.begin(), pairs.end()); // preserves relative order of equals

    // partial_sort: sort only the first k elements
    std::vector<int> u = {5, 3, 8, 1, 9, 2};
    std::partial_sort(u.begin(), u.begin() + 3, u.end());  // smallest 3 sorted
    std::cout << "partial: " << u[0] << " " << u[1] << " " << u[2] << "\n"; // 1 2 3

    // nth_element: O(n) — element at position n is what it would be if sorted;
    // elements before it are ≤ it, after are ≥ it (no other guarantees)
    std::vector<int> w = {5, 3, 8, 1, 9, 2, 7};
    std::nth_element(w.begin(), w.begin() + 3, w.end());
    std::cout << "nth=3: " << w[3] << "\n";  // 4th smallest
}

// ---- Searching --------------------------------------------------------------

void searchingAlgos() {
    std::vector<int> v = {1, 2, 3, 4, 5, 6, 7};

    // Binary search (requires sorted range)
    bool found = std::binary_search(v.begin(), v.end(), 4);
    auto lb = std::lower_bound(v.begin(), v.end(), 4); // first >= 4
    auto ub = std::upper_bound(v.begin(), v.end(), 4); // first > 4
    auto [lo, hi] = std::equal_range(v.begin(), v.end(), 4); // [lb, ub)
    std::cout << "found=" << found << " lb=" << *lb << "\n";

    // Linear search
    auto it = std::find(v.begin(), v.end(), 3);
    auto it2 = std::find_if(v.begin(), v.end(), [](int x) { return x > 4; });
    std::cout << "find_if>4: " << *it2 << "\n";  // 5

    // min/max
    auto [mn, mx] = std::minmax_element(v.begin(), v.end());
    std::cout << "min=" << *mn << " max=" << *mx << "\n";
}

// ---- Transforming and generating --------------------------------------------

void transformAlgos() {
    std::vector<int> v = {1, 2, 3, 4, 5};
    std::vector<int> out(v.size());

    // transform: apply function element-wise
    std::transform(v.begin(), v.end(), out.begin(), [](int x) { return x * x; });
    std::cout << "squares: "; for (int x : out) std::cout << x << " "; std::cout << "\n";

    // transform with two ranges (binary operation)
    std::vector<int> a = {1, 2, 3}, b = {10, 20, 30}, c(3);
    std::transform(a.begin(), a.end(), b.begin(), c.begin(), std::plus<int>{});
    std::cout << "plus: "; for (int x : c) std::cout << x << " "; std::cout << "\n";

    // generate / fill
    std::vector<int> seq(5);
    int n = 0;
    std::generate(seq.begin(), seq.end(), [&n] { return n++ * 2; });
    std::fill(v.begin() + 2, v.end(), 0);  // fill subrange with value

    // iota: fill with incrementing sequence
    std::iota(seq.begin(), seq.end(), 1);  // {1, 2, 3, 4, 5}
}

// ---- Reduction and accumulation ---------------------------------------------

void reductionAlgos() {
    std::vector<int> v = {1, 2, 3, 4, 5};

    int sum = std::accumulate(v.begin(), v.end(), 0);              // 15
    int product = std::accumulate(v.begin(), v.end(), 1, std::multiplies<int>{}); // 120
    std::cout << "sum=" << sum << " product=" << product << "\n";

    // reduce (C++17): like accumulate but order is unspecified — parallelizable
    // int rsum = std::reduce(v.begin(), v.end());  // needs <numeric>

    // inner_product: dot product
    std::vector<int> w = {1, 2, 3, 4, 5};
    int dot = std::inner_product(v.begin(), v.end(), w.begin(), 0);
    std::cout << "dot=" << dot << "\n";  // 55

    // partial_sum: running total
    std::vector<int> prefix(v.size());
    std::partial_sum(v.begin(), v.end(), prefix.begin());
    std::cout << "prefix: "; for (int x : prefix) std::cout << x << " "; std::cout << "\n";
}

// ---- Partitioning and filtering ---------------------------------------------

void partitionAlgos() {
    std::vector<int> v = {1, 2, 3, 4, 5, 6, 7, 8};

    // partition: rearrange so pred(x) elements come first
    auto mid = std::partition(v.begin(), v.end(), [](int x) { return x % 2 == 0; });
    std::cout << "evens first: "; for (int x : v) std::cout << x << " "; std::cout << "\n";
    std::cout << "odd start index=" << std::distance(v.begin(), mid) << "\n";

    // stable_partition: preserves relative order within each group
    std::vector<int> u = {1, 2, 3, 4, 5, 6};
    std::stable_partition(u.begin(), u.end(), [](int x) { return x % 2 == 0; });

    // remove_if + erase idiom (erase-remove)
    std::vector<int> r = {1, 2, 3, 4, 5, 6};
    r.erase(std::remove_if(r.begin(), r.end(), [](int x) { return x % 2 == 0; }), r.end());
    std::cout << "odd only: "; for (int x : r) std::cout << x << " "; std::cout << "\n";
}

// ---- Set operations (on sorted ranges) --------------------------------------

void setOps() {
    std::vector<int> a = {1, 2, 3, 4, 5};
    std::vector<int> b = {3, 4, 5, 6, 7};
    std::vector<int> out;

    std::set_intersection(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(out));
    std::cout << "intersection: "; for (int x : out) std::cout << x << " "; std::cout << "\n";

    out.clear();
    std::set_union(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(out));
    std::cout << "union: "; for (int x : out) std::cout << x << " "; std::cout << "\n";

    out.clear();
    std::set_difference(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(out));
    std::cout << "a-b: "; for (int x : out) std::cout << x << " "; std::cout << "\n";
}

// ---- Permutations and rotations ---------------------------------------------

void permAndRotate() {
    std::vector<int> v = {1, 2, 3};
    do {
        for (int x : v) std::cout << x; std::cout << " ";
    } while (std::next_permutation(v.begin(), v.end()));
    std::cout << "\n";

    std::vector<int> r = {1, 2, 3, 4, 5};
    std::rotate(r.begin(), r.begin() + 2, r.end()); // {3,4,5,1,2}
    for (int x : r) std::cout << x << " "; std::cout << "\n";
}

int main() {
    std::cout << "=== sorting ===\n";     sortingAlgos();
    std::cout << "=== searching ===\n";   searchingAlgos();
    std::cout << "=== transform ===\n";   transformAlgos();
    std::cout << "=== reduction ===\n";   reductionAlgos();
    std::cout << "=== partition ===\n";   partitionAlgos();
    std::cout << "=== set ops ===\n";     setOps();
    std::cout << "=== permute ===\n";     permAndRotate();
}
