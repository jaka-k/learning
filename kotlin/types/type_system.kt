// ============================================================
// Kotlin Type System — Smart Casts, Type Checks, When as Expression
// ============================================================

// ----- is / !is checks and smart casts ------------------------------------
// After an `is` check, the compiler narrows (smart-casts) the type in scope.
// No explicit cast needed — the compiler does it.

fun describe(obj: Any): String {
    return when (obj) {
        is Int    -> "Integer: ${obj * 2}"     // obj is Int here
        is String -> "String of length ${obj.length}"  // obj is String here
        is List<*> -> "List with ${obj.size} elements"
        is Map<*, *> -> "Map with ${obj.size} entries"
        else      -> "Unknown: ${obj::class.simpleName}"
    }
}

// Smart casts work in if branches too
fun processValue(value: Any?) {
    if (value is String && value.length > 0) {
        // Both conditions contribute to the narrowed type
        println("Non-empty string: $value")
    }

    // Smart cast also works with when subjects
    when {
        value == null       -> println("null")
        value is Int        -> println("Int: $value")
        value is String     -> println("String: $value")
    }
}

// Smart cast with val — compiler tracks that the property can't change
class Container(val value: Any) {
    fun process(): String {
        // `value` is val → stable → compiler can smart-cast
        return if (value is String) value.uppercase() else value.toString()
    }
}

// Smart cast doesn't work with var in class bodies (another thread could change it)
// Solution: capture in a local val first
class UnsafeContainer(var value: Any) {
    fun process(): String {
        val v = value   // captured — now stable
        return if (v is String) v.uppercase() else v.toString()
    }
}

// ----- as and as? (unsafe and safe cast) ------------------------------------

fun castingExamples() {
    val obj: Any = "Hello"

    // as — throws ClassCastException if wrong type
    val str: String = obj as String
    println(str.length)

    // as? — returns null if wrong type (safe cast)
    val num: Int? = obj as? Int   // null
    println(num)

    // Common pattern: as? + Elvis
    val length = (obj as? String)?.length ?: -1
    println(length)
}

// ----- when as expression --------------------------------------------------
// `when` can act as both statement and expression.
// As expression, it must be exhaustive (or have an `else`).
// With a sealed class subject, `else` is not needed (compiler verifies).

sealed class Shape
data class Circle(val radius: Double) : Shape()
data class Rectangle(val w: Double, val h: Double) : Shape()
object Triangle : Shape()

fun area(shape: Shape): Double = when (shape) {
    is Circle    -> Math.PI * shape.radius * shape.radius
    is Rectangle -> shape.w * shape.h
    Triangle     -> 0.5 * 3.0 * 4.0   // simplified
    // No `else` needed — sealed class is exhaustive
}

// `when` without subject — acts like a chain of if-else
fun classify(n: Int) = when {
    n < 0     -> "negative"
    n == 0    -> "zero"
    n < 10    -> "single digit"
    n < 100   -> "double digit"
    else      -> "large"
}

// `when` with multiple conditions in one branch
fun dayType(day: String) = when (day.uppercase()) {
    "SATURDAY", "SUNDAY" -> "Weekend"
    "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY" -> "Weekday"
    else -> "Unknown"
}

// `when` with ranges and predicates
fun describe(n: Int) = when (n) {
    in 1..10     -> "1–10"
    in 11..100   -> "11–100"
    !in 0..1000  -> "out of range"
    else         -> "101–1000"
}

// ----- Type aliases ---------------------------------------------------------
// Aliases are compile-time only — they don't create new types.
// Useful to shorten complex generic signatures or clarify intent.

typealias EventHandler<E> = (E) -> Unit
typealias StringPair = Pair<String, String>
typealias JsonMap = Map<String, Any?>

fun processEvent(handler: EventHandler<String>) = handler("click")

// ----- Any, Unit, Nothing ---------------------------------------------------
// Any   — root of the non-nullable hierarchy (like Object in Java)
// Any?  — root of the nullable hierarchy
// Unit  — singleton return type for side-effecting functions (not void)
// Nothing — bottom type; subtype of every type; represents divergence

fun alwaysThrows(msg: String): Nothing = throw RuntimeException(msg)
fun infiniteLoop(): Nothing { while (true) {} }

fun nothingInBranches(x: Int): String =
    if (x > 0) "positive"
    else alwaysThrows("Must be positive")  // OK because Nothing is a subtype of String

// ----- Type upper bounds and intersection types ----------------------------
// Kotlin doesn't have explicit intersection types in user code, but you can
// express them via multiple bounds in a `where` clause.

interface Named { val name: String }
interface Aged  { val age: Int }

fun <T> greet(entity: T) where T : Named, T : Aged {
    println("Hello ${entity.name}, age ${entity.age}")
}

data class Person(override val name: String, override val age: Int) : Named, Aged

fun main() {
    println(describe(42))
    println(describe("Kotlin"))
    println(describe(listOf(1, 2, 3)))

    processValue("hello")
    processValue(null)
    processValue(42)

    println(Container("world").process())
    println(UnsafeContainer(123).process())

    castingExamples()

    val shapes: List<Shape> = listOf(Circle(5.0), Rectangle(3.0, 4.0), Triangle)
    shapes.forEach { println("${it::class.simpleName}: area=${area(it)}") }

    println(classify(-5))
    println(classify(0))
    println(classify(7))
    println(classify(42))

    println(dayType("Monday"))
    println(dayType("Saturday"))

    println(describe(5))
    println(describe(500))

    processEvent { e -> println("Event: $e") }

    greet(Person("Alice", 30))
}
