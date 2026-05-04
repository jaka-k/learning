// ============================================================
// Kotlin Flows — Cold, Hot, StateFlow, SharedFlow
// ============================================================
// Flow is the coroutines answer to Rx/RxJava: a COLD asynchronous stream.
// Requires: org.jetbrains.kotlinx:kotlinx-coroutines-core
//
// KEY DISTINCTION:
//   Cold flow  — starts producing when collected; one producer per collector
//   Hot flow   — produces regardless of collectors; shared across collectors
//                StateFlow and SharedFlow are hot.

import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlin.time.Duration.Companion.milliseconds

// ----- Cold Flow basics -----------------------------------------------------

// `flow { }` builder — suspend code inside, emit values with emit()
fun simpleFlow(): Flow<Int> = flow {
    println("Flow started")
    for (i in 1..5) {
        delay(100)
        emit(i)   // suspend and send value downstream
    }
    println("Flow completed")
}

// Flows are COLD: nothing happens until collected
// Calling simpleFlow() twice creates two independent producers.

// ----- Flow operators (lazy, like Sequence) ---------------------------------

fun flowOperators(): Flow<String> = simpleFlow()
    .filter { it % 2 == 0 }          // only even values
    .map { "item-$it" }               // transform
    .onEach { println("Emitting: $it") }  // side effect without transforming
    .catch { e -> emit("error: ${e.message}") }  // handle upstream errors
    .onCompletion { println("Stream completed") }

// ----- Terminal operators (trigger collection) ------------------------------

suspend fun terminalOps() {
    // collect — most basic terminal
    simpleFlow().collect { println("Got: $it") }

    println()

    // collectLatest — cancels current block if new value arrives before it completes
    simpleFlow().collectLatest { value ->
        delay(150)   // slower than emission rate (100ms)
        println("Processed: $value")  // may be skipped if value arrives during delay
    }

    println()

    // toList, toSet — materialise the flow
    val list = simpleFlow().toList()
    println(list)

    // first / last / single
    println(simpleFlow().first())
    println(simpleFlow().last())

    // fold / reduce on flows
    val sum = simpleFlow().fold(0) { acc, v -> acc + v }
    println("Sum: $sum")
}

// ----- Exception handling in flows ------------------------------------------

fun riskyFlow(): Flow<Int> = flow {
    emit(1)
    emit(2)
    throw RuntimeException("Something went wrong")
    emit(3)   // never reached
}

suspend fun flowExceptions() {
    riskyFlow()
        .catch { e ->
            println("Caught: ${e.message}")
            emit(-1)   // emit a fallback value
        }
        .collect { println("Received: $it") }

    // retry — re-subscribe on error
    var attempt = 0
    flow {
        attempt++
        if (attempt < 3) throw RuntimeException("Attempt $attempt failed")
        emit("Success on attempt $attempt")
    }
    .retry(3) { e ->
        println("Retrying after: ${e.message}")
        delay(50)
        true   // return true to retry
    }
    .catch { println("All retries exhausted: ${it.message}") }
    .collect { println(it) }
}

// ----- Combining flows -------------------------------------------------------

suspend fun combiningFlows() {
    val numbers = flow { for (i in 1..3) { delay(100); emit(i) } }
    val letters = flow { for (c in listOf("a","b","c")) { delay(150); emit(c) } }

    // zip — pairs elements position-wise; waits for both
    numbers.zip(letters) { n, c -> "$n$c" }.collect { println("zip: $it") }

    println()

    // combine — emits whenever EITHER flow emits, using the latest from each
    numbers.combine(letters) { n, c -> "$n$c" }.collect { println("combine: $it") }

    println()

    // merge — interleave two flows
    merge(numbers, letters).collect { println("merge: $it") }
}

// ----- flatMapConcat / flatMapMerge / flatMapLatest -------------------------

suspend fun flatMapping() {
    val ids = flowOf(1, 2, 3)

    // flatMapConcat — sequential: waits for inner flow to complete before next
    ids.flatMapConcat { id ->
        flow { delay(100); emit("User$id-A"); emit("User$id-B") }
    }.collect { println("concat: $it") }

    println()

    // flatMapMerge — concurrent: inner flows run in parallel
    ids.flatMapMerge { id ->
        flow { delay(100); emit("User$id") }
    }.collect { println("merge: $it") }

    println()

    // flatMapLatest — cancels previous inner flow when new value arrives
    ids.flatMapLatest { id ->
        flow { delay(200); emit("User$id") }  // 200ms > 100ms between emissions
    }.collect { println("latest: $it") }     // only last id's flow completes
}

// ----- StateFlow — hot, shared, always has a value -------------------------
// StateFlow is a hot flow that:
//   - always holds exactly ONE current value
//   - replays the latest value to new collectors
//   - conflates: rapid updates keep only the latest (no intermediate values)
//   - uses structural equality to skip duplicate updates

class CounterViewModel {
    private val _count = MutableStateFlow(0)
    val count: StateFlow<Int> = _count.asStateFlow()  // expose read-only

    fun increment() { _count.value++ }
    fun reset()     { _count.value = 0 }
}

suspend fun stateFlowDemo() {
    val vm = CounterViewModel()

    val job = CoroutineScope(Dispatchers.Default).launch {
        vm.count.collect { println("Count: $it") }  // always gets latest
    }

    vm.increment()
    vm.increment()
    delay(50)   // let collector process
    vm.increment()
    delay(50)
    job.cancel()
}

// ----- SharedFlow — hot, multicast, configurable replay --------------------
// SharedFlow is like an event bus. Multiple collectors receive the same events.
// Use when events should be broadcast and replay history matters.

class EventBus {
    private val _events = MutableSharedFlow<String>(
        replay = 2,           // new collectors get last 2 events
        extraBufferCapacity = 10  // buffer for slow collectors
    )
    val events: SharedFlow<String> = _events.asSharedFlow()

    suspend fun emit(event: String) = _events.emit(event)
}

suspend fun sharedFlowDemo() {
    val bus = EventBus()
    val scope = CoroutineScope(Dispatchers.Default)

    bus.emit("Event A")   // before any collector — replayed due to replay=2
    bus.emit("Event B")

    val collector1 = scope.launch {
        bus.events.collect { println("Collector1: $it") }
    }
    val collector2 = scope.launch {
        delay(50)   // starts later
        bus.events.collect { println("Collector2: $it") }  // gets replayed events
    }

    delay(100)
    bus.emit("Event C")   // both collectors see this
    delay(100)

    collector1.cancel()
    collector2.cancel()
}

// ----- Flow context and buffer ---------------------------------------------
// Flows are context-preserving by default — they run in the collector's context.
// flowOn() changes the upstream context (where emit runs).

fun contextualFlow(): Flow<Int> = flow {
        println("Emitting on: ${Thread.currentThread().name}")
        for (i in 1..3) { delay(50); emit(i) }
    }
    .flowOn(Dispatchers.Default)  // upstream runs on Default; downstream on caller

fun main() = runBlocking {
    println("=== Flow operators ===")
    flowOperators().collect { println(it) }

    println("\n=== Terminal ops ===")
    terminalOps()

    println("\n=== Exception handling ===")
    flowExceptions()

    println("\n=== Combining flows ===")
    combiningFlows()

    println("\n=== FlatMapping ===")
    flatMapping()

    println("\n=== StateFlow ===")
    stateFlowDemo()

    println("\n=== SharedFlow ===")
    sharedFlowDemo()
}
