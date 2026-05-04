// ============================================================
// Smart Pointers
// ============================================================
// Raw owning pointers (T*) are error-prone: manual delete, double-free, leaks.
// Smart pointers encode ownership in the type system and clean up automatically.

#include <memory>
#include <iostream>
#include <vector>
#include <cstdio>

// ---- unique_ptr: exclusive ownership ----------------------------------------
// One owner at a time. Non-copyable, movable. Zero overhead over raw pointer.
// Destructs the object when it goes out of scope (or is reset/moved-from).

struct Resource {
    int id;
    explicit Resource(int id) : id(id) { std::cout << "Resource " << id << " created\n"; }
    ~Resource() { std::cout << "Resource " << id << " destroyed\n"; }
    void use() const { std::cout << "Using resource " << id << "\n"; }
};

void uniquePtrBasics() {
    // make_unique is preferred over `new` — exception safe, no raw pointer
    auto r1 = std::make_unique<Resource>(1);
    r1->use();

    // Transfer ownership: r1 is null after this
    auto r2 = std::move(r1);
    // r1.get() == nullptr now; r2 owns the resource

    // unique_ptr for arrays: uses delete[] automatically
    auto arr = std::make_unique<int[]>(5);
    arr[0] = 42;
    // Both arr and r2 destroyed here; Resource 1 printed after
}

// Custom deleter — useful for C-style resources (FILE*, SDL_Window*, etc.)
struct FileDeleter {
    void operator()(FILE* f) const {
        if (f) { std::fclose(f); std::cout << "File closed\n"; }
    }
};

void customDeleter() {
    std::unique_ptr<FILE, FileDeleter> fp(std::fopen("/dev/null", "w"));
    if (fp) std::fputs("hello\n", fp.get());
    // FileDeleter::operator() called at end of scope
}

// Lambda as deleter — type is captured with decltype
void lambdaDeleter() {
    auto del = [](int* p) { std::cout << "deleting " << *p << "\n"; delete p; };
    std::unique_ptr<int, decltype(del)> p(new int(99), del);
}

// ---- shared_ptr: shared ownership -------------------------------------------
// Reference-counted. Object lives as long as any shared_ptr points to it.
// Control block: ref count + weak count + deleter/allocator. Two pointer indirections.

void sharedPtrBasics() {
    auto s1 = std::make_shared<Resource>(2);
    std::cout << "use_count=" << s1.use_count() << "\n"; // 1

    {
        auto s2 = s1;   // copy: increments ref count
        auto s3 = s1;
        std::cout << "use_count=" << s1.use_count() << "\n"; // 3
    }
    // s2, s3 destroyed → ref count back to 1
    std::cout << "use_count=" << s1.use_count() << "\n"; // 1
}
// Resource 2 destroyed when s1 goes out of scope

// NEVER construct two shared_ptrs from the same raw pointer:
//   shared_ptr<T> a(raw), b(raw);  // two control blocks → double-free!

// ---- weak_ptr: non-owning observer ------------------------------------------
// Observes a shared_ptr without extending lifetime. Must lock() to access.
// Essential for breaking reference cycles (parent↔child).

struct Node {
    int val;
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;   // weak to break cycle; shared would cause a leak
    explicit Node(int v) : val(v) {}
    ~Node() { std::cout << "Node " << val << " destroyed\n"; }
};

void weakPtrCycleBreaker() {
    auto a = std::make_shared<Node>(1);
    auto b = std::make_shared<Node>(2);
    a->next = b;
    b->prev = a;   // weak_ptr: no cycle, both nodes get destroyed at scope end

    if (auto locked = b->prev.lock()) {  // lock() returns shared_ptr or nullptr
        std::cout << "prev val=" << locked->val << "\n";
    }
}

// ---- enable_shared_from_this ------------------------------------------------
// Allows an object to produce a shared_ptr to itself safely.
// Inherit from enable_shared_from_this<T> and call shared_from_this().
// ONLY valid after the object is already managed by a shared_ptr.

struct Widget : std::enable_shared_from_this<Widget> {
    int id;
    explicit Widget(int id) : id(id) {}

    std::shared_ptr<Widget> clone() {
        return shared_from_this();  // safe: reuses the existing control block
        // NOT `return std::shared_ptr<Widget>(this)` — that creates a new control block
    }
};

void enableSharedFromThisExample() {
    auto w = std::make_shared<Widget>(42);
    auto w2 = w->clone();
    std::cout << "same? " << (w.get() == w2.get()) << "\n"; // 1
    std::cout << "use_count=" << w.use_count() << "\n";      // 2
}

// ---- Passing smart pointers to functions ------------------------------------
// Guideline (from the C++ Core Guidelines):
//   - T* or T&        — non-owning access, caller guarantees lifetime
//   - unique_ptr<T>   — sink (takes ownership)
//   - unique_ptr<T>&  — reseat (function may change what the ptr points to)
//   - shared_ptr<T>   — shared ownership transfer
//   - shared_ptr<T>&  — may reseat; prefer T* for simple observation

void observe(const Resource& r) { r.use(); }  // preferred for non-owning access

void sink(std::unique_ptr<Resource> owned) {
    owned->use();
}  // Resource destroyed here

void passingConventions() {
    auto r = std::make_unique<Resource>(3);
    observe(*r);           // raw dereference — no ownership transfer
    sink(std::move(r));    // transfer ownership; r is null after this
}

int main() {
    std::cout << "=== unique_ptr ===\n";     uniquePtrBasics();
    std::cout << "=== custom deleter ===\n"; customDeleter();
    std::cout << "=== lambda deleter ===\n"; lambdaDeleter();
    std::cout << "=== shared_ptr ===\n";     sharedPtrBasics();
    std::cout << "=== weak_ptr ===\n";       weakPtrCycleBreaker();
    std::cout << "=== shared_from_this ===\n"; enableSharedFromThisExample();
    std::cout << "=== passing conventions ===\n"; passingConventions();
}
