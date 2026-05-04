# Versioning, Dependencies, and Publishing in Dart

---

## Semantic Versioning (SemVer)

Dart's pub package manager follows [Semantic Versioning 2.0.0](https://semver.org/). Every published Dart package version has the form:

```
MAJOR.MINOR.PATCH
  │      │     └── Bug fixes, no API changes
  │      └──────── New features, backwards compatible
  └─────────────── Breaking changes
```

### What each part means in Dart/pub context

**PATCH** (`1.2.X`): Bug fixes, documentation updates, performance improvements. Existing code using this package should work without any changes. Example: fixing a null pointer exception, correcting a return value.

**MINOR** (`1.X.0`): New public APIs added, existing APIs unchanged. Your code continues to work. Example: adding a new optional parameter, adding a new class, adding a new method to an existing class.

**MAJOR** (`X.0.0`): Breaking changes. Existing code may fail to compile or behave differently. Examples: renaming a class, removing a method, changing method signatures, changing behavior in a non-backwards-compatible way.

### The `0.x` Special Case

When the MAJOR version is `0`, different rules apply:
- `0.MINOR.PATCH` — the MINOR version acts like a MAJOR version
- Any `0.x` bump (e.g., `0.3.0` → `0.4.0`) **may** contain breaking changes
- This signals that the API is unstable and still evolving
- The caret operator `^0.3.0` means `>=0.3.0 <0.4.0` — it treats MINOR as breaking

**When to leave a package at `0.x`:**
You're still figuring out the API surface. Once you commit to stability, release `1.0.0`.

### Build Numbers in Flutter

Flutter apps (but not libraries) use a build number:

```
version: 2.5.1+103
         │         └── build number (versionCode on Android, CFBundleVersion on iOS)
         └──────────── version name (versionName on Android, CFBundleShortVersionString on iOS)
```

The build number must be strictly incremented with each store upload. It doesn't need to follow any particular scheme — just increment it.

---

## How the Caret `^` Operator Works

The caret is syntactic sugar for a common constraint pattern:

| Constraint | Equivalent Range | What it allows |
|---|---|---|
| `^1.2.3` | `>=1.2.3 <2.0.0` | MINOR and PATCH bumps |
| `^0.3.2` | `>=0.3.2 <0.4.0` | PATCH bumps only |
| `^0.0.3` | `>=0.0.3 <0.0.4` | Exactly `0.0.3` |
| `^2.0.0` | `>=2.0.0 <3.0.0` | MINOR and PATCH bumps |

The logic: "the leftmost non-zero digit must not change." This is based on the SemVer assumption that the leftmost non-zero component is the "stability indicator."

**Practical implication:** When a package releases `2.0.0` and you have `^1.x.x`, you will NOT automatically get the upgrade. You have to manually bump your constraint. This is intentional — major versions have breaking changes and you need to opt in.

**When caret is wrong:**
If a package doesn't follow SemVer (many older or immature packages don't), caret can be dangerous. A `0.x` package that makes breaking changes in PATCH releases would break you. In these cases, pin more tightly or use a range constraint.

---

## Transitive Dependencies and Conflict Resolution

When you depend on packages A and B, and both A and B depend on package C (but at different versions), pub must find a **single version of C** that satisfies all constraints. This is called the **version resolution problem**.

```
Your app
  ├── package_a: ^1.0.0
  │     └── http: ^0.13.0
  └── package_b: ^2.0.0
        └── http: ^1.1.0
```

Here, `package_a` requires `http <1.0.0` and `package_b` requires `http >=1.1.0`. These are **incompatible** — no single version of `http` satisfies both. `dart pub get` will fail with a version conflict error.

**Pub's resolution algorithm (pubgrub):**
Pub uses an algorithm called PubGrub (designed by the Dart team, now also used by Cargo). It explores the dependency graph and finds the newest set of versions that are mutually compatible. When it can't find a solution, it produces a detailed conflict explanation.

**How conflicts appear:**

```
Because package_a >=1.0.0 depends on http ^0.13.0
 and package_b >=2.0.0 depends on http ^1.1.0
 version solving failed.
```

**Resolving conflicts:**

