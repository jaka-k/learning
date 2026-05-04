// ============================================================
// Class Delegation and Property Delegation
// ============================================================

// ----- Class delegation (by keyword) ----------------------------------------
// Kotlin natively supports the Delegation pattern.
// `class Foo(impl: Bar) : Bar by impl` — the compiler generates all
// Bar interface methods forwarding to `impl`. No boilerplate.

interface Logger {
    fun log(msg: String)
    fun warn(msg: String) = log("[WARN] $msg")   // default — inherited
}

class ConsoleLogger : Logger {
    override fun log(msg: String) = println("[LOG] $msg")
}

class FileLogger(val path: String) : Logger {
    override fun log(msg: String) = println("[FILE:$path] $msg")
}

// ClassWithLogging delegates ALL Logger methods to `logger`.
// We can still override individual methods if needed.
class Service(logger: Logger) : Logger by logger {
    // Override only what differs
    override fun log(msg: String) {
        println("[Service] $msg")
    }
    // warn() still comes from the delegate's default implementation via ConsoleLogger
}

// Mixin pattern: combine multiple behaviours via delegation
interface Persistable {
    fun save(): String
    fun load(data: String)
}

interface Cacheable {
    fun invalidate()
}

class SimplePersistence : Persistable {
    private var data = ""
    override fun save() = data.also { println("Saved: $data") }
    override fun load(data: String) { this.data = data; println("Loaded: $data") }
}

class SimpleCache : Cacheable {
    override fun invalidate() = println("Cache invalidated")
}

// UserRepository inherits both interfaces with zero boilerplate
class UserRepository(
    private val persistence: Persistable = SimplePersistence(),
    private val cache: Cacheable = SimpleCache()
) : Persistable by persistence, Cacheable by cache {
    fun storeUser(name: String) {
        persistence.load(name)
        invalidate()   // from Cacheable
        save()         // from Persistable
    }
}

// ----- Property delegation (by keyword on properties) -----------------------
// `val/var foo: T by delegate` — reads/writes are forwarded to getValue/setValue
// on the delegate object (operator functions).

// The stdlib ships four important property delegates:

// 1. lazy { } — computed once on first access, then cached
//    By default thread-safe (LazyThreadSafetyMode.SYNCHRONIZED)
val expensiveValue: String by lazy {
    println("Computing expensive value…")
    "result"   // returned once and cached
}

// lazy with a different thread-safety mode
val unsafeLazy: String by lazy(LazyThreadSafetyMode.NONE) { "fast but unsafe" }

// 2. Delegates.observable — called after every assignment
import kotlin.properties.Delegates

class ViewModel {
    var name: String by Delegates.observable("<unset>") { property, old, new ->
        println("${property.name} changed: $old → $new")
    }

    // vetoable — called before assignment; return false to reject
    var age: Int by Delegates.vetoable(0) { _, old, new ->
        val accepted = new >= 0
        if (!accepted) println("Rejected age $new (must be non-negative)")
        accepted
    }
}

// 3. Delegates.notNull — like lateinit but works for val/primitives
//    Throws if read before written
var lateInt: Int by Delegates.notNull()

// 4. Map delegation — properties backed by a Map (great for configs/DTOs)
class Config(map: Map<String, Any?>) {
    val host: String     by map
    val port: Int        by map
    val debug: Boolean   by map
}

// ----- Custom property delegate ---------------------------------------------
// Implement getValue (and setValue for var) with operator keyword.
// Can be a class or an object.

import kotlin.reflect.KProperty

// Delegate that logs every read and write
class LoggedProperty<T>(private var value: T) {
    operator fun getValue(thisRef: Any?, property: KProperty<*>): T {
        println("Reading ${property.name} = $value")
        return value
    }
    operator fun setValue(thisRef: Any?, property: KProperty<*>, newValue: T) {
        println("Writing ${property.name}: $value → $newValue")
        value = newValue
    }
}

class DataModel {
    var count: Int by LoggedProperty(0)
    var title: String by LoggedProperty("untitled")
}

// Delegate factory via provideDelegate — runs at init time, can validate
class PositiveInt(initial: Int) {
    private var value = initial.also { require(it > 0) { "Must be positive" } }

    operator fun getValue(thisRef: Any?, property: KProperty<*>): Int = value
    operator fun setValue(thisRef: Any?, property: KProperty<*>, v: Int) {
        require(v > 0) { "${property.name} must be positive" }
        value = v
    }
}

class Rectangle {
    var width:  Int by PositiveInt(100)
    var height: Int by PositiveInt(50)
}

fun main() {
    println("--- Class delegation ---")
    val svc = Service(ConsoleLogger())
    svc.log("Hello from service")
    svc.warn("Something odd")

    val repo = UserRepository()
    repo.storeUser("Alice")

    println("\n--- lazy ---")
    println(expensiveValue)   // prints "Computing…" then the value
    println(expensiveValue)   // cached — no recomputation

    println("\n--- observable / vetoable ---")
    val vm = ViewModel()
    vm.name = "Alice"
    vm.name = "Bob"
    vm.age  = 25
    vm.age  = -1    // rejected

    println("\n--- Map delegation ---")
    val config = Config(mapOf("host" to "localhost", "port" to 5432, "debug" to true))
    println("${config.host}:${config.port} debug=${config.debug}")

    println("\n--- Custom delegate ---")
    val model = DataModel()
    model.count = 5
    println(model.count)
    model.title = "My Title"

    println("\n--- PositiveInt delegate ---")
    val rect = Rectangle()
    println("${rect.width} x ${rect.height}")
    rect.width = 200
    // rect.width = -1  // throws IllegalArgumentException
}
