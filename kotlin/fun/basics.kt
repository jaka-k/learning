// ============================================================
// Kotlin Functions — Basics to Intermediate
// ============================================================

// Top-level functions — no class wrapper needed (unlike Java)
fun greet(name: String): String {
    return "Hello, $name!"
}

// Single-expression function — body is an expression, return type inferred
fun square(x: Int) = x * x

// Default parameter values — eliminates most overload boilerplate
fun connect(host: String, port: Int = 8080, secure: Boolean = false): String {
    val protocol = if (secure) "https" else "http"
    return "$protocol://$host:$port"
}

// Named arguments — can reorder, self-documents call sites
fun createUser(name: String, age: Int, email: String) =
    "$name (age $age) <$email>"

// vararg — variable number of args, received as typed array
fun sum(vararg numbers: Int): Int = numbers.sum()   // numbers: IntArray

// Nothing return type — function diverges (throws or infinite loops)
// Useful as return type in branches: val x = condition ?: fail("msg")
fun fail(message: String): Nothing = throw IllegalStateException(message)

// Unit — analogous to void, but Unit is a real singleton object
// Can be omitted from the signature
fun log(message: String): Unit = println("[LOG] $message")

// Local functions — defined inside another function, close over outer scope
fun processInput(input: String): String {
    fun validate(s: String) = s.isNotBlank() && s.length <= 100
    return if (validate(input)) input.trim() else fail("Invalid: $input")
}

// @tailrec — compiler verifies the call is in tail position and rewrites
// the recursion into a loop, preventing StackOverflowError
tailrec fun factorial(n: Long, acc: Long = 1L): Long =
    if (n <= 1L) acc else factorial(n - 1L, n * acc)

// infix — member/extension with one param; called without dot/parens
// Great for DSL-like readability: 3 times { ... }
infix fun Int.times(action: () -> Unit) {
    for (i in 1..this) action()
}

// Operator overloading — implement well-known operator functions
// Full list: plus, minus, times, div, rem, unaryMinus, inc, dec,
// compareTo, get, set, contains, invoke, rangeTo, iterator…
data class Vector2(val x: Double, val y: Double) {
    operator fun plus(other: Vector2) = Vector2(x + other.x, y + other.y)
    operator fun times(scalar: Double) = Vector2(x * scalar, y * scalar)
    operator fun unaryMinus() = Vector2(-x, -y)

    // component functions power destructuring declarations
    // data classes generate these automatically for each property
    // operator fun component1() = x  ← already generated
}

// Destructuring — works wherever componentN() functions exist
fun minMax(list: List<Int>): Pair<Int, Int> = list.min() to list.max()

fun main() {
    println(greet("World"))

    // Named args — order doesn't matter, very readable
    println(createUser(name = "Alice", email = "alice@example.com", age = 30))

    // Spread operator (*) unpacks an array into vararg position
    val nums = intArrayOf(1, 2, 3, 4, 5)
    println(sum(*nums))

    // infix call (equivalent to: 3.times { ... })
    3 times { print("Kotlin! ") }; println()

    // Operators
    val v1 = Vector2(1.0, 2.0)
    val v2 = Vector2(3.0, 4.0)
    println(v1 + v2)      // calls v1.plus(v2)
    println(v1 * 2.0)     // calls v1.times(2.0)
    println(-v1)          // calls v1.unaryMinus()

    // Destructuring a Pair (component1, component2)
    val (lo, hi) = minMax(listOf(5, 1, 8, 2, 9))
    println("min=$lo  max=$hi")

    // tailrec — no stack overflow even at n=1_000_000
    println(factorial(20))
}
