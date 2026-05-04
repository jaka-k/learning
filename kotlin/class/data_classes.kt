// ============================================================
// Data Classes, Destructuring, and Copy
// ============================================================
// `data class` auto-generates: equals, hashCode, toString, copy, componentN
// Requirements: primary constructor must have ≥1 parameter, all val/var.
// data classes are implicitly final (can be open, but unusual).

data class Point(val x: Double, val y: Double)

data class User(
    val id: Long,
    val name: String,
    val email: String,
    val roles: List<String> = emptyList()
)

// ----- equals and hashCode --------------------------------------------------
// Generated equals compares all properties declared in the primary constructor.
// Properties in the body are EXCLUDED.

data class Config(val host: String, val port: Int) {
    var lastUsed: Long = 0L   // NOT part of equals/hashCode/toString/copy
}

fun equalsDemo() {
    val a = Config("localhost", 8080)
    val b = Config("localhost", 8080)
    a.lastUsed = 12345L
    b.lastUsed = 99999L

    println(a == b)           // true — lastUsed not in equals
    println(a.hashCode() == b.hashCode())  // true
}

// ----- copy -----------------------------------------------------------------
// `copy` creates a new instance with some properties changed.
// This is the idiomatic way to do "update" in immutable data models (Redux-style).

fun copyDemo() {
    val user = User(1, "Alice", "alice@example.com", listOf("admin"))

    // Change only the email; other fields are copied
    val updated = user.copy(email = "alice@newdomain.com")
    println(user)
    println(updated)

    // Deep copy caveat: copy() is shallow — nested collections are shared
    val withRole = user.copy(roles = user.roles + "editor")  // new list
    println(withRole.roles)
}

// ----- Destructuring declarations -------------------------------------------
// componentN() functions enable destructuring anywhere a declaration is expected.
// data class generates component1(), component2(), … for primary constructor params.

fun destructuringDemo() {
    val p = Point(3.0, 4.0)
    val (x, y) = p   // calls p.component1(), p.component2()
    println("x=$x, y=$y")

    // Skip a component with `_`
    val user = User(42, "Bob", "bob@example.com")
    val (id, name, _) = user   // skip email
    println("id=$id, name=$name")

    // Destructuring in for loops
    val points = listOf(Point(0.0, 0.0), Point(1.0, 2.0), Point(3.0, 4.0))
    for ((x2, y2) in points) {
        println("($x2, $y2)")
    }

    // Map.Entry is destructurable (component1=key, component2=value)
    val map = mapOf("a" to 1, "b" to 2)
    for ((k, v) in map) {
        println("$k -> $v")
    }
}

// ----- Custom componentN (non-data classes) ---------------------------------
// Any class can participate in destructuring by declaring operator componentN()

class RGB(val r: Int, val g: Int, val b: Int) {
    operator fun component1() = r
    operator fun component2() = g
    operator fun component3() = b
}

// ----- Pair and Triple ------------------------------------------------------
// stdlib lightweight data holders; for more fields, prefer named data classes

fun pairTripleDemo() {
    // `to` infix creates a Pair
    val coord: Pair<Int, Int> = 3 to 5
    val (cx, cy) = coord
    println("$cx, $cy")

    // Triple
    val rgb: Triple<Int, Int, Int> = Triple(255, 128, 0)
    val (r, g, b) = rgb
    println("R=$r G=$g B=$b")
}

// ----- Sealed data hierarchies (Kotlin 1.9+) ---------------------------------
// Combining sealed classes with data classes gives exhaustive ADTs

sealed class Result<out T> {
    data class Success<T>(val value: T) : Result<T>()
    data class Failure(val error: Throwable) : Result<Nothing>()
    object Loading : Result<Nothing>()  // singleton state
}

fun <T> Result<T>.getOrNull(): T? = when (this) {
    is Result.Success -> value
    is Result.Failure -> null
    Result.Loading    -> null
}

fun <T> Result<T>.getOrElse(default: T): T = when (this) {
    is Result.Success -> value
    is Result.Failure -> default
    Result.Loading    -> default
}

// ----- Value objects pattern ------------------------------------------------
// Wrapping primitives in data classes gives type safety

data class Email(val value: String) {
    init {
        require(value.contains('@')) { "Invalid email: $value" }
    }
}

data class Money(val amount: Long, val currency: String) {
    operator fun plus(other: Money): Money {
        require(currency == other.currency) { "Currency mismatch" }
        return copy(amount = amount + other.amount)
    }
}

fun main() {
    println("--- equals ---")
    equalsDemo()

    println("\n--- copy ---")
    copyDemo()

    println("\n--- destructuring ---")
    destructuringDemo()

    println("\n--- custom component ---")
    val color = RGB(200, 100, 50)
    val (r, g, b) = color
    println("R=$r G=$g B=$b")

    println("\n--- Pair/Triple ---")
    pairTripleDemo()

    println("\n--- Result ADT ---")
    val ok: Result<Int> = Result.Success(42)
    val err: Result<Int> = Result.Failure(RuntimeException("oops"))
    println(ok.getOrNull())
    println(err.getOrElse(-1))

    println("\n--- Value objects ---")
    val price = Money(1000, "USD") + Money(500, "USD")
    println(price)
}
