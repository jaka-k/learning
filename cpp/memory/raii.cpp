// ============================================================
// RAII — Resource Acquisition Is Initialization
// ============================================================
// Every resource is wrapped in an object.
// Constructor acquires, destructor releases — automatically, even through exceptions.

#include <iostream>
#include <fstream>
#include <mutex>
#include <stdexcept>
#include <memory>
#include <utility>    // std::exchange

// ---- Basic RAII wrapper -----------------------------------------------------

class FileHandle {
public:
    explicit FileHandle(const char* path, const char* mode) {
        f_ = std::fopen(path, mode);
        if (!f_) throw std::runtime_error("cannot open file");
    }
    ~FileHandle() { if (f_) std::fclose(f_); }

    // Non-copyable: two copies → double fclose
    FileHandle(const FileHandle&) = delete;
    FileHandle& operator=(const FileHandle&) = delete;

    // Movable: transfer ownership
    FileHandle(FileHandle&& o) noexcept : f_(std::exchange(o.f_, nullptr)) {}
    FileHandle& operator=(FileHandle&& o) noexcept {
        if (this != &o) { if (f_) std::fclose(f_); f_ = std::exchange(o.f_, nullptr); }
        return *this;
    }

    std::FILE* get() const { return f_; }
    explicit operator bool() const { return f_ != nullptr; }

private:
    std::FILE* f_ = nullptr;
};

// ---- Scope guard — run cleanup on exit from a scope -------------------------
// Useful for ad-hoc cleanup that doesn't justify a dedicated class.

template<typename F>
class ScopeGuard {
public:
    explicit ScopeGuard(F&& fn) : fn_(std::move(fn)), active_(true) {}
    ~ScopeGuard() { if (active_) fn_(); }

    // Call dismiss() to cancel cleanup (e.g., after a successful commit)
    void dismiss() noexcept { active_ = false; }

    ScopeGuard(const ScopeGuard&) = delete;
    ScopeGuard& operator=(const ScopeGuard&) = delete;

private:
    F fn_;
    bool active_;
};

template<typename F>
ScopeGuard<F> makeScopeGuard(F&& fn) { return ScopeGuard<F>(std::forward<F>(fn)); }

void scopeGuardExample() {
    std::cout << "begin\n";
    auto guard = makeScopeGuard([] { std::cout << "cleanup on exit\n"; });
    std::cout << "doing work\n";
    // "cleanup on exit" printed when guard goes out of scope
}

void scopeGuardWithDismiss() {
    bool committed = false;
    auto rollback = makeScopeGuard([&] {
        if (!committed) std::cout << "rolling back transaction\n";
    });

    // ... do work ...
    committed = true;
    rollback.dismiss();   // work succeeded: cancel rollback
    std::cout << "committed\n";
}

// ---- RAII for mutex locking -------------------------------------------------
// std::lock_guard and std::unique_lock are built-in RAII mutex wrappers.

std::mutex g_mutex;
int g_counter = 0;

void increment() {
    std::lock_guard<std::mutex> lock(g_mutex);  // locked here
    ++g_counter;
}  // unlocked here, even if an exception is thrown

// unique_lock is more flexible: deferred lock, early unlock, condition variables
void conditionalLock() {
    std::unique_lock<std::mutex> lock(g_mutex, std::defer_lock);
    // ... do something without the lock ...
    lock.lock();
    ++g_counter;
    lock.unlock();  // optional: unlocked automatically in destructor too
}

// ---- Exception safety and RAII ----------------------------------------------
// RAII gives the strong exception guarantee: either the operation succeeds
// or the program state is unchanged (resources are always cleaned up).

void mayThrow(bool doThrow) {
    auto r1 = std::make_unique<int>(1);
    auto r2 = std::make_unique<int>(2);
    if (doThrow) throw std::runtime_error("oops");
    // If we throw, r1 and r2 are still freed — no leak
}

void exceptionSafety() {
    try { mayThrow(true); }
    catch (const std::exception& e) {
        std::cout << "caught: " << e.what() << " (no leak)\n";
    }
}

// ---- std::exchange — a handy RAII helper ------------------------------------
// Assigns new_val to obj and returns the old value atomically (in a single step).
// Used in move constructors to steal and nullify in one call.

void exchangeExample() {
    int* raw = new int(42);
    int* stolen = std::exchange(raw, nullptr);   // raw=nullptr, stolen=old value
    std::cout << "stolen=" << *stolen << ", raw is " << (raw ? "valid" : "null") << "\n";
    delete stolen;
}

int main() {
    std::cout << "=== FileHandle ===\n";
    try {
        FileHandle f("/dev/null", "w");
        std::cout << "file open: " << (bool)f << "\n";
    } catch (const std::exception& e) { std::cout << e.what() << "\n"; }

    std::cout << "=== scope guard ===\n";     scopeGuardExample();
    std::cout << "=== dismiss ===\n";         scopeGuardWithDismiss();
    std::cout << "=== mutex RAII ===\n";      increment(); conditionalLock();
    std::cout << "counter=" << g_counter << "\n";
    std::cout << "=== exception safety ===\n"; exceptionSafety();
    std::cout << "=== exchange ===\n";        exchangeExample();
}
