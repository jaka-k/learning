// ============================================================
// Building DSLs in Kotlin
// ============================================================
// Kotlin's type system and features enable expressive internal DSLs:
//   - Extension functions with receivers
//   - Infix functions
//   - Lambda with receiver (function types like T.() -> Unit)
//   - Operator overloading
//   - @DslMarker to prevent scope leakage

// ----- @DslMarker -----------------------------------------------------------
// Without DslMarker, `this` inside a nested builder can accidentally refer
// to an outer builder, silently calling the wrong function.
// DslMarker prevents calling a builder method from a different scope's receiver.

@DslMarker
annotation class HtmlDsl

// ----- HTML Builder DSL -----------------------------------------------------

@HtmlDsl
abstract class Tag(val name: String) {
    protected val children = mutableListOf<Tag>()
    protected val attributes = mutableMapOf<String, String>()

    fun attr(key: String, value: String) { attributes[key] = value }

    protected fun render(indent: Int): String = buildString {
        val pad = " ".repeat(indent)
        val attrs = if (attributes.isEmpty()) ""
                    else attributes.entries.joinToString(" ", prefix = " ") { (k, v) -> """$k="$v"""" }
        append("$pad<$name$attrs>")
        if (children.isEmpty()) {
            append("</$name>")
        } else {
            appendLine()
            children.forEach { appendLine(it.render(indent + 2)) }
            append("$pad</$name>")
        }
    }

    override fun toString() = render(0)
}

@HtmlDsl
class TextTag(private val text: String) : Tag("__text__") {
    override fun toString() = text
}

@HtmlDsl
class Div : Tag("div") {
    fun div(init: Div.() -> Unit) = Div().also { it.init(); children.add(it) }
    fun p(init: P.() -> Unit) = P().also { it.init(); children.add(it) }
    fun h1(text: String) { children.add(H1(text)) }
}

@HtmlDsl
class P : Tag("p") {
    operator fun String.unaryPlus() { children.add(TextTag(this)) }
}

@HtmlDsl
class H1(text: String) : Tag("h1") {
    init { children.add(TextTag(text)) }
}

@HtmlDsl
class Html : Tag("html") {
    fun body(init: Body.() -> Unit) = Body().also { it.init(); children.add(it) }
}

@HtmlDsl
class Body : Tag("body") {
    fun div(init: Div.() -> Unit) = Div().also { it.init(); children.add(it) }
    fun h1(text: String) { children.add(H1(text)) }
}

// Entry point for the DSL
fun html(init: Html.() -> Unit): Html = Html().apply(init)

// ----- Configuration DSL ----------------------------------------------------

@DslMarker
annotation class ConfigDsl

@ConfigDsl
class ServerConfig {
    var host: String = "0.0.0.0"
    var port: Int = 8080
    var debug: Boolean = false
    private val middleware = mutableListOf<String>()

    fun middleware(name: String) { middleware.add(name) }

    @ConfigDsl
    inner class Database {
        var url: String = "jdbc:postgresql://localhost/mydb"
        var maxPoolSize: Int = 10
        var timeout: Long = 30_000L
    }

    private var db: Database? = null
    fun database(init: Database.() -> Unit) {
        db = Database().apply(init)
    }

    override fun toString() =
        "Server($host:$port, debug=$debug, middleware=$middleware, db=$db)"
}

fun server(init: ServerConfig.() -> Unit) = ServerConfig().apply(init)

// ----- Query Builder DSL ----------------------------------------------------
// A small type-safe SQL query builder

@DslMarker
annotation class QueryDsl

@QueryDsl
class WhereClause {
    private val conditions = mutableListOf<String>()
    private val params = mutableListOf<Any>()

    infix fun String.eq(value: Any): WhereClause {
        conditions.add("$this = ?")
        params.add(value)
        return this@WhereClause
    }
    infix fun String.gt(value: Any): WhereClause {
        conditions.add("$this > ?")
        params.add(value)
        return this@WhereClause
    }
    infix fun String.like(pattern: String): WhereClause {
        conditions.add("$this LIKE ?")
        params.add(pattern)
        return this@WhereClause
    }

