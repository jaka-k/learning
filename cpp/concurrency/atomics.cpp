// ============================================================
// Atomics and Memory Ordering
// ============================================================
// Atomic operations are indivisible — no other thread can observe a
// partial state. They are the foundation of lock-free data structures.

#include <atomic>
#include <thread>
#include <iostream>
#include <vector>
#include <cassert>

// ---- std::atomic<T> basics --------------------------------------------------
// Supported for integral types, pointers, and trivially-copyable types (C++20).
// All operations on atomic<T> are individually atomic (not groups of ops).

void atomicBasics() {
    std::atomic<int> counter{0};

    // fetch_add returns the old value; += returns the new value
    int old = counter.fetch_add(1, std::memory_order_relaxed);
    std::cout << "old=" << old << " new=" << counter.load() << "\n"; // 0, 1

    counter.store(10);
    std::cout << counter.exchange(99) << "\n";  // returns 10, stores 99

    // compare_exchange: CAS (compare-and-swap)
    int expected = 99;
    bool swapped = counter.compare_exchange_strong(expected, 42);
    // If counter==expected: stores 42, returns true
    // If counter!=expected: sets expected=counter, returns false
    std::cout << "swapped=" << swapped << " counter=" << counter.load() << "\n";

    // compare_exchange_weak: may fail spuriously (for loops); faster on some CPUs
    expected = 42;
    while (!counter.compare_exchange_weak(expected, expected + 1))
        ;  // retry on spurious failure
    std::cout << "after CAS loop: " << counter.load() << "\n";  // 43
}

// ---- Memory orderings -------------------------------------------------------
// Memory ordering controls how operations are visible across threads.
// Weaker orderings are faster; stronger are safer.
//
// relaxed:     No synchronization, no ordering. Only atomicity is guaranteed.
//              Use for counters where exact ordering doesn't matter.
//
// acquire:     A load that synchronizes with a prior release on the same var.
//              All writes before the release are visible after this load.
//
// release:     A store that "publishes" prior writes. A matching acquire load
//              on another thread will see those writes.
//
// acq_rel:     acquire + release in one (for read-modify-write ops like fetch_add).
//
// seq_cst:     Total sequential consistency — the default. Slowest, but safest.
//              All threads observe the same global order of seq_cst operations.

// ---- Acquire/release for producer-consumer ----------------------------------
// This is the minimum synchronization needed for one-shot producer-consumer.

std::atomic<bool> g_ready{false};
int g_value = 0;  // protected by the atomic flag

void producer() {
    g_value = 42;                                   // plain write before release
    g_ready.store(true, std::memory_order_release); // "publish" g_value
}

void consumer() {
    while (!g_ready.load(std::memory_order_acquire)) // spin until published
        ;
    // acquire synchronizes with the release: g_value is guaranteed to be 42
    assert(g_value == 42);
    std::cout << "g_value=" << g_value << "\n";
}

void acquireReleaseExample() {
    std::thread p(producer);
    std::thread c(consumer);
    p.join(); c.join();
}

// ---- Spinlock using atomic_flag ----------------------------------------------
// atomic_flag is guaranteed to be lock-free on all platforms.
// Uses test_and_set (acquire) / clear (release) for minimal ordering.

class Spinlock {
    std::atomic_flag flag = ATOMIC_FLAG_INIT;
public:
    void lock()   { while (flag.test_and_set(std::memory_order_acquire)) { std::this_thread::yield(); } }
    void unlock() { flag.clear(std::memory_order_release); }
};

Spinlock sl;
int sl_counter = 0;

void spinlockWorker(int n) {
    for (int i = 0; i < n; ++i) {
        sl.lock();
        ++sl_counter;
        sl.unlock();
    }
}

void spinlockExample() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 4; ++i) threads.emplace_back(spinlockWorker, 250);
    for (auto& t : threads) t.join();
    std::cout << "sl_counter=" << sl_counter << "\n";  // 1000
}

// ---- Lock-free stack using CAS ----------------------------------------------

template<typename T>
class LockFreeStack {
    struct Node {
        T data;
        Node* next;
        Node(T d, Node* n) : data(std::move(d)), next(n) {}
    };
    std::atomic<Node*> head_{nullptr};

public:
    void push(T val) {
        Node* new_node = new Node(std::move(val), head_.load(std::memory_order_relaxed));
        // CAS loop: retry if head changed since we read it
        while (!head_.compare_exchange_weak(new_node->next, new_node,
                                            std::memory_order_release,
                                            std::memory_order_relaxed))
            ;
    }

    bool pop(T& out) {
        Node* old_head = head_.load(std::memory_order_acquire);
        while (old_head) {
            if (head_.compare_exchange_weak(old_head, old_head->next,
                                            std::memory_order_acquire,
                                            std::memory_order_relaxed)) {
                out = std::move(old_head->data);
                delete old_head;
                return true;
            }
        }
        return false;
    }

    // Note: this is not safe against ABA problem without hazard pointers
    // or epoch-based reclamation.
};

void lockFreeStackExample() {
    LockFreeStack<int> stack;
    stack.push(1); stack.push(2); stack.push(3);
    int val;
    while (stack.pop(val)) std::cout << val << " ";
    std::cout << "\n";  // 3 2 1
}

// ---- std::atomic<shared_ptr> (C++20) ----------------------------------------
// Allows thread-safe shared_ptr operations without external locks.
// Useful for lock-free read-copy-update (RCU) patterns.
//
// std::atomic<std::shared_ptr<T>> ptr;
// auto snap = ptr.load();            // atomic load of the shared_ptr
// ptr.store(std::make_shared<T>());  // atomic store

int main() {
    std::cout << "=== atomic basics ===\n";     atomicBasics();
    std::cout << "=== acquire/release ===\n";   acquireReleaseExample();
    std::cout << "=== spinlock ===\n";          spinlockExample();
    std::cout << "=== lock-free stack ===\n";   lockFreeStackExample();
}
