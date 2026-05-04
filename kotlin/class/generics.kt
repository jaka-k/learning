// ============================================================
// Generics — Variance, Bounds, Star Projections, Type Erasure
// ============================================================

// ----- Basic generics -------------------------------------------------------

class Box<T>(val value: T) {
    fun <R> map(transform: (T) -> R): Box<R> = Box(transform(value))
}

// Upper bound — T must be Comparable
fun <T : Comparable<T>> max(a: T, b: T): T = if (a >= b) a else b

// Multiple bounds — `where` clause
fun <T> stringify(value: T): String
    where T : Any,        // non-nullable
          T : Comparable<T> =
    value.toString()

// ----- Variance — in/out/invariant ------------------------------------------
//
// Variance controls type substitutability for generic types.
// Problem: if Dog : Animal, is List<Dog> a subtype of List<Animal>? No — by default.
//
// Kotlin uses DECLARATION-SITE variance (unlike Java's use-site wildcards).
//
//   out T  (covariant)     — T is only PRODUCED (returned), not consumed
//                           Box<Dog> can be used where Box<Animal> is expected
//   in  T  (contravariant) — T is only CONSUMED (accepted as param), not produced
//                           Comparator<Animal> can be used where Comparator<Dog> is expected
//   T      (invariant)     — default; neither substitution is safe (MutableList<Dog> ≠ MutableList<Animal>)

// Covariant producer — reads T, never writes T
interface Producer<out T> {
    fun produce(): T
}

// Contravariant consumer — writes T, never reads T
interface Consumer<in T> {
    fun consume(value: T)
}

// Both — invariant (MutableList is the canonical example)
interface Container<T> {
    fun get(): T
    fun put(value: T)
}

class StringProducer(private val s: String) : Producer<String> {
    override fun produce() = s
}

// Covariance in action: Producer<String> is a Producer<Any>
fun printProduced(p: Producer<Any>) = println(p.produce())

// Contravariance: Consumer<Any> can consume Strings
class Printer<in T> {
    fun print(value: T) = println(value)
}

// ----- Use-site variance (projections) --------------------------------------
// When a type is invariant but you only need to use it covariantly/contravariantly.

// `out` projection — can only read from this MutableList
fun copy(from: MutableList<out Any>, to: MutableList<Any>) {
    for (item in from) to.add(item)  // safe: only reading from `from`
    // from.add("x")  // ERROR: can't write to out projection
}

// `in` projection — can only write to this MutableList
fun fill(list: MutableList<in String>, value: String) {
    list.add(value)   // safe: only writing to `list`
}

// Star projection (*) — when the type parameter doesn't matter
fun printSize(list: List<*>) = println("Size: ${list.size}")
// List<*> is equivalent to List<out Any?> — can read as Any?, can't write

// ----- Reified generics (inline) -------------------------------------------
// Type parameters are erased at runtime. `reified` in inline functions
// preserves the type at the call site. See also: fun/inline_functions.kt

inline fun <reified T> Iterable<*>.filterIsInstanceOf(): List<T> =
    filterIsInstance<T>()   // T is real here because the function is inline

// ----- Type aliases ---------------------------------------------------------
// Aliases don't create new types — they're documentation aids

typealias Matrix<T> = List<List<T>>
typealias StringMap  = Map<String, String>
typealias Predicate<T> = (T) -> Boolean

fun <T> List<T>.where(predicate: Predicate<T>) = filter(predicate)

// ----- Generic constraints with sealed types --------------------------------
// Useful for building type-safe registries, event buses, etc.

sealed interface Command
data class CreateUser(val name: String) : Command
data class DeleteUser(val id: Long) : Command

interface Handler<in C : Command> {
    fun handle(command: C)
}

class CreateUserHandler : Handler<CreateUser> {
    override fun handle(command: CreateUser) = println("Creating ${command.name}")
}

// ----- Phantom types — encode state in the type system ----------------------
// T is never used at runtime, but prevents misuse at compile time

class StateMachine<State> private constructor(val current: String) {
    companion object {
        fun <S> initial(state: String) = StateMachine<S>(state)
    }

    fun <NewState> transition(newState: String): StateMachine<NewState> =
        StateMachine(newState)
}

sealed interface States {
    interface Idle
    interface Running
    interface Stopped
}

fun demonstratePhantomTypes() {
    val idle: StateMachine<States.Idle> = StateMachine.initial("idle")
    val running: StateMachine<States.Running> = idle.transition("running")
    println("${idle.current} → ${running.current}")
    // val bad: StateMachine<States.Stopped> = idle  // COMPILE ERROR — type mismatch
}

// ----- Variance with function types ----------------------------------------
// (A) -> B is contravariant in A, covariant in B
// This is the Liskov Substitution Principle expressed in types.

fun higherOrderVariance() {
    // A function that accepts Any can serve as a function that accepts String
    val anyToString: (Any) -> String = { it.toString() }
    val stringToString: (String) -> String = anyToString  // contravariance in input

    // A function that returns String can serve as a function that returns Any
    val stringFn: () -> String = { "hello" }
    val anyFn: () -> Any = stringFn   // covariance in output

    println(stringToString("hello"))
    println(anyFn())
}

fun main() {
    val box = Box(42)
    val strBox = box.map { it.toString() }
    println(strBox.value)

    println(max(3, 7))
    println(max("apple", "banana"))

    // Covariance: Producer<String> usable as Producer<Any>
    val sp = StringProducer("hello")
    printProduced(sp)   // works because Producer<out T>

    // Contravariance: Printer<Any> usable for Strings
    val anyPrinter: Printer<Any> = Printer()
    val strPrinter: Printer<String> = anyPrinter   // works because Printer<in T>
    strPrinter.print("Kotlin!")

    // Copy with out projection
    val dogs = mutableListOf<String>("Rex", "Buddy")  // imagine List<Dog>
    val animals = mutableListOf<Any>()
    copy(dogs, animals)
    println(animals)

    val mixed: List<Any> = listOf(1, "two", 3.0, "four", 5)
    println(mixed.filterIsInstanceOf<String>())

    val numbers = listOf(1, 2, 3, 4, 5, 6)
    println(numbers.where { it % 2 == 0 })

    demonstratePhantomTypes()

    higherOrderVariance()
}
