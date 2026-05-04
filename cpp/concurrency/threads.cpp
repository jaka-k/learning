// ============================================================
// Threads, Mutexes, and Synchronization
// ============================================================

#include <thread>
#include <mutex>
#include <shared_mutex>
#include <condition_variable>
#include <iostream>
#include <vector>
#include <numeric>
#include <string>

// ---- std::thread basics -----------------------------------------------------
// A thread must be either joined or detached before destruction,
// otherwise std::terminate() is called.

void threadBasics() {
    std::thread t1([] { std::cout << "hello from thread\n"; });
    t1.join();   // wait for t1 to finish

    // Pass arguments by value (copies or moves)
    int x = 42;
    std::thread t2([](int n) { std::cout << "n=" << n << "\n"; }, x);
    t2.join();

    // Pass by reference: wrap in std::ref to avoid unintentional copy
    std::string msg = "mutable";
    std::thread t3([](std::string& s) { s += " modified"; }, std::ref(msg));
    t3.join();
    std::cout << msg << "\n";  // "mutable modified"
}

// ---- std::jthread (C++20) ---------------------------------------------------
// Like std::thread but automatically joins on destruction (RAII).
// Also supports cooperative cancellation via std::stop_token.

void jthreadExample() {
    std::jthread worker([](std::stop_token st) {
        for (int i = 0; !st.stop_requested(); ++i) {
            if (i >= 5) break;
            std::cout << "working " << i << "\n";
        }
        std::cout << "worker done\n";
    });
    // jthread's destructor calls request_stop() then join()
}

// ---- mutex and lock_guard ---------------------------------------------------
// A mutex protects a shared resource. lock_guard is a scoped RAII wrapper.

std::mutex g_mtx;
int g_counter = 0;

void increment(int n) {
    for (int i = 0; i < n; ++i) {
        std::lock_guard<std::mutex> lock(g_mtx);  // locked; unlocked at end of block
        ++g_counter;
    }
}

void mutexExample() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 4; ++i)
        threads.emplace_back(increment, 250);
    for (auto& t : threads) t.join();
    std::cout << "counter=" << g_counter << "\n"; // 1000
}

// ---- unique_lock — flexible locking ----------------------------------------
// Supports: deferred lock, timed lock, manual unlock, condition variables.

std::mutex g_mut2;

void uniqueLockExample() {
    std::unique_lock<std::mutex> lock(g_mut2, std::defer_lock);
    // ... do non-critical work ...
    lock.lock();
    // critical section
    lock.unlock();
    // ... more non-critical work ...
    lock.lock();
    // critical section again
}  // unlocked by destructor if still held

// ---- Avoiding deadlock ------------------------------------------------------
// Always lock multiple mutexes in the same order — OR use std::lock / scoped_lock.

std::mutex mtxA, mtxB;

void safeDualLock() {
    // scoped_lock (C++17): locks multiple mutexes atomically, deadlock-free
    std::scoped_lock lock(mtxA, mtxB);
    // Both mutexes held; both released at end of scope
}

// ---- shared_mutex — read/write lock ----------------------------------------
// Multiple readers OR one writer at a time.

std::shared_mutex g_rwmtx;
int g_data = 0;

void reader() {
    std::shared_lock lock(g_rwmtx);  // shared (read) lock — multiple allowed
    std::cout << "read: " << g_data << "\n";
}

void writer(int val) {
    std::unique_lock lock(g_rwmtx);  // exclusive (write) lock
    g_data = val;
}

// ---- condition_variable — wait for an event ---------------------------------
// Allows a thread to sleep until another thread signals it.
// ALWAYS check the condition in a loop (spurious wakeups are real).

std::mutex cvMtx;
std::condition_variable cv;
bool ready = false;
int payload = 0;

void producer() {
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
    {
        std::lock_guard lock(cvMtx);
        payload = 99;
        ready = true;
    }
    cv.notify_one();  // wake one waiting thread
}

void consumer() {
    std::unique_lock lock(cvMtx);
    // Predicate version: re-checks condition after each wakeup (handles spurious)
    cv.wait(lock, [] { return ready; });
    std::cout << "consumed payload=" << payload << "\n";
}

void condvarExample() {
    std::thread p(producer);
    std::thread c(consumer);
    p.join(); c.join();
}

// ---- thread_local storage ---------------------------------------------------
// Each thread has its own copy of a thread_local variable.

thread_local int tl_id = -1;

void threadLocalExample() {
    auto worker = [](int id) {
        tl_id = id;
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
        std::cout << "thread " << id << " sees tl_id=" << tl_id << "\n";
    };
    std::thread t1(worker, 1), t2(worker, 2);
    t1.join(); t2.join();
}

int main() {
    std::cout << "=== thread basics ===\n";   threadBasics();
    std::cout << "=== jthread ===\n";         jthreadExample();
    std::cout << "=== mutex ===\n";           mutexExample();
    std::cout << "=== shared_mutex ===\n";    writer(42); reader();
    std::cout << "=== condition_var ===\n";   condvarExample();
    std::cout << "=== thread_local ===\n";    threadLocalExample();
}
