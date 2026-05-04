// ============================================================
// Scope Functions: let, run, with, apply, also
// ============================================================
// All five execute a block with a given object. They differ in two axes:
//
//   How the object is accessed inside the block:
//     - `this` (implicit receiver): run, with, apply
//     - `it`  (lambda argument):    let, also
//
//   What they return:
//     - The lambda result:  let, run, with
//     - The receiver:       apply, also
//
// Quick cheat-sheet:
//   let   → it  → result     (null check + transform)
//   run   → this → result    (object config + compute result)
//   with  → this → result    (non-extension, object operations)
//   apply → this → receiver  (object initialisation)
//   also  → it  → receiver   (side effects, debugging)

data class User(
    var name: String = "",
    var email: String = "",
    var age: Int = 0,
    var active: Boolean = false
)

// ----- let ------------------------------------------------------------------
// Canonical use: null-safety transformation chain
// The object is available as `it`. Returns the lambda result.

fun letExamples() {
    val name: String? = "alice"

    // Runs the block only if name != null; result is Int?
    val length: Int? = name?.let { it.length }
    println(length)   // 5

    // Chain: transform and return a new type
    val upper = name?.let { it.uppercase() }?.let { "[$it]" }
    println(upper)    // [ALICE]

    // `let` on non-nullable for scoped temp variable (avoid `run` confusion)
    val result = listOf(1, 2, 3, 4, 5).let { list ->
        val evens = list.filter { it % 2 == 0 }
        evens.sum()   // returned from let
    }
    println(result)   // 6
}

// ----- run ------------------------------------------------------------------
// Like `let` but object is `this`. Returns the lambda result.
// Also works as a standalone (no receiver) to create a local scope.

fun runExamples() {
    val user = User()

    // Run a block on an object, return a value
    val greeting = user.run {
        name = "Bob"   // this.name
        email = "bob@example.com"
        "Hello, $name!"   // returned
    }
    println(greeting)

    // Standalone run — scoped block, avoids polluting surrounding scope
    val answer = run {
        val x = 6
        val y = 7
        x * y   // returned
    }
    println(answer)   // 42
}

// ----- with -----------------------------------------------------------------
// Non-extension function. `with(obj) { ... }` — object is `this`.
// Typically used when you need to call multiple functions on an object.
// Returns the lambda result.

fun withExamples() {
    val sb = StringBuilder()
    val result = with(sb) {
        append("Hello")
        append(", ")
        append("World!")
        toString()   // returned from `with`
    }
    println(result)
}

// ----- apply ----------------------------------------------------------------
// Like `run` but returns THE RECEIVER (not the lambda result).
// Canonical use: object initialization / builder pattern.
// The object is available as `this`.

fun applyExamples() {
    // Builder pattern without a real builder class
    val user = User().apply {
        name = "Carol"
        email = "carol@example.com"
        age = 28
        active = true
    }
    println(user)

    // Chaining apply calls
    val list = mutableListOf<Int>()
        .apply { addAll(1..5) }
        .apply { removeIf { it % 2 == 0 } }
    println(list)   // [1, 3, 5]
}

// ----- also -----------------------------------------------------------------
// Like `let` but returns THE RECEIVER. Object available as `it`.
// Canonical use: side effects (logging, debugging) in a chain.

fun alsoExamples() {
    val user = User()
        .apply {
            name = "Dave"
            email = "dave@example.com"
            age = 35
        }
        .also { println("Created user: ${it.name}") }  // side effect
        .also { require(it.age >= 0) { "Age must be non-negative" } }

    println(user)
}

// ----- Choosing the right scope function -----------------------------------
//
// Q: Do I need the return value to be the receiver (for chaining)?
//   YES → apply (this) or also (it)
//   NO  → let (it), run (this), with (non-ext, this)
//
// Q: Do I need to refer to the object by `it` or `this`?
//   `this` (can omit qualifier): apply, run, with  — best for config/init
//   `it`   (explicit name ok):   let, also          — best when return type differs
//
// Common patterns:
//   Null check + transform:   obj?.let { ... }
//   Object construction:      Foo().apply { ... }
//   Side effect in chain:     .also { log(it) }
//   Compute from object:      obj.run { ... } or with(obj) { ... }

// ----- takeIf and takeUnless ------------------------------------------------
// Not scope functions, but related: return the receiver or null based on predicate

fun takeIfExamples() {
    val number = 42

    // Returns number if predicate true, else null
    val even = number.takeIf { it % 2 == 0 }
    println(even)   // 42

    // Returns number if predicate false, else null
    val odd = number.takeUnless { it % 2 == 0 }
    println(odd)    // null

    // Useful to guard: parse then takeIf it's in range
    val input = "255"
    val byte = input.toIntOrNull()?.takeIf { it in 0..255 }
    println(byte)   // 255
}

fun main() {
    println("--- let ---")
    letExamples()

    println("\n--- run ---")
    runExamples()

    println("\n--- with ---")
    withExamples()

    println("\n--- apply ---")
    applyExamples()

    println("\n--- also ---")
    alsoExamples()

    println("\n--- takeIf / takeUnless ---")
    takeIfExamples()
}
