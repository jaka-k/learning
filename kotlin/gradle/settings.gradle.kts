// ============================================================
// settings.gradle.kts — Gradle Settings Script
// ============================================================
// This file is the entry point for every Gradle build.
// Gradle looks for settings.gradle.kts (or settings.gradle) first.
// It defines:
//   1. The root project name
//   2. Which subprojects (modules) are included
//   3. Dependency resolution settings and plugin repositories

// ----- Root project name ----------------------------------------------------
// The rootProject.name becomes the default archive name and is used
// to identify this build in multi-project builds.
rootProject.name = "learning-kotlin"

// ----- Plugin management block ----------------------------------------------
// Repositories where Gradle looks for PLUGINS (not regular dependencies).
// Evaluated BEFORE build.gradle.kts files.
pluginManagement {
    repositories {
        // Maven Central is the primary open-source repo
        mavenCentral()
        // Gradle Plugin Portal hosts community plugins (e.g., Shadow, SpotBugs)
        gradlePluginPortal()
        // Google's repository — required for Android, KSP, etc.
        google()
    }

    // resolutionStrategy — override plugin versions in one place
    // rather than specifying them in every subproject
    resolutionStrategy {
        eachPlugin {
            if (requested.id.namespace == "org.jetbrains.kotlin") {
                useVersion("2.1.0")
            }
        }
    }
}

// ----- Dependency resolution management ------------------------------------
// Centralise ALL dependency resolution here.
// Subprojects inherit these settings automatically.
dependencyResolutionManagement {
    // FAIL_ON_PROJECT_REPOS: disallow declaring repositories in subproject
    // build.gradle.kts files — forces all repos to be declared here.
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)

    repositories {
        mavenCentral()
        google()
        // Snapshots (use with care — unstable):
        // maven("https://oss.sonatype.org/content/repositories/snapshots")
    }

    // Version catalogs — define versions and bundles in a single TOML file
    // Referenced in build scripts as `libs.kotlin.stdlib`, etc.
    // See gradle/libs.versions.toml for the catalog definition.
    versionCatalogs {
        create("libs") {
            from(files("gradle/libs.versions.toml"))
        }
    }
}

// ----- Including subprojects ------------------------------------------------
// Each include() corresponds to a directory with its own build.gradle.kts.
// The directory structure can differ from the project name using `project(":name").projectDir`

// Simple include: directory name == project name
include(":app")
include(":core")
include(":data")

// Custom directory mapping (e.g., separate services/ folder)
// include(":user-service")
// project(":user-service").projectDir = file("services/user")

// Nested subprojects
// include(":features:auth")
// include(":features:payment")
