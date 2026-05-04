// ============================================================
// Inline Functions — inline, noinline, crossinline, reified
// ============================================================
// `inline` copies the function body (and lambda bodies) to the call site
// at compile time, eliminating the object allocation for each lambda and
// enabling features that only work at compile time (reified, non-local return).

// ----- Basic inline ---------------------------------------------------------
// Without inline: each lambda { } creates a Function object on the heap.
// With inline: the lambda body is copy-pasted to the call site. Zero allocation.

inline fun measure(block: () -> Unit): Long {
    val start = System.nanoTime()
    block()   // inlined — no Function object created
    return System.nanoTime() - start
}

// ----- Non-local returns ----------------------------------------------------
// `return` inside a regular lambda returns from the lambda.
// `return` inside an INLINED lambda returns from the ENCLOSING function.
// This is called a "non-local return".

fun findFirst(list: List<Int>, predicate: (Int) -> Boolean): Int? {
    list.forEach { item ->
        if (predicate(item)) return item  // non-local: returns from findFirst
    }
    return null
}
// forEach is inline in stdlib, so `return item` exits findFirst, not just the lambda.

// ----- noinline -------------------------------------------------------------
// Sometimes you want to pass a lambda to another function rather than inline it.
// `noinline` opts that specific lambda out of inlining.

inline fun hybrid(
    inlinedLambda: () -> Unit,
    noinline storedLambda: () -> Unit   // this one is kept as an object
) {
    inlinedLambda()         // inlined — body copied here
    val ref = storedLambda  // OK: storedLambda is a real object, can be stored
    ref()
}

// ----- crossinline ----------------------------------------------------------
// Inlined lambdas allow non-local returns, but if you pass the lambda to
// another execution context (e.g., another lambda, a Runnable), a non-local
// return would be illegal. `crossinline` marks lambdas that are inlined BUT
// must NOT use non-local returns.

inline fun runLater(crossinline block: () -> Unit) {
    // Imagine scheduling this on another thread/executor
    val runnable = Runnable { block() }  // block can't do non-local return here
    runnable.run()
}

// ----- reified type parameters ----------------------------------------------
// Normally type parameters are erased at runtime (JVM type erasure).
// In an INLINE function, the actual type is available at the call site,
// so you can use `reified` to access it at runtime: is T, T::class, etc.

// Without reified — can't use T at runtime:
// fun <T> List<*>.filterByType(): List<T> = filterIsInstance<T>()  // COMPILE ERROR

// With reified — T is real at the call site
inline fun <reified T> List<*>.filterByType(): List<T> = filterIsInstance<T>()

// Practical use: type-safe JSON parsing, service locator, etc.
inline fun <reified T> Any.tryCast(): T? = this as? T

// You can use T::class, is T, typeof T — all because the type is inlined
inline fun <reified T : Any> printTypeName() = println(T::class.simpleName)

// ----- Combining inline + reified for factory patterns ----------------------

interface Serializer<T> {
    fun serialize(obj: T): String
    fun deserialize(json: String): T
}

// Registry keyed by KClass, looked up with reified
object SerializerRegistry {
    private val map = mutableMapOf<kotlin.reflect.KClass<*>, Serializer<*>>()

    fun <T : Any> register(klass: kotlin.reflect.KClass<T>, s: Serializer<T>) {
        map[klass] = s
    }

    @Suppress("UNCHECKED_CAST")
    inline fun <reified T : Any> get(): Serializer<T>? =
        map[T::class] as? Serializer<T>
}

// ----- Performance: when to use inline ----------------------------------------
// USE inline when:
//   - The function takes lambda parameters (eliminates allocations)
//   - You need reified type parameters
//   - The function body is small (avoid code-size explosion)
//
// AVOID inline when:
//   - The function is large (code bloat at every call site)
//   - The function has many call sites
//   - The lambda needs to be stored, not called immediately (use noinline)

// ----- Inline classes (value classes) ---------------------------------------
// @JvmInline value class wraps a single value with zero overhead at runtime.
// At runtime it's just the underlying type; the wrapper only exists at compile time.
// Covered more thoroughly in class/value_classes.kt

@JvmInline
value class UserId(val raw: String) {
    init { require(raw.isNotBlank()) { "UserId cannot be blank" } }
    fun isAdmin() = raw.startsWith("admin_")
}

fun main() {
    // measure() — lambda is inlined, no allocation
    val elapsed = measure {
        var sum = 0L
        for (i in 1..1_000_000) sum += i
    }
    println("Elapsed: ${elapsed}ns")

    // filterByType uses reified T
    val mixed: List<Any> = listOf(1, "hello", 2, "world", 3.14)
    val strings: List<String> = mixed.filterByType<String>()
    val ints: List<Int> = mixed.filterByType<Int>()
    println(strings)
    println(ints)

    // reified type name
    printTypeName<String>()    // String
    printTypeName<List<Int>>() // List

    // tryCast
    val obj: Any = "Hello"
    val s: String? = obj.tryCast<String>()
    val n: Int?    = obj.tryCast<Int>()    // null — not an Int
    println("$s / $n")

    // Value class — UserId and String are the same at runtime
    val id = UserId("admin_42")
    println(id.isAdmin())

    // findFirst uses non-local return via inlined forEach
    println(findFirst(listOf(1, 3, 5, 4, 7)) { it % 2 == 0 })  // 4
}
