// ============================================================
// Null Safety — Kotlin's Type System vs Null
// ============================================================
// In Kotlin, nullability is part of the TYPE.
//   String  — never null (non-nullable)
//   String? — may be null (nullable)
// The compiler enforces correct handling at compile time.

// ----- Nullable types and safe access ---------------------------------------

fun nullableBasics() {
    val nonNull: String = "hello"
    // val bad: String = null  // COMPILE ERROR

    val nullable: String? = null

    // Direct access on nullable is an error:
    // println(nullable.length)  // COMPILE ERROR

    // Safe call (?.) — returns null if receiver is null, short-circuits the chain
    println(nullable?.length)       // null
    println(nullable?.uppercase()?.reversed())  // null — whole chain short-circuits

    // Elvis operator (?:) — provide a default when the left side is null
    val length = nullable?.length ?: 0
    println(length)   // 0

    // Non-null assertion (!!) — throws NullPointerException if null
    // Use SPARINGLY — defeats null safety. Acceptable in tests or when you've
    // already checked (but smart cast is better).
    val known: String? = "world"
    println(known!!.length)  // safe here, but fragile

    // Smart cast — after a null check, the type is narrowed automatically
    if (nullable != null) {
        println(nullable.length)  // smart cast: nullable is String here
    }
    // Also works with `&&`
    val result = if (nullable != null && nullable.length > 3) nullable else "short"
    println(result)
}

// ----- Elvis chain idiom ----------------------------------------------------
// Chaining multiple null-or-empty checks

data class Address(val city: String?)
data class User(val name: String, val address: Address?)

fun getCity(user: User?): String =
    user?.address?.city ?: "Unknown"

// ----- let with safe call ---------------------------------------------------
// Runs the block only if the receiver is non-null

fun sendEmail(to: String?) {
    to?.let { address ->
        println("Sending email to $address")
    } ?: println("No recipient provided")
}

// ----- Nullable collection vs collection of nullables -----------------------
// List<String>? — the list itself may be null
// List<String?>  — the list exists but elements may be null
// List<String?>? — both nullable

fun collectionNullability() {
    val nullableList: List<String>? = null
    val listWithNulls: List<String?> = listOf("a", null, "b", null, "c")

    // orEmpty() on nullable collection — returns empty list if null
    println(nullableList.orEmpty())

    // filterNotNull() removes nulls and narrows the type to List<String>
    val nonNulls: List<String> = listWithNulls.filterNotNull()
    println(nonNulls)

    // mapNotNull — map + filter in one step
    val lengths = listWithNulls.mapNotNull { it?.length }
    println(lengths)
}

// ----- Platform types (Java interop) ----------------------------------------
// When calling Java code, the return type is a "platform type" (String!)
// meaning Kotlin doesn't know if it's nullable or not.
// Assign to a typed variable immediately to assert your intent:
//
//   val name: String  = javaObject.getName()   // crash if null
//   val name: String? = javaObject.getName()   // safe
//
// Use @NotNull/@Nullable in Java to give Kotlin precise information.

// ----- Null coalescing patterns ---------------------------------------------

fun String?.blankToNull(): String? = takeIf { it?.isNotBlank() == true }

fun parsePort(input: String?): Int =
    input?.trim()?.toIntOrNull()?.takeIf { it in 1..65535 } ?: 8080

// ----- lateinit var ---------------------------------------------------------
// For non-null properties that can't be initialised in the constructor
// (e.g., DI frameworks, Android onCreate). Throws UninitializedPropertyAccessException
// if accessed before assignment — NOT a NullPointerException.

class Service {
    lateinit var repository: String   // injected later

    // Check before access to avoid the exception
    fun isInitialized() = ::repository.isInitialized

    fun run() {
        if (::repository.isInitialized) {
            println("Repository: $repository")
        } else {
            println("Repository not set")
        }
    }
}

// ----- Dealing with nulls functionally -------------------------------------

// Monad-like chaining without exceptions
fun divide(a: Int, b: Int): Int? = if (b == 0) null else a / b

fun compute(x: Int, y: Int, z: Int): Int? =
    divide(x, y)?.let { result -> divide(result, z) }

// Using `run` as an alternative to let for sequences of nullable ops
fun fetchUserName(id: Int?): String? =
    id?.run { "User#$this" }

// ----- Nothing and null -----------------------------------------------------
// `Nothing` is the bottom type — subtype of every type.
// A function returning Nothing never returns normally.
// Useful in Elvis chains to throw or fail fast:

fun requireNotEmpty(s: String?): String =
    s?.takeIf { it.isNotBlank() } ?: throw IllegalArgumentException("String must not be blank")

fun main() {
    println("--- basics ---")
    nullableBasics()

    println("\n--- nested null access ---")
    val user = User("Alice", Address(null))
    println(getCity(user))             // Unknown
    println(getCity(null))             // Unknown

    println("\n--- let + nullable ---")
    sendEmail("alice@example.com")
    sendEmail(null)

    println("\n--- collections ---")
    collectionNullability()

    println("\n--- blankToNull / parsePort ---")
    println("   ".blankToNull())       // null
    println("hello".blankToNull())     // hello
    println(parsePort("8443"))         // 8443
    println(parsePort(null))           // 8080
    println(parsePort("99999"))        // 8080 (out of range)

    println("\n--- lateinit ---")
    val svc = Service()
    svc.run()                          // not initialized
    svc.repository = "my-repo"
    svc.run()

    println("\n--- compute ---")
    println(compute(100, 5, 2))        // 10
    println(compute(100, 0, 2))        // null (divide by zero)

    println(requireNotEmpty("hello"))
}