    fun and(init: WhereClause.() -> Unit): WhereClause {
        val sub = WhereClause().apply(init)
        conditions.add("(${sub.build()})")
        params.addAll(sub.params)
        return this
    }

    fun build() = conditions.joinToString(" AND ")
    fun params() = params.toList()
}

@QueryDsl
class SelectQuery {
    private var table: String = ""
    private val columns = mutableListOf<String>()
    private var where: WhereClause? = null
    private var limit: Int? = null
    private var orderBy: String? = null

    fun from(tableName: String) { table = tableName }
    fun select(vararg cols: String) { columns.addAll(cols) }
    fun limit(n: Int) { limit = n }
    fun orderBy(col: String) { orderBy = col }
    fun where(init: WhereClause.() -> Unit) { where = WhereClause().apply(init) }

    fun build(): Pair<String, List<Any>> {
        val cols = if (columns.isEmpty()) "*" else columns.joinToString()
        val sql = buildString {
            append("SELECT $cols FROM $table")
            where?.let { append(" WHERE ${it.build()}") }
            orderBy?.let { append(" ORDER BY $it") }
            limit?.let { append(" LIMIT $it") }
        }
        return sql to (where?.params() ?: emptyList())
    }
}

fun query(init: SelectQuery.() -> Unit): Pair<String, List<Any>> =
    SelectQuery().apply(init).build()

// ----- Gradle-style task DSL (simplified) -----------------------------------

@DslMarker
annotation class TaskDsl

@TaskDsl
class Task(val name: String) {
    var description: String = ""
    private val dependencies = mutableListOf<String>()
    private var action: (() -> Unit)? = null

    fun dependsOn(vararg tasks: String) { dependencies.addAll(tasks) }
    fun doLast(block: () -> Unit) { action = block }

    fun execute() {
        println("▶ Running task: $name (depends on: $dependencies)")
        action?.invoke()
    }
}

@TaskDsl
class TaskRegistry {
    private val tasks = mutableMapOf<String, Task>()

    fun task(name: String, init: Task.() -> Unit): Task =
        Task(name).apply(init).also { tasks[name] = it }

    fun run(name: String) {
        tasks[name]?.execute() ?: println("Task '$name' not found")
    }
}

fun tasks(init: TaskRegistry.() -> Unit): TaskRegistry =
    TaskRegistry().apply(init)

fun main() {
    println("=== HTML DSL ===")
    val page = html {
        body {
            h1("Hello, DSL!")
            div {
                attr("class", "container")
                p { +"This is a paragraph built with a DSL." }
                p { +"Another paragraph." }
            }
        }
    }
    println(page)

    println("\n=== Config DSL ===")
    val config = server {
        host = "localhost"
        port = 9090
        debug = true
        middleware("auth")
        middleware("logging")
        database {
            url = "jdbc:postgresql://db:5432/prod"
            maxPoolSize = 20
        }
    }
    println(config)

    println("\n=== Query Builder DSL ===")
    val (sql, params) = query {
        select("id", "name", "email")
        from("users")
        where {
            "age" gt 18
            "city" eq "NYC"
            "name" like "A%"
        }
        orderBy("name")
        limit(10)
    }
    println("SQL: $sql")
    println("Params: $params")

    println("\n=== Task DSL ===")
    val registry = tasks {
        task("compile") {
            description = "Compile sources"
            doLast { println("  Compiling...") }
        }
        task("test") {
            description = "Run tests"
            dependsOn("compile")
            doLast { println("  Running tests...") }
        }
        task("build") {
            description = "Full build"
            dependsOn("compile", "test")
            doLast { println("  Building artifact...") }
        }
    }
    registry.run("build")
    registry.run("test")
}
