// ============================================================
// Coroutines — Suspending Functions, Coroutine Builders, Context
// ============================================================
// Requires: org.jetbrains.kotlinx:kotlinx-coroutines-core
//
// Coroutines are lightweight threads managed by the Kotlin runtime.
// A `suspend` function can pause execution without blocking a thread,
// freeing the thread to do other work until the result is ready.

import kotlinx.coroutines.*
import kotlinx.coroutines.channels.*
import kotlin.system.measureTimeMillis

// ----- suspend functions ----------------------------------------------------
// A suspend function can only be called from another suspend function
// or from a coroutine builder (launch, async, runBlocking).
// Suspension points are marked implicitly at every `suspend` call.

suspend fun fetchUser(id: Int): String {
    delay(100)   // non-blocking sleep — suspends the coroutine, not the thread
    return "User#$id"
}

suspend fun fetchRole(userId: String): String {
    delay(50)
    return "admin"
}

// ----- Coroutine builders ---------------------------------------------------

// runBlocking — bridges blocking and suspend world; blocks the calling thread.
// Use in main() and tests; AVOID in production library/server code.
fun runBlockingDemo() = runBlocking {
    val user = fetchUser(1)       // sequential
    val role = fetchRole(user)    // sequential
    println("$user is $role")
}

// launch — fire-and-forget; returns a Job (not a value)
// async  — returns Deferred<T>; call .await() to get the value

fun launchAndAsync() = runBlocking {
    // Sequential
    val seqTime = measureTimeMillis {
        val user = fetchUser(1)
        val role = fetchRole(user)
        println("Sequential: $user / $role")
    }
    println("Sequential time: ${seqTime}ms")

    // Concurrent with async
    val concTime = measureTimeMillis {
        val userDeferred = async { fetchUser(2) }
        val anotherDeferred = async { fetchUser(3) }
        println("Concurrent: ${userDeferred.await()} / ${anotherDeferred.await()}")
    }
    println("Concurrent time: ${concTime}ms")  // ~100ms instead of ~200ms
}

// ----- Structured concurrency -----------------------------------------------
// Every coroutine belongs to a CoroutineScope.
// When a scope is cancelled or fails, ALL its children are cancelled too.
// This prevents coroutine leaks (compare to fire-and-forget Thread.start()).

fun structuredConcurrency() = runBlocking {
    // coroutineScope creates a child scope; it suspends until all children complete
    coroutineScope {
        launch { delay(200); println("Child 1 done") }
        launch { delay(100); println("Child 2 done") }
        println("Parent waiting...")
    }
    println("All children completed")
}

// ----- Coroutine Context and Dispatchers ------------------------------------
// CoroutineContext = Dispatcher + Job + CoroutineName + ExceptionHandler
//
// Dispatchers.Default  — CPU-bound work (thread pool sized to CPU count)
// Dispatchers.IO       — I/O-bound work (large thread pool, up to 64)
// Dispatchers.Main     — UI thread (Android/Swing); not available in CLI
// Dispatchers.Unconfined — starts in current thread, resumes in whatever thread

fun dispatcherDemo() = runBlocking {
    launch(Dispatchers.Default) {
        println("Default: ${Thread.currentThread().name}")
    }
    launch(Dispatchers.IO) {
        println("IO: ${Thread.currentThread().name}")
    }
    // withContext — switch dispatcher mid-coroutine (preferred over launch+await)
    val result = withContext(Dispatchers.Default) {
        // Heavy computation
        (1..1_000_000).sum()
    }
    println("Result: $result")
}

// ----- Job and cancellation -------------------------------------------------
// Coroutines are cooperative — they must check for cancellation.
// delay() and yield() are cancellation points.
// Long CPU-bound loops need manual checks: isActive, ensureActive().

fun cancellationDemo() = runBlocking {
    val job = launch {
        repeat(1000) { i ->
            ensureActive()   // throws CancellationException if cancelled
            println("Working $i")
            delay(50)
        }
    }
    delay(200)       // let it run for a bit
    job.cancel()     // request cancellation
    job.join()       // wait for the coroutine to finish cancelling
    println("Cancelled")
}

// withTimeout — automatically cancels after a deadline
suspend fun timeoutDemo() {
    try {
        withTimeout(300) {
            delay(1000)   // will be cancelled after 300ms
            println("This won't print")
        }
    } catch (e: TimeoutCancellationException) {
        println("Timed out!")
    }

    // withTimeoutOrNull — returns null on timeout instead of throwing
    val result = withTimeoutOrNull(300) {
        delay(1000)
        "success"
    }
    println("Result: $result")  // null
}

// ----- Exception handling ---------------------------------------------------
// CancellationException is special — it's not an error, just cancellation.
// Other exceptions propagate up through the scope hierarchy.
//
// SupervisorJob / supervisorScope: a child failure doesn't cancel siblings.

fun exceptionHandling() = runBlocking {
    // CoroutineExceptionHandler — catches uncaught exceptions in root coroutines
    val handler = CoroutineExceptionHandler { _, e ->
        println("Caught: ${e.message}")
    }

    val scope = CoroutineScope(Dispatchers.Default + handler)
    scope.launch {
        throw RuntimeException("Something went wrong")
    }
    delay(100)   // give it time to run

    // supervisorScope — failure of one child doesn't cancel others
    supervisorScope {
        val child1 = launch {
            delay(100)
            throw RuntimeException("Child 1 failed")
        }
        val child2 = launch {
            delay(200)
            println("Child 2 completed normally")
        }
        // Wait for both without one failing the other
        try { child1.join() } catch (e: Exception) { println("child1 failed: ${e.message}") }
        child2.join()
    }
}

// ----- Coroutine scope in a class ------------------------------------------
// Use CoroutineScope interface or delegate to SupervisorJob + dispatcher.
// Cancel the scope when the class is torn down.

class Repository(private val scope: CoroutineScope = CoroutineScope(Dispatchers.IO)) {
    fun prefetch(id: Int): Job = scope.launch {
        val data = fetchUser(id)
        println("Prefetched: $data")
    }

    fun close() = scope.cancel()   // cancels all coroutines owned by this scope
}

fun main() = runBlocking {
    println("=== runBlocking ===")
    runBlockingDemo()

    println("\n=== launch/async ===")
    launchAndAsync()

    println("\n=== Structured concurrency ===")
    structuredConcurrency()

    println("\n=== Dispatchers ===")
    dispatcherDemo()

    println("\n=== Cancellation ===")
    cancellationDemo()

    println("\n=== Timeout ===")
    timeoutDemo()

    println("\n=== Exception handling ===")
    exceptionHandling()
}
