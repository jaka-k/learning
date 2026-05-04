// ============================================================
// build.gradle.kts — Kotlin DSL Build Script
// ============================================================
// This file configures ONE project (or the root project).
// Kotlin DSL (.kts) gives you type-safe access and IDE autocomplete
// compared to the Groovy DSL (build.gradle).

// ----- Plugins block --------------------------------------------------------
// `plugins { }` is evaluated at configuration time before any other block.
// Plugins add tasks, extensions, and configurations to the project.

plugins {
    // Core Kotlin JVM plugin — adds compileKotlin, compileTestKotlin tasks
    // and configures the Kotlin compiler
    kotlin("jvm") version "2.1.0"

    // Application plugin — adds `run` task and produces a distribution
    // Adds: run, installDist, distZip, distTar tasks
    application

    // Serialization plugin — enables @Serializable annotation processing
    // (part of the Kotlin compiler, not a separate library)
    kotlin("plugin.serialization") version "2.1.0"
}

// ----- Group and version ----------------------------------------------------
// group: your Maven groupId — usually reverse domain (com.example)
// version: use SemVer; "-SNAPSHOT" suffix marks in-progress versions
group   = "com.example"
version = "1.0.0-SNAPSHOT"

// ----- Repositories ---------------------------------------------------------
// Where to download dependencies from. Not needed if declared in settings.gradle.kts
// with dependencyResolutionManagement (preferred in multi-project builds).
repositories {
    mavenCentral()
}

// ----- Dependencies block ---------------------------------------------------
// Configuration buckets:
//   implementation   — on compile & runtime classpath; NOT exposed to consumers
//   api              — same as implementation but IS exposed (library projects)
//   compileOnly      — compile only, not at runtime (e.g., annotation processors)
//   runtimeOnly      — runtime only, not at compile time
//   testImplementation / testRuntimeOnly — same as above but for tests only
//   kapt             — Kotlin annotation processor (use ksp for new projects)
//   ksp              — Kotlin Symbol Processing (modern annotation processing)

dependencies {
    // Kotlin standard library — auto-added by the kotlin("jvm") plugin,
    // shown here for illustration
    implementation(kotlin("stdlib"))

    // Kotlin coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.0")

    // Arrow — functional programming for Kotlin (Either, IO, optics)
    implementation("io.arrow-kt:arrow-core:1.2.4")

    // Serialization runtime — needed alongside the compiler plugin
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.3")

    // Test dependencies
    testImplementation(kotlin("test"))   // JUnit 5 under the hood for Kotlin
    testImplementation("io.kotest:kotest-runner-junit5:5.8.0")
    testImplementation("io.mockk:mockk:1.13.10")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

// ----- Kotlin compiler options ----------------------------------------------
// Access via the `kotlin` extension added by the Kotlin plugin

kotlin {
    // Target JVM version — byte code compatibility
    jvmToolchain(21)   // recommended: use toolchain instead of sourceCompatibility

    // Compiler options shared by all Kotlin compilations in this project
    compilerOptions {
        // Enable experimental stdlib APIs without @OptIn on every use
        // freeCompilerArgs.add("-opt-in=kotlin.RequiresOptIn")

        // Strict null checks for Java interop (T! becomes T? not T)
        // freeCompilerArgs.add("-Xjsr305=strict")

        // Enable K2 compiler (default from Kotlin 2.0)
        // languageVersion.set(KotlinVersion.KOTLIN_2_0)
    }
}

// ----- Application entry point ----------------------------------------------
// Only relevant when the `application` plugin is applied

application {
    mainClass.set("com.example.MainKt")  // top-level main() is in MainKt by convention
}

// ----- Test configuration ---------------------------------------------------
tasks.test {
    // Gradle needs to be told to use JUnit Platform (JUnit 5 runner)
    useJUnitPlatform()

    // Show test output in the console even on success
    testLogging {
        events("passed", "skipped", "failed")
    }

    // Parallel test execution (requires test isolation)
    // maxParallelForks = (Runtime.getRuntime().availableProcessors() / 2).coerceAtLeast(1)
}

// ----- Custom tasks ---------------------------------------------------------
// Tasks are the basic unit of work in Gradle.
// Every task has: inputs, outputs, and an action.

// Register a simple task
tasks.register("hello") {
    group = "demo"
    description = "Prints Hello, Gradle!"
    // doLast runs after all actions from superclasses
    doLast {
        println("Hello, Gradle! (Kotlin DSL)")
    }
}

// Task that depends on another task
tasks.register("greet") {
    dependsOn("hello")   // runs `hello` first
    doLast { println("Greet task ran") }
}

// Copy task — built-in task type with inputs/outputs for up-to-date checks
tasks.register<Copy>("copyConfig") {
    from("src/main/resources")
    into(layout.buildDirectory.dir("config"))
    include("*.properties", "*.yaml")
    // Gradle tracks inputs/outputs; this task is SKIPPED if nothing changed
}

// Exec task — run a shell command
tasks.register<Exec>("printVersion") {
    commandLine("echo", "Version: ${project.version}")
}

// ----- Configurations and dependencies advanced -----------------------------

// Create a custom configuration (e.g., for an agent/runtime classpath)
val agentConfig: Configuration by configurations.creating

dependencies {
    // agentConfig("com.example:my-agent:1.0")
}

// Extend an existing configuration
configurations {
    implementation {
        // Exclude a transitive dependency globally
        exclude(group = "commons-logging", module = "commons-logging")
    }
}

// ----- Source sets ----------------------------------------------------------
// sourceSets define which directories are compiled together.
// integration tests as a separate source set:

// sourceSets {
//     create("integrationTest") {
//         kotlin.srcDir("src/integrationTest/kotlin")
//         resources.srcDir("src/integrationTest/resources")
//         compileClasspath += sourceSets["main"].output + configurations["testRuntimeClasspath"]
//         runtimeClasspath += output + compileClasspath
//     }
// }

// ----- Properties and extra properties -------------------------------------
// Project properties can be passed as: -PmyProp=value on the CLI
// or defined in gradle.properties at the root.

val myProp: String by project.properties   // from gradle.properties
// val buildNumber: String = System.getenv("BUILD_NUMBER") ?: "local"

// Extra properties — arbitrary key/value attached to any object
// extra["someKey"] = "someValue"
// val val: String by extra
