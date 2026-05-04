// ============================================================
// Rule of 0 / 3 / 5
// ============================================================
// Rule of 0: prefer types with no user-defined special members.
//            Let the compiler generate them (using member RAII types).
// Rule of 3: if you define destructor, copy ctor, or copy assign,
//            define all three (pre-C++11).
// Rule of 5: if you define any of the above, also define move ctor
//            and move assign for efficiency (C++11+).

#include <iostream>
#include <string>
#include <algorithm>
#include <utility>

// ---- Rule of 0 — the best rule -----------------------------------------------
// Use std::string, std::vector, std::unique_ptr as members.
// The compiler-generated specials do the right thing automatically.

struct Good {
    std::string name;
    std::vector<int> data;
    // No user-defined specials needed — compiler generates correct ones
};

// ---- Rule of 5 example — owning raw pointer ---------------------------------
// Only needed when you can't use a smart pointer (e.g., custom allocator,
// interop with C, educational purposes).

class Buffer {
public:
    // Constructor
    explicit Buffer(size_t n, int fill = 0)
        : data_(new int[n]()), size_(n) {
        std::fill_n(data_, n, fill);
        std::cout << "ctor n=" << n << "\n";
    }

    // Destructor — must free the resource
    ~Buffer() {
        delete[] data_;
        std::cout << "dtor n=" << size_ << "\n";
    }

    // Copy constructor — deep copy
    Buffer(const Buffer& o)
        : data_(new int[o.size_]), size_(o.size_) {
        std::copy(o.data_, o.data_ + size_, data_);
        std::cout << "copy ctor n=" << size_ << "\n";
    }

    // Copy assignment — handle self-assignment, release old resource
    Buffer& operator=(const Buffer& o) {
        if (this == &o) return *this;
        int* tmp = new int[o.size_];
        std::copy(o.data_, o.data_ + o.size_, tmp);
        delete[] data_;          // release AFTER new allocation succeeds
        data_ = tmp;
        size_ = o.size_;
        std::cout << "copy-assign n=" << size_ << "\n";
        return *this;
    }

    // Move constructor — steal the resource, leave source in a valid empty state
    Buffer(Buffer&& o) noexcept
        : data_(std::exchange(o.data_, nullptr))
        , size_(std::exchange(o.size_, 0)) {
        std::cout << "move ctor n=" << size_ << "\n";
    }

    // Move assignment — steal, release own old resource
    Buffer& operator=(Buffer&& o) noexcept {
        if (this == &o) return *this;
        delete[] data_;
        data_ = std::exchange(o.data_, nullptr);
        size_ = std::exchange(o.size_, 0);
        std::cout << "move-assign n=" << size_ << "\n";
        return *this;
    }

    size_t size() const { return size_; }
    int& operator[](size_t i) { return data_[i]; }
    const int& operator[](size_t i) const { return data_[i]; }

private:
    int* data_;
    size_t size_;
};

// ---- = delete and = default -------------------------------------------------
// `= delete` explicitly removes a function; calling it is a compile error.
// `= default` asks the compiler to generate the usual implementation.

class NonCopyable {
public:
    NonCopyable() = default;
    NonCopyable(const NonCopyable&) = delete;             // no copy
    NonCopyable& operator=(const NonCopyable&) = delete;
    NonCopyable(NonCopyable&&) = default;                  // movable
    NonCopyable& operator=(NonCopyable&&) = default;
};

class Singleton {
public:
    static Singleton& instance() {
        static Singleton s;
        return s;
    }
    Singleton(const Singleton&) = delete;
    Singleton& operator=(const Singleton&) = delete;

private:
    Singleton() = default;
};

// ---- Compiler-generated specials: when are they suppressed? ------------------
// User declares destructor             → copy ctor/assign are deprecated-generated
//                                        move ctor/assign are NOT generated
// User declares copy ctor or assign    → move ctor/assign are NOT generated
// User declares move ctor or assign    → copy ctor/assign are deleted
// → If you define any, define all five (or explicitly = default/= delete them)

// ---- Copy-and-swap idiom — gives strong exception guarantee -----------------
// Build a copy first; only modify *this after the copy succeeds.

class SafeBuffer {
public:
    explicit SafeBuffer(size_t n) : data_(new int[n]()), size_(n) {}
    ~SafeBuffer() { delete[] data_; }

    SafeBuffer(const SafeBuffer& o) : data_(new int[o.size_]), size_(o.size_) {
        std::copy(o.data_, o.data_ + size_, data_);
    }

    // Unified assignment using copy-and-swap: takes by value (copy or move),
    // then swaps. Handles both copy-assign and move-assign.
    SafeBuffer& operator=(SafeBuffer o) {   // `o` is a copy (or a moved value)
        swap(o);
        return *this;
    }

    SafeBuffer(SafeBuffer&& o) noexcept
        : data_(std::exchange(o.data_, nullptr)), size_(std::exchange(o.size_, 0)) {}

    void swap(SafeBuffer& o) noexcept {
        std::swap(data_, o.data_);
        std::swap(size_, o.size_);
    }

private:
    int* data_;
    size_t size_;
};

int main() {
    std::cout << "=== rule of 5 ===\n";
    Buffer b1(3, 7);
    Buffer b2 = b1;            // copy ctor
    Buffer b3(5);
    b3 = b1;                   // copy-assign
    Buffer b4 = std::move(b1); // move ctor; b1 is empty
    Buffer b5(2);
    b5 = std::move(b4);        // move-assign; b4 is empty

    std::cout << "=== rule of 0 ===\n";
    Good g1{"Alice", {1, 2, 3}};
    Good g2 = g1;    // works automatically
    Good g3 = std::move(g1); // works automatically

    std::cout << "=== non-copyable ===\n";
    NonCopyable nc1;
    NonCopyable nc2 = std::move(nc1);  // movable
    // NonCopyable nc3 = nc2;          // compile error: copy deleted

    std::cout << "=== copy-and-swap ===\n";
    SafeBuffer sb1(4), sb2(2);
    sb1 = sb2;             // copy-assign via copy-and-swap
    sb1 = std::move(sb2);  // move-assign via copy-and-swap
}
