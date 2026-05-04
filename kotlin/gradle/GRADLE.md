# Gradle — Build System Deep Dive

## What is Gradle?

Gradle is the de-facto build tool for Kotlin (and Android) projects. It:
- Compiles source files
- Manages dependencies (downloads JARs)
- Runs tests
- Packages artifacts (JARs, ZIPs, Docker images)
- Models task dependencies (a DAG of work units)

Gradle uses a **Kotlin DSL** (`build.gradle.kts`) or Groovy DSL (`build.gradle`). The Kotlin DSL has IDE autocomplete and type safety.

---

## Build Lifecycle

Every Gradle build goes through three phases:

```
1. Initialization  →  settings.gradle.kts is evaluated
                       Gradle determines which projects exist

2. Configuration   →  build.gradle.kts for every project is evaluated
                       Tasks and their dependencies are wired up
                       No work is done yet

3. Execution       →  Only the requested tasks and their dependencies run
```

> **Key insight:** `println()` at the top level of `build.gradle.kts` runs at **configuration** time (every build). Put prints inside `doLast { }` to run at execution time only.

---

## Project Structure

```
root/
├── settings.gradle.kts        ← required, entry point
├── build.gradle.kts           ← root project build script
├── gradle/
│   ├── wrapper/
│   │   ├── gradle-wrapper.jar
│   │   └── gradle-wrapper.properties  ← Gradle version pinned here
│   └── libs.versions.toml    ← version catalog (optional but recommended)
├── gradlew                    ← Unix wrapper script
├── gradlew.bat                ← Windows wrapper script
├── app/
│   └── build.gradle.kts      ← subproject
└── core/
    └── build.gradle.kts      ← subproject
```

Always use `./gradlew` (the wrapper) rather than a globally-installed `gradle`. The wrapper downloads the exact Gradle version specified in `gradle-wrapper.properties`, ensuring reproducible builds.

---

## Key Concepts

### Tasks

The fundamental unit of work. Every task has:
- **Inputs** — files, properties (tracked for up-to-date checks)
- **Outputs** — files, directories
- **Actions** — the code that runs (`doFirst`, `doLast`)

```kotlin
tasks.register<Copy>("copyDocs") {
    from("docs/")
    into(layout.buildDirectory.dir("site"))
    dependsOn("generateDocs")   // runs generateDocs first
}
```

Gradle skips a task if inputs and outputs haven't changed (**incremental build**).

### Configurations

A named set of dependencies. Common ones:

| Configuration       | Compile? | Runtime? | Exported to consumers? |
|---------------------|----------|----------|------------------------|
| `implementation`    | ✅        | ✅        | ❌                      |
| `api`               | ✅        | ✅        | ✅ (library projects)   |
| `compileOnly`       | ✅        | ❌        | ❌                      |
| `runtimeOnly`       | ❌        | ✅        | ❌                      |
| `testImplementation`| ✅ test   | ✅ test   | ❌                      |

Use `implementation` by default. Use `api` only when downstream consumers **must** see the transitive dependency at compile time.

### Dependency Coordinates

```kotlin
implementation("group:artifact:version")
// e.g.:
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.8.0")
```

With a version catalog:
```kotlin
implementation(libs.kotlinx.coroutines.core)
```

### Plugins

Plugins add tasks and DSL extensions. Two ways to apply:

```kotlin
// New style (resolves from Plugin Portal)
plugins {
    kotlin("jvm") version "2.1.0"
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

// Legacy style (still used for local/classpath plugins)
apply(plugin = "some-plugin")
```

---

## Common Tasks

```bash
./gradlew tasks              # list all available tasks
./gradlew build              # compile + test + assemble artifact
./gradlew test               # run tests only
./gradlew run                # run the application (requires `application` plugin)
./gradlew clean              # delete build/ directories
./gradlew dependencies       # print dependency tree
./gradlew :app:dependencies  # dependency tree for :app subproject
./gradlew check              # all verification tasks (test, lint, etc.)
./gradlew assemble           # build artifact without running tests
```

Append `--info` or `--debug` for more output. Append `--scan` to upload a build scan to scans.gradle.com.

---

## Multi-Project Builds

Useful when splitting a system into modules with separate compilation units.

**settings.gradle.kts:**
```kotlin
include(":app", ":core", ":data")
```

**:app/build.gradle.kts:**
```kotlin
dependencies {
    implementation(project(":core"))   // depend on another subproject
}
```

Each subproject has its own `build.gradle.kts`. Configuration in the root `build.gradle.kts` can be shared:

```kotlin
// root build.gradle.kts — apply to all subprojects
subprojects {
    apply(plugin = "org.jetbrains.kotlin.jvm")
    repositories { mavenCentral() }
}
```

Or using `allprojects { }` (includes root), or convention plugins (preferred for larger builds).

---

## Convention Plugins

For large multi-project builds, duplication across subproject `build.gradle.kts` files grows. **Convention plugins** (also called "precompiled script plugins") extract shared config into a plugin in `buildSrc/` or an included build.

```
buildSrc/
└── src/main/kotlin/
    └── my.kotlin-library.gradle.kts   ← convention plugin
```

```kotlin
// my.kotlin-library.gradle.kts
plugins {
    kotlin("jvm")
}
kotlin { jvmToolchain(21) }
dependencies {
    testImplementation(libs.kotest.runner.junit5)
}
```

Apply it in any subproject:
```kotlin
plugins {
    id("my.kotlin-library")   // one line replaces boilerplate
}
```

---

## Incremental Compilation

Gradle and the Kotlin compiler both support incremental compilation:
- Gradle: skips tasks with unchanged inputs/outputs
- Kotlin compiler: recompiles only affected files

Enable compiler daemon for faster builds (enabled by default since Kotlin 1.6):
```properties
# gradle.properties
kotlin.incremental=true
org.gradle.daemon=true
org.gradle.caching=true          # reuse outputs across clean builds
org.gradle.parallel=true         # build subprojects in parallel
org.gradle.jvmargs=-Xmx2g        # more heap for the Gradle daemon
```

---

## Dependency Locking and Verification

```bash
./gradlew dependencies --write-locks     # write gradle.lockfile
./gradlew --dependency-verification=strict  # verify checksums
```

Use `dependencyLocking { lockAllConfigurations() }` in `build.gradle.kts` to lock every configuration. Commit the lock files to version control for reproducible builds.

---

## Gradle Wrapper

The wrapper (`gradlew`) ensures everyone uses the exact same Gradle version:

```properties
# gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
```

Update the wrapper version:
```bash
./gradlew wrapper --gradle-version 8.8
```

---

## Useful Debugging Commands

```bash
./gradlew :app:test --tests "com.example.MyTest" --info   # run one test class
./gradlew :app:compileKotlin --rerun                      # force rerun even if up-to-date
./gradlew build --continue                                 # keep going on failure
./gradlew properties                                       # dump all project properties
./gradlew outgoingVariants                                 # what a project publishes
./gradlew :app:dependencyInsight --dependency coroutines --configuration runtimeClasspath
```
