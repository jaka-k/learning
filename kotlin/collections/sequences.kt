// ============================================================
// Sequences — Lazy vs Eager Collections
// ============================================================
// Collections process operations EAGERLY: each step creates a new list.
// Sequences process operations LAZILY: each element flows through ALL
// operations before the next element is processed.
//
// WHEN TO USE SEQUENCES:
//   - Large or infinite data sets (sequences can be infinite)
//   - Chains of multiple operations (avoids intermediate collections)
//   - When you don't need all results (find, first, take)
//
// WHEN TO USE COLLECTIONS:
//   - Small data sets (overhead of Sequence machinery isn't worth it)
//   - Random access needed (sequences are forward-only)
//   - Multiple iterations over the same data

// ----- Eager vs Lazy comparison ---------------------------------------------

fun eagerVsLazy() {
    val data = (1..1_000_000).toList()

    // EAGER: filter creates a new list, then map creates another
    val eagerStart = System.nanoTime()
    val eagerResult = data
        .filter { it % 2 == 0 }   // new list of 500_000 elements
        .map { it * it }           // new list of 500_000 elements
        .take(5)                   // new list of 5 elements
    val eagerTime = System.nanoTime() - eagerStart

    // LAZY (Sequence): processes element by element, stops after 5
    val lazyStart = System.nanoTime()
    val lazyResult = data
        .asSequence()
        .filter { it % 2 == 0 }   // no work yet
        .map { it * it }           // no work yet
        .take(5)                   // no work yet
        .toList()                  // TERMINAL: now all ops run for 5 elements total
    val lazyTime = System.nanoTime() - lazyStart

    println("Eager:    $eagerResult in ${eagerTime / 1_000_000}ms")
    println("Lazy:     $lazyResult  in ${lazyTime / 1_000_000}ms")
}

// ----- Order of operations: eager vs lazy -----------------------------------
// This matters for understanding which elements get processed.

fun operationOrder() {
    println("--- Eager order ---")
    listOf(1, 2, 3)
        .filter  { print("filter($it) ");  it > 1 }
        .map     { print("map($it) ");     it * 10 }
        .forEach { println("forEach($it)") }
    // All filter(), then all map(), then forEach

    println("\n--- Lazy order ---")
    listOf(1, 2, 3)
        .asSequence()
        .filter  { print("filter($it) ");  it > 1 }
        .map     { print("map($it) ");     it * 10 }
        .forEach { println("forEach($it)") }
    // Each element goes through ALL ops before the next element starts
}

// ----- Creating sequences ---------------------------------------------------

fun creatingSequences() {
    // From a collection
    val fromList = listOf(1, 2, 3).asSequence()

    // sequenceOf — like listOf but lazy
    val explicit = sequenceOf(1, 2, 3, 4, 5)

    // generateSequence — infinite or finite sequence from a seed
    val naturals = generateSequence(1) { it + 1 }   // infinite: 1, 2, 3, …
    println(naturals.take(10).toList())

    // Finite: generateSequence stops when the lambda returns null
    val countdown = generateSequence(10) { if (it > 0) it - 1 else null }
    println(countdown.toList())

    // sequence { } builder — most powerful; uses yield / yieldAll
    val fibonacci = sequence {
        var a = 0L; var b = 1L
        while (true) {
            yield(a)           // suspend and emit `a`
            val next = a + b
            a = b; b = next
        }
    }
    println(fibonacci.take(15).toList())

    // Reading lines lazily from a string (simulate File.lineSequence())
    val csv = "name,age\nAlice,30\nBob,25"
    val rows = csv.lineSequence().drop(1).map { it.split(",") }
    rows.forEach { println(it) }
}

// ----- Infinite sequences and lazy pipelines --------------------------------

val primes: Sequence<Int> = sequence {
    val sieve = mutableSetOf<Int>()
    var candidate = 2
    while (true) {
        if (sieve.none { candidate % it == 0 }) {
            yield(candidate)
            sieve.add(candidate)
        }
        candidate++
    }
}

// Collatz sequence — ends at 1
fun collatz(start: Long) = generateSequence(start) { n ->
    when {
        n == 1L  -> null
        n % 2 == 0L -> n / 2
        else     -> 3 * n + 1
    }
}

// ----- Terminal operations --------------------------------------------------
// Operations that trigger evaluation: toList, toSet, first, last, count,
// find, any, all, none, sum, min, max, fold, reduce, forEach

fun terminalOps() {
    val seq = generateSequence(1) { it + 1 }

    println(seq.first { it > 100 })              // 101 — stops as soon as found
    println(seq.take(5).sum())                   // 15
    println(seq.takeWhile { it <= 10 }.count())  // 10
}

// ----- Sequences vs flows (preview) -----------------------------------------
// Sequence is synchronous and single-threaded.
// If you need async lazy streams, use kotlinx.coroutines Flow.
// They have the same conceptual model but Flow suspends between elements.

// ----- Practical example: processing a log file lazily ----------------------

data class LogEntry(val level: String, val message: String)

fun parseLog(line: String): LogEntry? {
    val parts = line.split(" ", limit = 2)
    return if (parts.size == 2) LogEntry(parts[0], parts[1]) else null
}

fun analyzeLog(lines: Sequence<String>): Map<String, Int> =
    lines
        .mapNotNull { parseLog(it) }
        .groupingBy { it.level }
        .eachCount()

fun main() {
    println("=== Eager vs Lazy ===")
    eagerVsLazy()

    println("\n=== Operation Order ===")
    operationOrder()

    println("\n=== Creating Sequences ===")
    creatingSequences()

    println("\n=== Primes (infinite sequence) ===")
    println(primes.take(20).toList())

    println("\n=== Collatz(27) ===")
    println(collatz(27L).toList())
    println("Steps: ${collatz(27L).count()}")

    println("\n=== Terminal Ops ===")
    terminalOps()

    println("\n=== Log analysis ===")
    val fakeLog = sequenceOf(
        "INFO  Server started",
        "DEBUG Request received",
        "ERROR Database timeout",
        "INFO  Request processed",
        "WARN  Slow query detected",
        "ERROR Connection refused"
    )
    println(analyzeLog(fakeLog))
}
