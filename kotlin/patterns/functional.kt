// ============================================================
// Functional Programming Patterns in Kotlin
// ============================================================

// ----- Functor (map) --------------------------------------------------------
// A type that can apply a function to its contents.
// Kotlin's nullable, List, Sequence, Flow all behave as functors via map().

// Custom Maybe monad (illustrative — use nullable instead in real code)
sealed class Maybe<out A> {
    object Nothing_ : Maybe<Nothing>()
    data class Just<A>(val value: A) : Maybe<A>()

    fun <B> map(f: (A) -> B): Maybe<B> = when (this) {
        is Nothing_ -> Nothing_
        is Just     -> Just(f(value))
    }

    fun <B> flatMap(f: (A) -> Maybe<B>): Maybe<B> = when (this) {
        is Nothing_ -> Nothing_
        is Just     -> f(value)
    }

    fun getOrElse(default: @UnsafeVariance A): A = when (this) {
        is Nothing_ -> default
        is Just     -> value
    }
}

fun <A> maybeOf(value: A?): Maybe<A> = if (value == null) Maybe.Nothing_ else Maybe.Just(value)

// ----- Either (error handling without exceptions) --------------------------
// Either<L, R> — conventionally Left = error, Right = success

sealed class Either<out L, out R> {
    data class Left<L>(val value: L) : Either<L, Nothing>()
    data class Right<R>(val value: R) : Either<Nothing, R>()

    val isRight get() = this is Right
    val isLeft  get() = this is Left

    fun <T> map(f: (R) -> T): Either<L, T> = when (this) {
        is Left  -> this
        is Right -> Right(f(value))
    }

    fun <T> flatMap(f: (R) -> Either<@UnsafeVariance L, T>): Either<L, T> = when (this) {
        is Left  -> this
        is Right -> f(value)
    }

    fun mapLeft(f: (L) -> @UnsafeVariance L): Either<L, R> = when (this) {
        is Left  -> Left(f(value))
        is Right -> this
    }

    fun fold(onLeft: (L) -> Unit, onRight: (R) -> Unit) = when (this) {
        is Left  -> onLeft(value)
        is Right -> onRight(value)
    }

    fun getOrElse(default: @UnsafeVariance R): R = when (this) {
        is Left  -> default
        is Right -> value
    }
}

typealias AppError = String
typealias AppResult<T> = Either<AppError, T>

fun parseAge(input: String): AppResult<Int> {
    val n = input.toIntOrNull() ?: return Either.Left("'$input' is not a number")
    return if (n in 0..150) Either.Right(n) else Either.Left("Age $n is out of range")
}

fun classifyAge(age: Int): AppResult<String> = Either.Right(
    when {
        age < 18  -> "minor"
        age < 65  -> "adult"
        else      -> "senior"
    }
)

// Railway-oriented programming — chain operations, errors propagate left
fun processAge(input: String): AppResult<String> =
    parseAge(input).flatMap { classifyAge(it) }

// ----- Memoization ----------------------------------------------------------
// Cache pure function results for the same inputs

fun <A, B> memoize(fn: (A) -> B): (A) -> B {
    val cache = mutableMapOf<A, B>()
    return { a -> cache.getOrPut(a) { fn(a) } }
}

val memoFib: (Int) -> Long by lazy {
    memoize { n: Int ->
        when {
            n <= 0 -> 0L
            n == 1 -> 1L
            else   -> memoFib(n - 1) + memoFib(n - 2)
        }
    }
}

// ----- Currying and partial application -------------------------------------

fun <A, B, C> ((A, B) -> C).curry(): (A) -> (B) -> C = { a -> { b -> this(a, b) } }

fun <A, B, C> ((A, B) -> C).partial(a: A): (B) -> C = { b -> this(a, b) }

fun curryingDemo() {
    val add: (Int, Int) -> Int = { a, b -> a + b }
    val curriedAdd = add.curry()
    val add5 = curriedAdd(5)

    println(add5(3))   // 8
    println(add5(10))  // 15

    val greet: (String, String) -> String = { greeting, name -> "$greeting, $name!" }
    val hello = greet.partial("Hello")
    println(hello("Alice"))
    println(hello("Bob"))
}

// ----- Function composition -------------------------------------------------

infix fun <A, B, C> ((A) -> B).andThen(f: (B) -> C): (A) -> C = { a -> f(this(a)) }
infix fun <A, B, C> ((B) -> C).compose(f: (A) -> B): (A) -> C = { a -> this(f(a)) }

fun compositionDemo() {
    val trim: (String) -> String   = String::trim
    val lower: (String) -> String  = String::lowercase
    val splitWords: (String) -> List<String> = { it.split(" ") }

    val normalize = trim andThen lower andThen splitWords
    println(normalize("  Hello World  "))   // [hello, world]
}

// ----- Monadic pipelines with Result ----------------------------------------
// Kotlin stdlib has Result<T>; let's build a pipeline with it

fun safeDivide(a: Int, b: Int): Result<Int> =
    if (b == 0) Result.failure(ArithmeticException("Division by zero"))
    else Result.success(a / b)

fun pipelineDemo() {
    val result = safeDivide(100, 5)
        .map { it * 2 }
        .mapCatching { check(it < 100) { "Too large: $it" }; it }
        .recover { e -> -1 }  // fallback on failure

    println(result)  // Success(40)

    val bad = safeDivide(10, 0)
        .map { it * 2 }
        .recover { -1 }
    println(bad)  // Success(-1)
}

// ----- Algebraic utilities --------------------------------------------------

// Fold over Either-like results
fun <T, R> List<T>.traverseEither(f: (T) -> Either<AppError, R>): Either<AppError, List<R>> {
    val results = mutableListOf<R>()
    for (item in this) {
        when (val result = f(item)) {
            is Either.Left  -> return result   // fail fast
            is Either.Right -> results.add(result.value)
        }
    }
    return Either.Right(results)
}

// Collect all errors rather than failing fast
fun <T, R> List<T>.validateAll(f: (T) -> Either<AppError, R>): Either<List<AppError>, List<R>> {
    val errors = mutableListOf<AppError>()
    val successes = mutableListOf<R>()
    for (item in this) {
        when (val result = f(item)) {
            is Either.Left  -> errors.add(result.value)
            is Either.Right -> successes.add(result.value)
        }
    }
    return if (errors.isEmpty()) Either.Right(successes) else Either.Left(errors)
}

fun main() {
    println("=== Maybe monad ===")
    val result = maybeOf("42")
        .map { it.toIntOrNull() }
        .flatMap { maybeOf(it) }
        .map { it * 2 }
        .getOrElse(0)
    println(result)   // 84

    println("\n=== Either / Railway oriented ===")
    println(processAge("25"))    // Right(adult)
    println(processAge("200"))   // Left(Age 200 is out of range)
    println(processAge("abc"))   // Left('abc' is not a number)

    println("\n=== Memoized fibonacci ===")
    println((0..10).map { memoFib(it) })

    println("\n=== Currying ===")
    curryingDemo()

    println("\n=== Composition ===")
    compositionDemo()

    println("\n=== Result pipeline ===")
    pipelineDemo()

    println("\n=== Traverse Either ===")
    val inputs = listOf("20", "35", "42")
    println(inputs.traverseEither { parseAge(it) })

    val badInputs = listOf("20", "abc", "999")
    println(badInputs.traverseEither { parseAge(it) })  // first error

    println("\n=== Validate all ===")
    println(badInputs.validateAll { parseAge(it) })  // all errors collected
}
