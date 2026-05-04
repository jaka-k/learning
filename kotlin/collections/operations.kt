// ============================================================
// Collections — Kotlin Standard Library Operations
// ============================================================
// Kotlin distinguishes Mutable vs Immutable collection interfaces.
// List<T> is read-only; MutableList<T> adds mutation.
// Note: read-only ≠ immutable — the underlying data may still change
// if the reference is cast to a mutable type (shared mutability problem).

data class Person(val name: String, val age: Int, val city: String)

val people = listOf(
    Person("Alice", 30, "NYC"),
    Person("Bob", 25, "LA"),
    Person("Carol", 35, "NYC"),
    Person("Dave", 28, "LA"),
    Person("Eve", 22, "Chicago"),
    Person("Frank", 40, "NYC")
)

// ----- Transformations -------------------------------------------------------

fun transformations() {
    // map — transform each element
    val names = people.map { it.name }
    println(names)

    // mapIndexed — includes the index
    val indexed = people.mapIndexed { i, p -> "$i: ${p.name}" }
    println(indexed)

    // mapNotNull — map + filter null results in one step
    val parsed = listOf("1", "two", "3", "four").mapNotNull { it.toIntOrNull() }
    println(parsed)   // [1, 3]

    // flatMap — each element produces a list, results are flattened
    val letters = listOf("abc", "de", "f").flatMap { it.toList() }
    println(letters)   // [a, b, c, d, e, f]

    // flatten — one level of nesting removed
    val nested = listOf(listOf(1, 2), listOf(3, 4), listOf(5))
    println(nested.flatten())

    // associate — build a Map from a list
    val nameToAge: Map<String, Int> = people.associate { it.name to it.age }
    println(nameToAge)

    // associateBy — key is extracted from element, value is the element
    val byName: Map<String, Person> = people.associateBy { it.name }
    println(byName["Alice"])

    // zip — combine two lists pairwise
    val a = listOf(1, 2, 3)
    val b = listOf("one", "two", "three")
    println(a.zip(b))            // [(1, one), (2, two), (3, three)]
    println(a.zip(b) { n, s -> "$n=$s" })  // with transform

    // unzip — split list of pairs
    val (nums, strs) = listOf(1 to "a", 2 to "b", 3 to "c").unzip()
    println("$nums | $strs")
}

// ----- Filtering -------------------------------------------------------------

fun filtering() {
    println(people.filter { it.age >= 30 })
    println(people.filterNot { it.city == "NYC" })

    // partition — split into (matching, not-matching) pair
    val (nycPeople, others) = people.partition { it.city == "NYC" }
    println("NYC: ${nycPeople.map { it.name }}")
    println("Others: ${others.map { it.name }}")

    // take/drop — first/last N elements
    println(people.take(2).map { it.name })
    println(people.drop(4).map { it.name })
    println(people.takeLast(2).map { it.name })

    // takeWhile/dropWhile — based on predicate (stops at first mismatch)
    println(listOf(1, 2, 3, 4, 5, 1, 2).takeWhile { it < 4 })   // [1, 2, 3]
    println(listOf(1, 2, 3, 4, 5, 1, 2).dropWhile { it < 4 })   // [4, 5, 1, 2]

    // distinct / distinctBy
    println(listOf(1, 2, 2, 3, 1, 4).distinct())
    println(people.distinctBy { it.city }.map { it.city })
}

// ----- Aggregations ---------------------------------------------------------

fun aggregations() {
    println(people.count { it.age > 25 })
    println(people.sumOf { it.age })
    println(people.minByOrNull { it.age }?.name)
    println(people.maxByOrNull { it.age }?.name)
    println(people.averageBy { it.age.toDouble() })  // stdlib 1.7+

    // fold — accumulate with initial value (explicit seed)
    val totalAge = people.fold(0) { acc, p -> acc + p.age }
    println("Total age: $totalAge")

    // reduce — like fold but uses first element as seed (throws on empty)
    val sumAges = people.map { it.age }.reduce { acc, a -> acc + a }
    println("Sum: $sumAges")

    // any / all / none — short-circuiting predicates
    println(people.any { it.age < 25 })    // true (Eve is 22)
    println(people.all { it.age >= 18 })   // true
    println(people.none { it.age > 100 })  // true
}

// Workaround for missing averageBy in older stdlib
fun <T> Iterable<T>.averageBy(selector: (T) -> Double): Double {
    var sum = 0.0; var count = 0
    for (e in this) { sum += selector(e); count++ }
    return if (count == 0) Double.NaN else sum / count
}

// ----- Grouping -------------------------------------------------------------

fun grouping() {
    // groupBy — Map<K, List<V>>
    val byCity: Map<String, List<Person>> = people.groupBy { it.city }
    byCity.forEach { (city, residents) ->
        println("$city: ${residents.map { it.name }}")
    }

    // groupingBy + aggregate — more efficient for multiple aggregations
    val countByCity = people.groupingBy { it.city }.eachCount()
    println(countByCity)

    val avgAgeByCity = people
        .groupBy { it.city }
        .mapValues { (_, residents) -> residents.averageBy { it.age.toDouble() } }
    println(avgAgeByCity)
}

// ----- Sorting --------------------------------------------------------------

fun sorting() {
    println(people.sortedBy { it.age })
    println(people.sortedByDescending { it.age })

    // Multi-key sort via compareBy
    val sorted = people.sortedWith(compareBy({ it.city }, { it.age }))
    sorted.forEach { println("${it.city} / ${it.name} (${it.age})") }

    // thenBy for secondary/tertiary sort
    val comparator = compareByDescending<Person> { it.age }
        .thenBy { it.name }
    println(people.sortedWith(comparator).map { it.name })
}

// ----- Set and Map operations -----------------------------------------------

fun setAndMap() {
    val a = setOf(1, 2, 3, 4)
    val b = setOf(3, 4, 5, 6)

    println(a intersect b)    // {3, 4}
    println(a union b)        // {1, 2, 3, 4, 5, 6}
    println(a subtract b)     // {1, 2}

    val map = mapOf("a" to 1, "b" to 2, "c" to 3)

    // Map filtering
    println(map.filter { (_, v) -> v > 1 })

    // Map transformation
    println(map.mapValues { (_, v) -> v * 10 })
    println(map.mapKeys { (k, _) -> k.uppercase() })

    // getOrDefault / getOrElse
    println(map.getOrDefault("z", -1))
    println(map.getOrElse("z") { 99 })

    // merge maps — putAll / + operator
    val merged = map + mapOf("d" to 4, "a" to 99)   // later values win
    println(merged)
}

// ----- Chunking and windowing -----------------------------------------------

fun chunksAndWindows() {
    val nums = (1..10).toList()

    // chunked — split into groups of N
    println(nums.chunked(3))   // [[1,2,3],[4,5,6],[7,8,9],[10]]

    // windowed — sliding window
    println(nums.windowed(3))          // [[1,2,3],[2,3,4],...]
    println(nums.windowed(3, step = 2)) // [[1,2,3],[3,4,5],...]
    println(nums.windowed(3, partialWindows = true).last())  // [9, 10]
}

fun main() {
    println("=== Transformations ===")
    transformations()

    println("\n=== Filtering ===")
    filtering()

    println("\n=== Aggregations ===")
    aggregations()

    println("\n=== Grouping ===")
    grouping()

    println("\n=== Sorting ===")
    sorting()

    println("\n=== Set/Map ===")
    setAndMap()

    println("\n=== Chunks/Windows ===")
    chunksAndWindows()
}
