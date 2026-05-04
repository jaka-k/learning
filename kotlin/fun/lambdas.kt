// ============================================================
// Lambdas and Function Types
// ============================================================

// Function types are written as (ParamTypes) -> ReturnType
// They are real types — can be stored, passed, returned

// Higher-order function: accepts a function as parameter
fun transform(list: List<Int>, fn: (Int) -> Int): List<Int> = list.map(fn)

// Function type with receiver: (T) -> R called on a receiver of type T
// Inside the lambda, `this` refers to the receiver
fun buildString(init: StringBuilder.() -> Unit): String {
    val sb = StringBuilder()
    sb.init()   // call the extension lambda on sb
    return sb.toString()
}

// Returning a function — the return type is a function type
fun multiplier(factor: Int): (Int) -> Int = { x -> x * factor }

// Nullable function type — the whole type is nullable, not just the param
fun runIfPresent(fn: (() -> Unit)?) {
    fn?.invoke()  // safe call on nullable function reference
}

// Function type with multiple params and named labels (just for docs)
typealias Reducer<S, A> = (state: S, action: A) -> S

// ----- Lambda syntax variants -----------------------------------------------

fun lambdaSyntax() {
    // Full explicit form
    val double: (Int) -> Int = { x: Int -> x * 2 }

    // Type inferred from variable declaration
    val triple: (Int) -> Int = { x -> x * 3 }

    // `it` — implicit single-parameter name (use sparingly for clarity)
    val negate: (Int) -> Int = { -it }

    // Multi-line lambda — last expression is the return value
    val classify: (Int) -> String = { n ->
        when {
            n < 0    -> "negative"
            n == 0   -> "zero"
            n < 100  -> "small"
            else     -> "large"
        }
    }

    println(double(5))
    println(triple(5))
    println(negate(5))
    println(classify(-3))
}

// ----- Trailing lambda syntax -----------------------------------------------
// When the last parameter is a function, the lambda can be moved outside ()
// If it's the only parameter, () can be dropped entirely

fun repeat(n: Int, action: (Int) -> Unit) {
    for (i in 0 until n) action(i)
}

fun trailingLambda() {
    repeat(3) { i -> println("iteration $i") }  // trailing lambda

    // buildString uses a receiver lambda — `this` is the StringBuilder
    val result = buildString {
        append("Hello")
        append(", ")
        append("World")
    }
    println(result)
}

// ----- Closures and captured variables -------------------------------------
// Lambdas close over mutable vars in Kotlin (unlike Java which requires
// effectively-final). The compiler wraps the var in a Ref object.

fun closureExample() {
    var count = 0
    val increment = { count++ }   // captures mutable `count`
    increment(); increment(); increment()
    println("count = $count")     // 3
}

// ----- Anonymous functions vs lambdas ----------------------------------------
// Anonymous functions use `return` to exit the function itself.
// `return` inside a lambda does a non-local return from the enclosing function
// (only allowed in inline functions). Use anonymous functions when you need
// a local return inside a non-inline higher-order function.

fun anonymousFunctionExample() {
    val isEven = fun(x: Int): Boolean {
        return x % 2 == 0   // returns from the anonymous function only
    }
    println(listOf(1, 2, 3, 4).filter(isEven))
}

// ----- Function references ---------------------------------------------------
// :: turns a named function/constructor/property into a first-class value

fun isOdd(n: Int) = n % 2 != 0

class Parser(val text: String) {
    fun parse(): List<String> = text.split(",")
}

fun references() {
    // Top-level function reference
    val filtered = listOf(1, 2, 3, 4, 5).filter(::isOdd)
    println(filtered)

    // Bound method reference — receiver is the specific instance
    val p = Parser("a,b,c")
    val parse: () -> List<String> = p::parse
    println(parse())

    // Unbound method reference — receiver passed as first argument
    val parserList = listOf(Parser("1,2"), Parser("a,b,c"))
    println(parserList.map(Parser::parse))

    // Constructor reference
    val makeParsers: (String) -> Parser = ::Parser
    println(makeParsers("x,y,z").parse())
}

// ----- Partial application / currying (manual) ------------------------------
// Kotlin doesn't have built-in currying, but it's straightforward to do

fun <A, B, C> ((A, B) -> C).partial(a: A): (B) -> C = { b -> this(a, b) }

fun partialApplication() {
    val add: (Int, Int) -> Int = { a, b -> a + b }
    val add5 = add.partial(5)   // fix the first argument
    println(add5(3))   // 8
    println(add5(10))  // 15
}

fun main() {
    lambdaSyntax()
    trailingLambda()
    closureExample()
    anonymousFunctionExample()
    references()
    partialApplication()

    // multiplier returns a function
    val double = multiplier(2)
    val triple = multiplier(3)
    println(transform(listOf(1, 2, 3), double))
    println(transform(listOf(1, 2, 3), triple))
}
