// ============================================================
// Extension Functions and Properties
// ============================================================
// Extensions let you add functions/properties to existing types
// without inheritance or decorators. They are resolved statically
// (at compile time based on the declared type, not the runtime type).

// ----- Basic extension function ---------------------------------------------

// Adds a `isPalindrome()` method to String without subclassing
fun String.isPalindrome(): Boolean {
    val cleaned = lowercase().filter { it.isLetterOrDigit() }
    return cleaned == cleaned.reversed()
}

// Extension on nullable receiver — safe to call even on null
fun String?.orEmpty(): String = this ?: ""   // already in stdlib, shown for demo

// Extensions on generic types
fun <T> List<T>.secondOrNull(): T? = if (size >= 2) this[1] else null

// ----- Extension properties -------------------------------------------------
// No backing field — computed each access

val String.wordCount: Int
    get() = trim().split(Regex("\\s+")).filter { it.isNotEmpty() }.size

val <T> List<T>.lastIndex: Int   // already in stdlib
    get() = size - 1

// ----- Extension on companion object ----------------------------------------
// Lets you add "static" factory methods to existing classes via their
// companion object. The class must have a companion (even empty).

class Event(val name: String) {
    companion object   // empty companion — just enough for extensions
}

fun Event.Companion.unknown() = Event("unknown")

// ----- Member vs extension priority -----------------------------------------
// If a class has a member function with the same signature as an extension,
// the MEMBER always wins. Extensions can't shadow members.

class Printer {
    fun print(msg: String) = println("Member: $msg")
}
fun Printer.print(msg: String) = println("Extension: $msg")  // never called

// ----- Scope and dispatch ---------------------------------------------------
// Extensions are resolved on the STATIC (declared) type, not runtime type.

open class Shape
class Circle : Shape()

fun Shape.describe() = "I am a Shape"
fun Circle.describe() = "I am a Circle"

fun printDescription(s: Shape) = println(s.describe())  // always "I am a Shape"

// ----- Extensions inside classes (dispatch + extension receiver) -------------
// An extension declared inside a class has TWO receivers:
//   - `this` = dispatch receiver (the class instance)
//   - the extension receiver is accessed normally

class HtmlBuilder {
    val content = StringBuilder()

    // Extension on String, but declared inside HtmlBuilder.
    // Inside this function: `this` is HtmlBuilder, String is the receiver.
    fun String.tag(tagName: String): String {
        content.append("<$tagName>$this</$tagName>\n")
        return "<$tagName>$this</$tagName>"
    }

    fun build(): String {
        "Hello World".tag("h1")
        "Some paragraph".tag("p")
        return content.toString()
    }
}

// ----- Practical patterns ---------------------------------------------------

// 1. Fluent/builder style via extension returning `this`
fun <T> MutableList<T>.addAll(vararg items: T): MutableList<T> {
    items.forEach { add(it) }
    return this
}

// 2. "Let-chaining" helper — apply only when condition is true
fun <T> T.applyIf(condition: Boolean, block: T.() -> T): T =
    if (condition) block() else this

// 3. Extending third-party / stdlib types
fun Int.clamp(min: Int, max: Int) = coerceIn(min, max)

fun ByteArray.toHexString() = joinToString("") { "%02x".format(it) }

// 4. Extension functions that act like DSL entry points
fun List<Int>.stats(): Map<String, Double> = mapOf(
    "min"  to minOrNull()!!.toDouble(),
    "max"  to maxOrNull()!!.toDouble(),
    "mean" to average(),
    "sum"  to sum().toDouble()
)

fun main() {
    println("racecar".isPalindrome())    // true
    println("hello".isPalindrome())      // false

    println("  Hello World  ".wordCount)  // 2

    val nums = listOf(1, 2, 3)
    println(nums.secondOrNull())          // 2
    println(emptyList<Int>().secondOrNull())  // null

    val e = Event.unknown()               // companion extension
    println(e.name)

    val p = Printer()
    p.print("test")  // "Member: test" — member wins

    printDescription(Circle())           // "I am a Shape" — static dispatch!

    val html = HtmlBuilder().build()
    println(html)

    // Fluent addAll
    val list = mutableListOf<String>().addAll("a", "b", "c").addAll("d")
    println(list)

    // applyIf
    val value = 42.applyIf(true) { this + 8 }  // 50
    println(value)

    println(150.clamp(0, 100))  // 100

    println(byteArrayOf(0xDE.toByte(), 0xAD.toByte(), 0xBE.toByte(), 0xEF.toByte()).toHexString())

    println(listOf(3, 1, 4, 1, 5, 9, 2, 6).stats())
}
