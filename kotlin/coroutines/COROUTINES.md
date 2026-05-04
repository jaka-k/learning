# Kotlin Coroutines — Mental Model

## The Core Idea

A coroutine is a computation that can **suspend** itself without blocking a thread. When it suspends, the thread is freed for other work. When the awaited result is ready, the coroutine resumes (possibly on a different thread).

```
Thread A:     [coroutine 1 running] → suspend → [coroutine 2 running] → [coroutine 1 resumes]
              No blocking, no extra threads created.
```

vs threads:

```
Thread A:     [work] → blocks waiting for I/O → [resumes]   (thread occupied the whole time)
Thread B:     (idle, waiting for Thread A to free up)
```

Coroutines are **cheap**: creating 100,000 coroutines is fine. Creating 100,000 threads will crash the JVM.

---

## Suspend Functions

A `suspend` function can pause and resume. It can only be called from:
1. Another `suspend` function
2. A coroutine builder (`launch`, `async`, `runBlocking`)

```kotlin
suspend fun fetchData(): String {
    delay(1000)          // suspend point — frees the thread
    return "result"
}
```

`delay()` is NOT `Thread.sleep()`. `delay` suspends the coroutine; the thread is available for other coroutines during the wait.

---

## Coroutine Builders

| Builder        | Returns      | Blocks thread? | Use case                        |
|---------------|--------------|----------------|---------------------------------|
| `launch`      | `Job`        | No             | Fire-and-forget side effects    |
| `async`       | `Deferred<T>`| No             | Compute a value concurrently    |
| `runBlocking` | `T`          | YES            | Bridge to non-suspend code (tests, main) |

```kotlin
// launch — result not needed
val job: Job = scope.launch { doSomething() }

// async — result needed
val deferred: Deferred<Int> = scope.async { compute() }
val result = deferred.await()   // suspends until done

// Parallel decomposition
val a = async { fetchUser(1) }
val b = async { fetchUser(2) }
println("${a.await()} and ${b.await()}")  // both run concurrently
```

---

## Structured Concurrency

**Every coroutine belongs to a scope.** When a scope is cancelled, all its children are cancelled. This prevents leaks.

```
CoroutineScope
└── launch (child 1)
└── launch (child 2)
    └── async (grandchild)
```

If the scope is cancelled → child 1, child 2, and grandchild are all cancelled.
If child 2 fails (non-CancellationException) → the scope and child 1 are cancelled.

```kotlin
coroutineScope {     // suspends until all children complete (or fails with first error)
    launch { ... }
    launch { ... }
}

supervisorScope {    // children are independent — one failure doesn't affect others
    launch { ... }
    launch { ... }
}
```

---

## Dispatchers — Which Thread Runs the Coroutine?

| Dispatcher              | Thread pool                  | Use for                     |
|------------------------|------------------------------|-----------------------------|
| `Dispatchers.Default`  | CPU count threads            | CPU-bound work (compute)    |
| `Dispatchers.IO`       | Up to 64 threads             | I/O-bound (network, disk)   |
| `Dispatchers.Main`     | UI thread                    | Android / Swing UI updates  |
| `Dispatchers.Unconfined`| Starts current, then caller | Testing, special cases      |

Switch dispatcher mid-coroutine with `withContext`:
```kotlin
suspend fun loadAndProcess() {
    val raw = withContext(Dispatchers.IO) { readFile() }   // I/O thread
    val result = withContext(Dispatchers.Default) { parse(raw) }  // CPU thread
    withContext(Dispatchers.Main) { updateUi(result) }    // UI thread
}
```

---

## Job and Cancellation

Cancellation is **cooperative**: a coroutine must check `isActive` or call a suspending function that checks it.

```kotlin
val job = launch {
    repeat(1000) {
        ensureActive()   // throws CancellationException if cancelled
        delay(100)       // also a cancellation checkpoint
    }
}
delay(250)
job.cancel()   // requests cancellation
job.join()     // waits for cancellation to complete
```

`CancellationException` is NOT an error — don't catch it unless you re-throw it.

---

## Exception Handling

```kotlin
// Option 1: try/catch inside the coroutine
launch {
    try {
        riskyOp()
    } catch (e: IOException) {
        println("Handled: ${e.message}")
    }
}

// Option 2: CoroutineExceptionHandler (root coroutines only)
val handler = CoroutineExceptionHandler { _, e -> println("Caught: $e") }
CoroutineScope(Dispatchers.IO + handler).launch { throw RuntimeException("oops") }

// Option 3: async + await (exceptions propagate through await)
val deferred = async { riskyOp() }
try {
    deferred.await()
} catch (e: Exception) {
    println("Caught from deferred: $e")
}
```

---

## Flow vs Sequence vs Channel

| Feature          | `Sequence<T>`       | `Flow<T>`             | `Channel<T>`         |
|-----------------|---------------------|----------------------|----------------------|
| Execution       | Synchronous         | Asynchronous         | Asynchronous         |
| Thread-safe     | Single thread       | Safe across threads  | Safe across threads  |
| Backpressure    | Natural (pull)      | Suspend on slow consumer | Buffered or suspend |
| Hot/Cold        | Cold                | Cold (usually)       | Hot                  |
| Use case        | CPU-bound lazy ops  | Async streams        | Communication between coroutines |

**Use Flow** for async data streams (database updates, API polls, UI events).
**Use Channel** for producer-consumer pipelines between coroutines.
**Use Sequence** for synchronous lazy transformations on in-memory data.

---

## StateFlow vs SharedFlow

| Feature        | `StateFlow`                    | `SharedFlow`                   |
|---------------|--------------------------------|--------------------------------|
| Current value  | Always has one                 | None (unless replay > 0)       |
| New collector  | Gets latest value immediately  | Gets `replay` recent values    |
| Conflation     | Yes (latest only)              | No (all events preserved)      |
| Use case       | UI state (current screen state)| Events (navigation, errors)    |

```kotlin
// StateFlow — model screen state
val uiState: StateFlow<UiState> = _uiState.asStateFlow()

// SharedFlow — one-shot events
val events: SharedFlow<Event> = _events.asSharedFlow()
```

---

## Testing Coroutines

Use `kotlinx-coroutines-test`:

```kotlin
@Test
fun `test coroutine`() = runTest {
    // TestCoroutineScope controls virtual time
    val result = async { fetchData() }
    advanceTimeBy(1000)   // advance virtual clock, no real waiting
    assertEquals("result", result.await())
}
```

`runTest` replaces `runBlocking` in tests and makes `delay()` instant.
