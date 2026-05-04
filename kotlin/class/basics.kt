// ============================================================
// Classes — Construction, Properties, Visibility
// ============================================================

// ----- Primary constructor --------------------------------------------------
// Parameters in the header; `val`/`var` turns them into properties.
class Person(
    val name: String,         // read-only property
    var age: Int,             // mutable property
    private val ssn: String   // private property
) {
    // init block runs as part of construction, after primary constructor params
    // Multiple init blocks are allowed; they run top-to-bottom.
    init {
        require(name.isNotBlank()) { "Name cannot be blank" }
        require(age >= 0)          { "Age cannot be negative" }
    }

    // Computed (derived) property — no backing field, just a getter
    val isAdult: Boolean
        get() = age >= 18

    // Property with custom getter AND setter
    var displayName: String = name
        get() = field.uppercase()          // `field` refers to backing field
        set(value) { field = value.trim() }

    // Secondary constructor — must delegate to primary via `this(...)`
    constructor(name: String) : this(name, 0, "")

    // Member function
    fun greet() = "Hi, I'm $name and I'm $age years old."

    // toString / equals / hashCode are NOT auto-generated (unlike data class)
    override fun toString() = "Person(name=$name, age=$age)"
}

// ----- Inheritance ----------------------------------------------------------
// Classes are `final` by default. Mark with `open` to allow subclassing.
// Properties and functions must also be `open` to be overridden.

open class Animal(open val name: String) {
    open fun sound(): String = "..."

    // Final override — no further overriding allowed
    final override fun toString() = "Animal($name)"
}

class Dog(override val name: String) : Animal(name) {
    override fun sound() = "Woof"
}

// ----- Abstract classes -----------------------------------------------------
abstract class Shape {
    abstract val area: Double      // subclasses must provide this
    abstract fun perimeter(): Double

    // Concrete function available to all subclasses
    fun describe() = "Area: $area, Perimeter: ${perimeter()}"
}

class Circle(val radius: Double) : Shape() {
    override val area: Double get() = Math.PI * radius * radius
    override fun perimeter() = 2 * Math.PI * radius
}

class Rectangle(val width: Double, val height: Double) : Shape() {
    override val area get() = width * height
    override fun perimeter() = 2 * (width + height)
}

// ----- Interfaces -----------------------------------------------------------
// Interfaces can have default implementations and properties (no backing field).
// A class can implement multiple interfaces.

interface Drawable {
    fun draw()
    fun resize(factor: Double) = println("Resizing by $factor")  // default impl
}

interface Printable {
    fun print() = println("Printing...")
}

class Canvas : Drawable, Printable {
    override fun draw() = println("Drawing on canvas")
    // resize() and print() are inherited defaults
}

// ----- Visibility modifiers -------------------------------------------------
// public    — visible everywhere (default)
// private   — visible inside the file/class
// protected — visible in class and subclasses
// internal  — visible within the same module (Gradle/Maven subproject)

class BankAccount(private var balance: Double) {
    internal fun getBalanceInternal() = balance  // visible in same module

    protected open fun interestRate() = 0.01

    fun deposit(amount: Double) {
        require(amount > 0)
        balance += amount
    }

    fun withdraw(amount: Double): Boolean {
        if (amount > balance) return false
        balance -= amount
        return true
    }
}

// ----- Object declarations (Singletons) -------------------------------------
// `object` creates a class with exactly one instance, created lazily.
// No constructor params allowed.

object AppConfig {
    var debug = false
    val version = "1.0.0"
    fun init() = println("Config initialized (debug=$debug)")
}

// ----- Companion objects ----------------------------------------------------
// One companion per class. Acts like Java static members but it's a real object.
// Can implement interfaces, be extended.

class ApiClient private constructor(val baseUrl: String) {
    companion object {
        // Factory method — `of` is a common Kotlin factory convention
        fun of(baseUrl: String) = ApiClient(baseUrl.trimEnd('/'))

        const val DEFAULT_TIMEOUT = 30_000   // compile-time constant (Int)

        @JvmStatic   // optional: makes it a real static method for Java callers
        fun defaultClient() = of("https://api.example.com")
    }

    fun get(path: String) = "GET $baseUrl/$path"
}

// ----- Object expressions (anonymous objects) --------------------------------
// Java equivalent of anonymous inner classes

interface ClickListener {
    fun onClick(x: Int, y: Int)
}

fun registerListener(l: ClickListener) = l.onClick(10, 20)

fun main() {
    val alice = Person("Alice", 30, "123-45-6789")
    println(alice.greet())
    println(alice.isAdult)
    alice.displayName = "  alice smith  "
    println(alice.displayName)   // ALICE SMITH (trimmed, uppercased)

    val dog = Dog("Rex")
    println("${dog.name} says ${dog.sound()}")

    val c = Circle(5.0)
    println(c.describe())

    val r = Rectangle(4.0, 6.0)
    println(r.describe())

    val canvas = Canvas()
    canvas.draw()
    canvas.resize(2.0)
    canvas.print()

    // Singleton
    AppConfig.debug = true
    AppConfig.init()

    // Companion
    val client = ApiClient.of("https://api.example.com")
    println(client.get("users"))
    println("Timeout: ${ApiClient.DEFAULT_TIMEOUT}ms")

    // Object expression — create an anonymous implementation on the fly
    registerListener(object : ClickListener {
        override fun onClick(x: Int, y: Int) = println("Clicked at ($x, $y)")
    })
}
