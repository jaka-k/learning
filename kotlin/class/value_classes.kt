// ============================================================
// Value Classes (@JvmInline value class)
// ============================================================
// A value class wraps exactly one property. At runtime the wrapper is
// usually eliminated — the underlying type is used directly.
// This gives you type safety at zero (or near-zero) cost.
//
// Requirements:
//   - Annotated with @JvmInline
//   - Primary constructor has exactly one val property
//   - Cannot have var properties or backing fields beyond the one val
//   - Can implement interfaces (at cost of boxing)
//   - Cannot extend classes (can extend Any implicitly)

@JvmInline
value class Metres(val value: Double) {
    // Validation in init runs at compile-time-erased wrapper creation
    init { require(value >= 0) { "Distance cannot be negative" } }

    operator fun plus(other: Metres) = Metres(value + other.value)
    operator fun compareTo(other: Metres) = value.compareTo(other.value)
    override fun toString() = "${value}m"
}

@JvmInline
value class Kilograms(val value: Double) {
    override fun toString() = "${value}kg"
}

// Without value classes, these two calls look identical to the compiler:
// fun setDimensions(length: Double, weight: Double) ...
// You could accidentally swap the arguments!
//
// With value classes:
fun setDimensions(length: Metres, weight: Kilograms) {
    println("Length: $length, Weight: $weight")
}

// ----- Type safety via wrapping primitives ----------------------------------

@JvmInline value class UserId(val raw: Long)

@JvmInline value class OrderId(val raw: Long)

// Now you can't accidentally pass a UserId where an OrderId is expected
fun fetchOrder(orderId: OrderId): String = "Order #${orderId.raw}"
// fetchOrder(UserId(42))  // COMPILE ERROR — type mismatch

// ----- Value classes implementing interfaces --------------------------------
// When a value class implements an interface and is used as that interface type,
// it gets BOXED (heap allocation). Use interfaces sparingly on hot paths.

interface Displayable {
    fun display(): String
}

@JvmInline
value class Temperature(val celsius: Double) : Displayable {
    val fahrenheit: Double get() = celsius * 9.0 / 5.0 + 32.0
    override fun display() = "%.1f°C (%.1f°F)".format(celsius, fahrenheit)
}

// ----- Value classes vs type aliases ----------------------------------------
// typealias Email = String  → just an alias, no type safety (Email == String)
// value class Email(val value: String) → real distinct type at compile time

@JvmInline
value class Email(val value: String) {
    init { require('@' in value) { "Invalid email: $value" } }
    val domain: String get() = value.substringAfter('@')
}

// ----- Inline enum simulation -----------------------------------------------
// Sealed value-class hierarchies can approximate enums with richer types

@JvmInline
value class HttpStatus(val code: Int) {
    val isSuccess get() = code in 200..299
    val isClientError get() = code in 400..499
    val isServerError get() = code in 500..599

    companion object {
        val OK         = HttpStatus(200)
        val NOT_FOUND  = HttpStatus(404)
        val SERVER_ERR = HttpStatus(500)
    }

    override fun toString() = "HTTP $code"
}

// ----- Boxing scenarios to be aware of -------------------------------------
// Value class IS boxed when used as:
//   - A nullable type: Metres? (must represent null somehow)
//   - A generic type: Box<Metres>
//   - An interface type: Displayable (from Temperature above)
//
// Value class is NOT boxed when used as:
//   - A non-nullable concrete type parameter
//   - A local variable
//   - A function parameter/return type (mostly)

fun boxingDemo() {
    // Not boxed — direct double at runtime
    val a = Metres(5.0)
    val b = Metres(3.0)
    val c = a + b
    println(c)

    // Boxed — nullable forces a wrapper
    val nullable: Metres? = if (true) Metres(1.0) else null
    println(nullable)

    // Boxed — generic container
    val box: List<Metres> = listOf(Metres(1.0), Metres(2.0))
    println(box)
}

fun main() {
    setDimensions(Metres(1.8), Kilograms(75.0))

    val t = Temperature(100.0)
    println(t.display())

    val email = Email("user@example.com")
    println(email.domain)

    println(HttpStatus.OK.isSuccess)
    println(HttpStatus.NOT_FOUND.isClientError)
    println(HttpStatus(201))

    println(fetchOrder(OrderId(99)))

    boxingDemo()
}
