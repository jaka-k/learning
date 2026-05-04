// ============================================================
// STL Containers
// ============================================================
// Choosing the right container is critical for performance.
// Always measure, but know the theoretical trade-offs.

#include <iostream>
#include <vector>
#include <deque>
#include <list>
#include <forward_list>
#include <array>
#include <map>
#include <unordered_map>
#include <set>
#include <unordered_set>
#include <stack>
#include <queue>
#include <string>

// ---- vector — the default sequential container ------------------------------
// Contiguous memory → cache-friendly, O(1) random access.
// Amortised O(1) push_back (doubles capacity on resize).
// O(n) insertion/deletion in the middle.
// Prefer over all other sequences unless you have a specific reason.

void vectorFeatures() {
    std::vector<int> v = {3, 1, 4, 1, 5};

    v.reserve(20);              // pre-allocate; avoids reallocations
    v.push_back(9);
    v.emplace_back(2);          // construct in-place (avoids extra copy)

    // Accessing elements
    std::cout << v[0] << "\n";         // no bounds check
    std::cout << v.at(1) << "\n";      // bounds-checked, throws out_of_range

    // Erasing
    v.erase(v.begin() + 2);           // O(n): shifts elements left
    v.erase(v.begin(), v.begin() + 2); // erase range

    // Shrink-to-fit: release excess capacity (advisory)
    v.shrink_to_fit();

    // swap trick (pre-C++11 shrink): vector<int>().swap(v)
    // Now: v.clear(); v.shrink_to_fit();
    std::cout << "size=" << v.size() << " cap=" << v.capacity() << "\n";
}

// ---- deque — double-ended queue ---------------------------------------------
// Segmented memory: blocks of fixed size.
// O(1) push/pop at both ends. O(1) random access (with extra indirection).
// Not contiguous → slightly worse cache behavior than vector.

void dequeFeatures() {
    std::deque<int> d = {3, 4, 5};
    d.push_front(2);   // O(1) — unlike vector which would be O(n)
    d.push_front(1);
    d.push_back(6);
    for (int x : d) std::cout << x << " ";
    std::cout << "\n";
}

// ---- list — doubly linked list ----------------------------------------------
// O(1) insertion/deletion anywhere given an iterator.
// No random access (O(n) to find position).
// High memory overhead per node (two pointers) and poor cache locality.
// Use only when you have stable iterators and frequent middle insertions.

void listFeatures() {
    std::list<int> l = {1, 3, 5};
    auto it = std::next(l.begin());  // iterator to 3
    l.insert(it, 2);                 // insert 2 before 3: O(1)
    l.erase(it);                     // erase 3: O(1), iterator was stable
    l.splice(l.end(), l, l.begin()); // move front to back without realloc
    for (int x : l) std::cout << x << " ";
    std::cout << "\n";
}

// ---- std::array — fixed-size stack array ------------------------------------
// Size is part of the type. Zero overhead over C array.
// Supports all the standard container operations (iterators, size(), etc.).

void arrayFeatures() {
    std::array<int, 5> a = {1, 2, 3, 4, 5};
    std::cout << a.size() << "\n";  // always 5
    auto [first, second, rest1, rest2, last] = a;  // structured binding
    std::cout << first << " " << last << "\n";
}

// ---- map vs unordered_map ---------------------------------------------------
// map:         Red-black tree. O(log n) operations. Keys ordered.
// unordered_map: Hash table. O(1) average, O(n) worst case.
//               Keys must be hashable (default: std::hash<K>).
// Prefer unordered_map unless: you need sorted iteration, worst-case guarantees,
// or your key type has no good hash.

void mapVsUnordered() {
    std::map<std::string, int> ordered;
    ordered["banana"] = 2;
    ordered["apple"] = 5;
    ordered["cherry"] = 1;
    for (auto& [k, v] : ordered) std::cout << k << "=" << v << " "; // sorted!
    std::cout << "\n";

    std::unordered_map<std::string, int> hash_map;
    hash_map.reserve(16);      // pre-size bucket array
    hash_map.max_load_factor(0.7f);  // rehash threshold
    hash_map["z"] = 1;
    hash_map["a"] = 2;

    // insert_or_assign: insert if absent, assign if present. Returns {iter, bool}.
    auto [it, inserted] = hash_map.insert_or_assign("z", 99);
    std::cout << "z=" << it->second << " inserted=" << inserted << "\n";

    // try_emplace: insert only if key absent; doesn't construct value if key exists
    hash_map.try_emplace("w", 42);   // inserts
    hash_map.try_emplace("z", 0);    // no-op: z already exists
}

// ---- set and unordered_set --------------------------------------------------
// set: sorted unique keys (red-black tree).
// unordered_set: hashed unique keys.
// multiset/unordered_multiset: allow duplicate keys.

void setFeatures() {
    std::set<int> s = {5, 3, 1, 4, 2};
    std::cout << "min=" << *s.begin() << " max=" << *s.rbegin() << "\n";

    // lower_bound/upper_bound — O(log n) unlike linear search on a vector
    auto it = s.lower_bound(3);   // first element >= 3
    std::cout << "lower_bound(3)=" << *it << "\n";
}

// ---- Adaptors: stack, queue, priority_queue ---------------------------------
// These wrap a container (default: deque for stack/queue, vector for pq).

void adaptors() {
    std::stack<int> stk;
    stk.push(1); stk.push(2); stk.push(3);
    std::cout << "top=" << stk.top() << "\n";  // 3

    std::priority_queue<int> maxHeap;
    maxHeap.push(3); maxHeap.push(1); maxHeap.push(4); maxHeap.push(1);
    while (!maxHeap.empty()) {
        std::cout << maxHeap.top() << " ";  // 4 3 1 1
        maxHeap.pop();
    }
    std::cout << "\n";

    // Min-heap: negate values or use greater<>
    std::priority_queue<int, std::vector<int>, std::greater<int>> minHeap;
    minHeap.push(3); minHeap.push(1); minHeap.push(4);
    std::cout << "min=" << minHeap.top() << "\n";  // 1
}

int main() {
    std::cout << "=== vector ===\n";     vectorFeatures();
    std::cout << "=== deque ===\n";      dequeFeatures();
    std::cout << "=== list ===\n";       listFeatures();
    std::cout << "=== array ===\n";      arrayFeatures();
    std::cout << "=== map/unordered ===\n"; mapVsUnordered();
    std::cout << "=== set ===\n";        setFeatures();
    std::cout << "=== adaptors ===\n";   adaptors();
}