1. **Wait for an upstream fix**: File issues with package_a to upgrade their http dependency.
2. **Use dependency_overrides**: Force a version you know works (risky).
3. **Find alternative packages**: Replace one conflicting package.
4. **Downgrade one dependency**: Use an older version of package_a or package_b that has compatible transitive deps.

---

## `dart pub outdated` — Interpreting the Output

Running `dart pub outdated` produces a table like this:

```
Showing outdated packages.
[*] indicates versions that require a major version change.

Name                Current   Upgradable  Resolvable  Latest
direct dependencies:
dio                 5.3.0     5.4.3       5.4.3       6.0.0 [*]
go_router           12.1.3    12.1.3      12.1.3      13.2.0 [*]
freezed_annotation  2.3.0     2.4.1       2.4.1       2.4.1

dev dependencies:
build_runner        2.4.6     2.4.9       2.4.9       2.4.9
freezed             2.3.5     2.4.7       2.4.7       2.4.7

transitive dependencies:
meta                1.9.0     1.10.0      1.12.0      1.12.0
```

**Column meanings:**

- **Current**: The version locked in `pubspec.lock` (what you're actually using)
- **Upgradable**: The newest version reachable *without* changing `pubspec.yaml` constraints. Running `dart pub upgrade` gets you here.
- **Resolvable**: The newest version reachable if you were to change constraints (but may require upgrading other packages too). This is the max achievable without breaking changes.
- **Latest**: The absolute newest published version, regardless of compatibility.

**The `[*]` marker**: This package has a newer MAJOR version available. You'd need to change your constraint (e.g., `^12.0.0` → `^13.0.0`) and handle any breaking changes.

**Color coding** (in terminals that support it):
- Green: up to date
- Yellow: upgradable within constraints
- Red: major version available or constraint change needed

---

## `dart pub upgrade --major-versions`

This command does two things:
1. Resolves to the latest version of every dependency, including across major versions
2. **Rewrites `pubspec.yaml`** to update the lower bounds of constraints to allow the new major versions

```bash
dart pub upgrade --major-versions
```

This is equivalent to manually editing `pubspec.yaml` to raise all the `^X` prefixes and then running `dart pub upgrade`. Use this when you're ready to intentionally migrate to new major versions.

**Workflow for a major version upgrade:**

1. Run `dart pub upgrade --major-versions` — this updates `pubspec.yaml` and `pubspec.lock`
2. Run `dart analyze` — see what broke
3. Read the migration guide for each upgraded package
4. Fix all breaking changes
5. Run tests
6. Commit `pubspec.yaml`, `pubspec.lock`, and all code changes together

---

## Dependency Overrides — When to Use and Risks

```yaml
dependency_overrides:
  http: ^1.2.0
  some_package:
    path: ../my_local_fork
```

### Legitimate use cases

**Security patches**: A transitive dependency has a CVE. The direct dependency hasn't released a fix yet. You override to the patched version to protect your app immediately.

**Monorepo local development**: You're developing package A and package B simultaneously. B depends on A. You override A with a path dependency to test in-progress changes.

**Prototype testing**: Testing compatibility with an unreleased pre-release or a fork before committing to it.

**Breaking a version deadlock**: Two packages require incompatible versions of a third package. You override to a version you've manually verified works with both.

### Risks

**Compatibility breakage**: You're bypassing the constraint checks that protect you. The overridden version may not actually be compatible with one of the packages that declared a constraint against it. This can manifest as runtime errors, not compile errors.

**Hidden from consumers**: Overrides only affect the root package. If you're developing a library, your consumers will NOT get your overrides. The library's constraints must actually be compatible without overrides.

**Easy to forget**: Overrides can linger in `pubspec.yaml` long after they're needed, silently holding back a dependency from upgrading.

**Best practice**: Add a comment next to every override explaining:
```yaml
dependency_overrides:
  # TEMP: override until package_a releases a fix for CVE-2024-XXXX.
  # Tracked: https://github.com/example/package_a/issues/123
  # Remove after package_a >= 2.3.1 is released and we upgrade.
  http: '>=1.2.4'
```

---

## Publishing a Package to pub.dev

### Pre-publish Checklist

Before running `dart pub publish`:

**Code quality:**
- [ ] `dart analyze` passes with zero issues
- [ ] `dart format .` applied (all files formatted)
- [ ] All tests pass: `dart test` or `flutter test`
- [ ] Public API has dartdoc comments (`///`)

**pubspec.yaml:**
- [ ] `name` is lowercase snake_case and available on pub.dev
- [ ] `version` is set correctly
- [ ] `description` is 60–180 characters
- [ ] `environment.sdk` constraint is accurate
- [ ] `homepage` or `repository` is set
- [ ] No `publish_to: none`
- [ ] No path dependencies in `dependencies` (only allowed in `dev_dependencies`)

**Files:**
- [ ] `CHANGELOG.md` exists and documents this version
- [ ] `README.md` exists and explains the package
- [ ] `LICENSE` file exists (pub.dev requires this for 130/130 pub points)
- [ ] Example code in `example/` directory
- [ ] `.pubignore` configured to exclude test data, generated files, etc.

**pub.dev scoring:**
pub.dev scores packages on a 130-point scale (the "pub points"):
- Following Dart file conventions: 10 pts
- Providing documentation: 20 pts
- Platform support: 20 pts
- Pass static analysis: 50 pts
- Support up-to-date dependencies: 20 pts
- Having a license: 10 pts

### The `dart pub publish` Command

```bash
# Dry run — validates everything without actually publishing
dart pub publish --dry-run

# Publish for real
dart pub publish
```

You'll be prompted to authenticate via Google OAuth. After publishing, your package appears on pub.dev within a few minutes. **You cannot unpublish a specific version** — you can retract it (hides from search but still downloadable) but cannot delete it.

### The `.pubignore` File

Works like `.gitignore` but for publishing. Files listed here are excluded from the published package:

```
# .pubignore
test/
integration_test/
screenshots/
.github/
analysis_options.yaml
```

If no `.pubignore` exists, pub falls back to `.gitignore`. The key difference: test files in `.gitignore` would not be published, but you might want them excluded from the package even if you don't `.gitignore` them.

---

## Pre-release Versions

SemVer allows pre-release identifiers after a hyphen:

```
1.0.0-alpha.1
1.0.0-beta.3
1.0.0-rc.1
2.0.0-dev.1
```

### How pub handles pre-releases

**Pre-releases are excluded from normal resolution.** If you have `^1.0.0` and version `1.1.0-beta.1` exists, `dart pub get` will NOT select it. You must explicitly opt in:

```yaml
dependencies:
  some_package: 1.1.0-beta.1  # exact pin to a pre-release
  # or:
  some_package: '>=1.1.0-beta.1 <2.0.0'  # range that includes pre-releases
```

`dart pub upgrade` will also skip pre-releases unless you've already opted into a pre-release version.

### Pre-release versions in your own package

```
version: 2.0.0-alpha.1   # First alpha of the upcoming 2.0.0
version: 2.0.0-beta.3    # Third beta
version: 2.0.0-rc.1      # Release candidate
version: 2.0.0            # Stable release
```

Use pre-releases when:
- Making breaking changes and want early adopters to test
- Building up to a major release incrementally
- Wanting to publish to pub.dev for early feedback without affecting current stable users

### Pre-release comparison

Pre-releases have lower precedence than the release:
`1.0.0-alpha.1 < 1.0.0-beta.1 < 1.0.0-rc.1 < 1.0.0`

Identifiers are compared lexically (strings) or numerically (numbers):
`1.0.0-alpha.1 < 1.0.0-alpha.2 < 1.0.0-alpha.10`
`1.0.0-alpha < 1.0.0-beta` (lexical comparison: 'a' < 'b')

---

## Version Constraint Best Practices Summary

| Scenario | Recommended Constraint |
|---|---|
| Stable package, trust SemVer | `^1.2.3` |
| Unstable `0.x` package | `^0.3.2` (already conservative) |
| Package doesn't follow SemVer | `'>=1.2.3 <1.5.0'` (manual range) |
| Need exact reproducibility | Use `pubspec.lock` (don't pin in pubspec) |
| Need to exclude a bad version | `'>=1.2.3 <1.2.7 >=1.2.8'` (note: two ranges, not directly writable — use override) |
| Testing a pre-release | `1.0.0-beta.1` (exact pin) |
| Library (be permissive) | Wide range: `'>=1.0.0 <3.0.0'` |
