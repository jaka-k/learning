// ============================================================
// Move Semantics
// ============================================================
// Before C++11, returning or passing large objects caused deep copies.
// Move semantics transfer ownership of resources rather than copying them.

#include <iostream>
#include <string>
#include <vector>
#include <utility>    // std::move, std::forward
#include <algorithm>

// ---- lvalue vs rvalue -------------------------------------------------------
// lvalue: has an address, persists beyond the expression — named variables
// rvalue: temporary, no persistent address — literals, return values, moved-from
// rvalue reference (T&&): binds to temporaries; signals "you can steal from me"

void lvalueRvalueBasics() {
    int x = 5;          // x is lvalue
    int& lref = x;      // lvalue reference: must bind to lvalue
    int&& rref = 42;    // rvalue reference: binds to temporary

    // std::move is just a cast to T&&; it does NOT move anything by itself.
    // It signals that the caller is done with x and the resource may be stolen.
    int&& rref2 = std::move(x);
    // x is still valid, but in an unspecified state after an actual move
    (void)lref; (void)rref; (void)rref2;
}

// ---- A class with explicit copy and move ------------------------------------

class Buffer {
public:
    int* data = nullptr;
    size_t size = 0;

    explicit Buffer(size_t n) : data(new int[n]()), size(n) {
        std::cout << "construct n=" << n << "\n";
    }

    // Copy constructor: allocate new storage and copy bytes
    Buffer(const Buffer& o) : data(new int[o.size]), size(o.size) {
        std::copy(o.data, o.data + size, data);
        std::cout << "copy n=" << size << "\n";
    }

    // Move constructor: steal the pointer, leave other in a valid empty state
    // noexcept: required for std::vector to use moves during reallocation
    Buffer(Buffer&& o) noexcept : data(o.data), size(o.size) {
        o.data = nullptr;
        o.size = 0;
        std::cout << "move n=" << size << "\n";
    }

    Buffer& operator=(const Buffer& o) {
        if (this == &o) return *this;
        delete[] data;
        data = new int[o.size];
        size = o.size;
        std::copy(o.data, o.data + size, data);
        std::cout << "copy-assign\n";
        return *this;
    }

    Buffer& operator=(Buffer&& o) noexcept {
        if (this == &o) return *this;
        delete[] data;
        data = o.data; size = o.size;
        o.data = nullptr; o.size = 0;
        std::cout << "move-assign\n";
        return *this;
    }

    ~Buffer() { delete[] data; std::cout << "~Buffer n=" << size << "\n"; }
};

void moveExample() {
    Buffer b1(10);
    Buffer b2 = std::move(b1);    // move constructor: b1.data is now nullptr
    Buffer b3(5);
    b3 = std::move(b2);           // move assignment: b2.data is now nullptr
}

// ---- Return Value Optimization (RVO / NRVO) ---------------------------------
// The compiler elides the copy/move when constructing a return value.
// NRVO (Named RVO): for named locals returned along a single path.
// Mandatory copy elision (C++17): guaranteed when returning a prvalue directly.

Buffer makeBuffer(size_t n) {
    Buffer tmp(n);    // NRVO: tmp is constructed in-place in the caller's storage
    return tmp;       // no copy or move emitted when NRVO fires
}

// ---- std::forward and perfect forwarding ------------------------------------
// T&& in a template is a "forwarding reference" — not a plain rvalue reference.
// It deduces to T& when called with an lvalue, T&& when called with an rvalue.
// std::forward<T>(x) preserves the original value category of x.

void process(int& x)  { std::cout << "lvalue process: " << x << "\n"; }
void process(int&& x) { std::cout << "rvalue process: " << x << "\n"; }

template<typename T>
void wrapper(T&& arg) {
    // Without std::forward: arg is always lvalue here (it has a name!)
    // With std::forward: passes as-was — lvalue stays lvalue, rvalue stays rvalue
    process(std::forward<T>(arg));
}

// Variadic perfect forwarding: emplace-style construction
template<typename T, typename... Args>
T* construct(Args&&... args) {
    return new T(std::forward<Args>(args)...);
}

// ---- Move-only types --------------------------------------------------------
// unique_ptr, thread, ofstream etc. are move-only: copying is deleted.
// vector uses moves (not copies) during reallocation when moves are noexcept.

void moveOnlyAndVector() {
    std::vector<Buffer> buffers;
    buffers.reserve(3);

    Buffer b(4);
    buffers.push_back(std::move(b));   // move into vector; b is empty
    buffers.emplace_back(8);           // construct directly in place — no move at all

    // Moving out of a vector element leaves it in a valid but unspecified state
    Buffer stolen = std::move(buffers[0]);
    std::cout << "stolen n=" << stolen.size << "\n";
}

// ---- noexcept on move operations --------------------------------------------
// std::vector checks is_nothrow_move_constructible<T> at compile time.
// If the move can throw, vector falls back to copies during reallocation to
// maintain the strong exception guarantee.  Always mark moves noexcept.

int main() {
    std::cout << "=== lvalue/rvalue ===\n"; lvalueRvalueBasics();
    std::cout << "=== move ===\n";          moveExample();
    std::cout << "=== RVO ===\n";           { auto b = makeBuffer(3); (void)b; }
    std::cout << "=== perfect forwarding ===\n";
    int n = 5;
    wrapper(n);     // lvalue → process(int&)
    wrapper(10);    // rvalue → process(int&&)
    std::cout << "=== move-only / vector ===\n"; moveOnlyAndVector();
    std::cout << "=== construct ===\n";
    auto* s = construct<std::string>(5, 'x');
    std::cout << *s << "\n";
    delete s;
}
