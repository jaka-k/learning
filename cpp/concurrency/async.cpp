// ============================================================
// Async, Futures, and Promises
// ============================================================
// Higher-level concurrency tools built on top of threads.
// future<T> represents a value that will be available later.

#include <future>
#include <thread>
#include <iostream>
#include <vector>
#include <chrono>
#include <numeric>
#include <stdexcept>

// ---- std::async — simplest high-level async --------------------------------
// Launches a callable (in a new thread or deferred/lazy) and returns a future.
// std::launch::async  : run in a new thread immediately
// std::launch::deferred: run lazily in the calling thread when .get() is called
// default (both|async): implementation-defined — don't rely on it

int expensiveComputation(int n) {
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    return n * n;
}

void asyncBasics() {
    // Forces a new thread:
    auto f = std::async(std::launch::async, expensiveComputation, 7);

    std::cout << "doing other work while computing...\n";

    int result = f.get();   // blocks until ready, then returns the value
    std::cout << "result=" << result << "\n";  // 49

    // Exception propagation: exceptions thrown in the async task are
    // rethrown when you call .get()
    auto bad = std::async(std::launch::async, []() -> int {
        throw std::runtime_error("async failure");
        return 0;
    });
    try { bad.get(); } catch (const std::exception& e) { std::cout << e.what() << "\n"; }
}

// ---- future and promise — manual plumbing -----------------------------------
// promise<T> is the write end; future<T> is the read end.
// One promise per future (single-producer, single-consumer).

void futurePromiseExample() {
    std::promise<int> prom;
    std::future<int> fut = prom.get_future();

    std::thread producer([&prom] {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        prom.set_value(42);    // fulfill the promise
        // prom.set_exception(std::make_exception_ptr(...));  // or propagate error
    });

    std::cout << "waiting for value...\n";
    std::cout << "got " << fut.get() << "\n";  // blocks, then prints 42
    producer.join();
}

// ---- packaged_task — wrap a callable in a future ----------------------------
// packaged_task<R(Args...)> wraps a function so you can get a future from it,
// then invoke it on any thread.

void packagedTaskExample() {
    std::packaged_task<int(int, int)> task([](int a, int b) { return a + b; });
    std::future<int> result = task.get_future();

    std::thread t(std::move(task), 3, 4);  // execute the task on a thread
    std::cout << "sum=" << result.get() << "\n";  // 7
    t.join();

    // packaged_task is move-only; after moving into the thread, it's empty.
}

// ---- shared_future — multiple consumers ------------------------------------
// shared_future allows multiple threads to wait on the same result.

void sharedFutureExample() {
    std::promise<int> prom;
    std::shared_future<int> sf = prom.get_future().share();

    auto reader = [&sf](int id) {
        std::cout << "reader " << id << " got " << sf.get() << "\n";
    };

    std::thread t1(reader, 1), t2(reader, 2);
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
    prom.set_value(100);
    t1.join(); t2.join();
}

// ---- Parallel reduce using async --------------------------------------------

long long parallelSum(const std::vector<int>& v) {
    if (v.size() <= 1000) {
        return std::accumulate(v.begin(), v.end(), 0LL);
    }
    auto mid = v.begin() + v.size() / 2;
    auto right = std::async(std::launch::async, [mid, &v] {
        return std::accumulate(mid, v.end(), 0LL);
    });
    long long left = std::accumulate(v.begin(), mid, 0LL);
    return left + right.get();
}

void parallelSumExample() {
    std::vector<int> v(10000, 1);
    std::cout << "parallel sum=" << parallelSum(v) << "\n";  // 10000
}

// ---- Future status polling --------------------------------------------------
// wait_for returns future_status: ready, timeout, or deferred.

void statusPolling() {
    auto f = std::async(std::launch::async, [] {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        return 99;
    });

    while (f.wait_for(std::chrono::milliseconds(10)) != std::future_status::ready) {
        std::cout << "not ready yet...\n";
    }
    std::cout << "ready: " << f.get() << "\n";
}

// ---- std::latch and std::barrier (C++20) ------------------------------------
// latch: count-down-to-zero synchronization (one-shot).
// barrier: cyclic rendezvous point for a fixed number of threads.
//
// #include <latch>
// std::latch done(num_threads);
// // in each thread: done.count_down(); done.wait();
//
// #include <barrier>
// std::barrier sync(num_threads, []{ /* completion fn */ });
// // in each thread: sync.arrive_and_wait();

int main() {
    std::cout << "=== async basics ===\n";       asyncBasics();
    std::cout << "=== promise/future ===\n";     futurePromiseExample();
    std::cout << "=== packaged_task ===\n";      packagedTaskExample();
    std::cout << "=== shared_future ===\n";      sharedFutureExample();
    std::cout << "=== parallel sum ===\n";       parallelSumExample();
    std::cout << "=== status polling ===\n";     statusPolling();
}
