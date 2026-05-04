// ============================================================
// Sealed Classes and Sealed Interfaces
// ============================================================
// A sealed type restricts its subclass hierarchy to the same package
// (Kotlin 1.5+: same package; before 1.5: same file).
// This makes `when` expressions exhaustive — the compiler knows all cases.

// ----- Sealed class ---------------------------------------------------------
// All direct subclasses must be in the same package.
// Can have state, abstract members, and shared logic.

sealed class NetworkResult<out T> {
    // Successful response with payload
    data class Success<T>(val data: T, val statusCode: Int = 200) : NetworkResult<T>()

    // Structured error with metadata
    data class Error(
        val message: String,
        val statusCode: Int,
        val cause: Throwable? = null
    ) : NetworkResult<Nothing>()

    // Loading state (singleton — no data needed)
    object Loading : NetworkResult<Nothing>()

    // Timeout as its own case (allows specific handling)
    data class Timeout(val durationMs: Long) : NetworkResult<Nothing>()
}

// `when` is exhaustive on sealed types — no `else` needed
fun <T> NetworkResult<T>.describe(): String = when (this) {
    is NetworkResult.Success  -> "Success(${statusCode}): $data"
    is NetworkResult.Error    -> "Error(${statusCode}): $message"
    NetworkResult.Loading     -> "Loading…"
    is NetworkResult.Timeout  -> "Timeout after ${durationMs}ms"
}

// Extension that works like Rust's Result::map
fun <T, R> NetworkResult<T>.map(transform: (T) -> R): NetworkResult<R> = when (this) {
    is NetworkResult.Success  -> NetworkResult.Success(transform(data), statusCode)
    is NetworkResult.Error    -> this   // Error has out=Nothing, covariant
    NetworkResult.Loading     -> NetworkResult.Loading
    is NetworkResult.Timeout  -> this
}

// ----- Sealed interfaces (Kotlin 1.5+) -------------------------------------
// Sealed interfaces can be implemented by classes AND data objects,
// making them ideal for state machines and event hierarchies.

sealed interface UiState {
    object Idle : UiState
    object Loading : UiState
    data class Content(val items: List<String>) : UiState
    data class Error(val message: String, val retryable: Boolean = true) : UiState
}

// State machine reducer — exhaustive when
fun reduce(state: UiState, event: UiEvent): UiState = when (event) {
    UiEvent.Load          -> UiState.Loading
    UiEvent.Retry         -> UiState.Loading
    is UiEvent.DataLoaded -> UiState.Content(event.items)
    is UiEvent.Failed     -> UiState.Error(event.reason)
    UiEvent.Reset         -> UiState.Idle
}

sealed interface UiEvent {
    object Load : UiEvent
    object Retry : UiEvent
    object Reset : UiEvent
    data class DataLoaded(val items: List<String>) : UiEvent
    data class Failed(val reason: String) : UiEvent
}

// ----- Sealed class with shared behavior ------------------------------------

sealed class Expr {
    abstract fun eval(): Double

    data class Num(val value: Double) : Expr() {
        override fun eval() = value
    }
    data class Add(val left: Expr, val right: Expr) : Expr() {
        override fun eval() = left.eval() + right.eval()
    }
    data class Mul(val left: Expr, val right: Expr) : Expr() {
        override fun eval() = left.eval() * right.eval()
    }
    data class Neg(val expr: Expr) : Expr() {
        override fun eval() = -expr.eval()
    }
}

// Visitor-style as extension (no need for the Visitor pattern boilerplate)
fun Expr.prettyPrint(): String = when (this) {
    is Expr.Num -> value.toString()
    is Expr.Add -> "(${left.prettyPrint()} + ${right.prettyPrint()})"
    is Expr.Mul -> "(${left.prettyPrint()} * ${right.prettyPrint()})"
    is Expr.Neg -> "-(${expr.prettyPrint()})"
}

// ----- Exhaustiveness ensures correctness -----------------------------------
// If you add a new subclass, every `when` without `else` becomes a compile error.
// This is sealed's killer feature over open class hierarchies.

// Example of handling unrecognized cases at API boundary
fun parseApiStatus(code: Int): NetworkResult<String> = when (code) {
    200  -> NetworkResult.Success("OK")
    404  -> NetworkResult.Error("Not found", 404)
    408  -> NetworkResult.Timeout(30_000)
    else -> NetworkResult.Error("Unexpected status", code)
}

fun main() {
    val results: List<NetworkResult<String>> = listOf(
        NetworkResult.Success("Hello"),
        NetworkResult.Error("Not found", 404),
        NetworkResult.Loading,
        NetworkResult.Timeout(5000)
    )
    results.forEach { println(it.describe()) }

    println()

    // map — transforms only the Success case
    val mapped = NetworkResult.Success(42).map { it.toString() }
    println(mapped)

    println()

    // State machine
    var state: UiState = UiState.Idle
    val events = listOf(
        UiEvent.Load,
        UiEvent.DataLoaded(listOf("item1", "item2")),
        UiEvent.Reset
    )
    events.forEach { event ->
        state = reduce(state, event)
        println("After $event → $state")
    }

    println()

    // Expression tree
    val expr: Expr = Expr.Add(
        Expr.Mul(Expr.Num(2.0), Expr.Num(3.0)),
        Expr.Neg(Expr.Num(4.0))
    )
    println(expr.prettyPrint())  // ((2.0 * 3.0) + -(4.0))
    println(expr.eval())         // 2.0
}
