# pubspec.yaml — The Complete Guide

The `pubspec.yaml` file is the manifest for every Dart and Flutter project. It tells the `pub` package manager (bundled with the Dart SDK) who you are, what you need, and how your package is structured. Every Dart package — whether it's a Flutter app, a CLI tool, or a shared library — must have a `pubspec.yaml` at its root.

---

## Required Fields

### `name`

```yaml
name: my_awesome_app
```

The package name must be:
- All lowercase
- Words separated by underscores (`snake_case`)
- Only letters, numbers, and underscores (no hyphens)
- Unique on pub.dev if you intend to publish

This name is how other packages import your code:
`import 'package:my_awesome_app/some_file.dart';`

### `version`

```yaml
version: 1.2.3
```

Follows Semantic Versioning (SemVer): `MAJOR.MINOR.PATCH`. Required if you publish to pub.dev. Optional for private apps but strongly recommended — Flutter uses it for `--build-name` in `flutter build`. You can also include a build number: `version: 1.2.3+42` where `42` is the build number (used as `versionCode` on Android, `CFBundleVersion` on iOS).

### `environment` (SDK Constraint)

```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
```

This is **not optional in practice**. It tells pub which Dart SDK versions can use this package. Without it, pub assumes the package works with any SDK version, which is almost never true. The lower bound prevents use on old SDKs that lack features you depend on. The upper bound is typically the next major version — you're saying "I haven't tested against Dart 4.x yet."

Flutter projects also often specify the Flutter SDK:
```yaml
environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'
```

---

## Dependency Sections

### `dependencies`

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  go_router: ^13.0.0
```

These are **runtime dependencies** — packages your code imports and needs to function. They are included in the final compiled output. Both your package and any package that depends on yours will have these resolved.

### `dev_dependencies`

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
  mockito: ^5.4.0
```

These are **development-only dependencies**. They are NOT included in your compiled app. Use them for:
- Testing frameworks (`flutter_test`, `test`)
- Code generators (`build_runner`, `freezed`, `json_serializable`)
- Linting tools (`flutter_lints`)
- Mocking libraries (`mockito`)

When someone else depends on your *library* package, they do not get your `dev_dependencies`. This keeps the dependency graph clean.

### `dependency_overrides`

```yaml
dependency_overrides:
  some_package: ^2.0.0
```

This is an **escape hatch**. It forces pub to use a specific version of a package regardless of what any dependency in the graph requires. Use it when:
- You need a security patch before an upstream package has updated its dependency
- Two packages require incompatible versions and you need to force a resolution
- You're testing your code against an unreleased version of a dependency

**Risks:** You're overriding the version compatibility checks that protect you. The forced version may not actually be compatible with all packages using it. Overrides are **never exported** — they only affect the root package, not packages that depend on yours.

---

## Version Constraint Syntax

### Caret `^` — Compatible with (most common)

```yaml
http: ^1.2.3
```

Means `>=1.2.3 <2.0.0`. Allows MINOR and PATCH upgrades, but not MAJOR. This is the **recommended default** for most dependencies. It assumes the package follows SemVer: breaking changes only happen in MAJOR versions.

If the version starts with `0.x`, caret is more conservative:
- `^0.3.2` means `>=0.3.2 <0.4.0` — only PATCH upgrades allowed (because `0.x` packages signal instability)
- `^0.0.3` means `>=0.0.3 <0.0.4` — only that exact PATCH

### Range Constraints

```yaml
some_package: '>=1.0.0 <2.0.0'
```

Explicit range. Equivalent to `^1.0.0` in this case, but gives you full control. You might use this when the package doesn't follow SemVer strictly, or you have a specific known-bad version to exclude:

```yaml
some_package: '>=1.0.0 <1.5.3'  # 1.5.3 has a bug, exclude it
```

### `any`

```yaml
some_package: any
```

Accepts any version. **Avoid this in libraries** — it makes your package incompatible with almost everything because it will conflict with any other constraint on that package. Sometimes acceptable in applications where you control the entire dependency graph.

### Exact Pinning

```yaml
some_package: 1.2.3
```

Requires exactly that version. Even stricter than `any`, because it will conflict with anything else. Rarely appropriate — use `pubspec.lock` instead when you want reproducible builds. Exact pinning in `pubspec.yaml` itself makes future upgrades painful.

---

## Dependency Sources

### Hosted (pub.dev) — Default

```yaml
dependencies:
  http: ^1.1.0  # Implicitly from pub.dev
  
  # Explicit form:
  http:
    hosted: https://pub.dev
    version: ^1.1.0
```

The explicit hosted form lets you use a **private pub server** (like Dart's self-hosted pub server or a company proxy):
```yaml
dependencies:
  my_private_package:
    hosted: https://packages.mycompany.com
    version: ^1.0.0
```

### Git Dependencies

```yaml
dependencies:
  some_package:
    git:
      url: https://github.com/username/some_package.git
      ref: main          # branch, tag, or commit SHA
      path: packages/core  # optional: subdirectory within the repo
```

Use git dependencies for:
- Packages not yet published to pub.dev
- Testing unreleased fixes before a package maintainer publishes
- Internal packages in private GitHub/GitLab repos

**Caution:** Git dependencies don't have the version stability of pub.dev. A branch reference like `main` is a moving target.

### Path Dependencies

```yaml
dependencies:
  my_local_package:
    path: ../my_local_package        # relative path
    
  another_package:
    path: /absolute/path/to/package  # absolute path
```

Path dependencies are resolved from the filesystem. Perfect for:
- Monorepo setups (packages in the same repo)
- Rapid iteration — changes to the local package are immediately reflected
- Testing changes to a package you maintain before publishing

Path dependencies **cannot be published to pub.dev** — they're replaced with version references before publishing.

---

## pubspec.lock

When you run `dart pub get`, pub resolves the full dependency graph and writes `pubspec.lock`. This file records the **exact version of every package** (direct and transitive) that was resolved. It looks like:

```yaml
packages:
  http:
    dependency: "direct main"
    description:
      name: http
      sha256: "abc123..."
      url: "https://pub.dev"
    source: hosted
    version: "1.2.0"
```

### When to commit pubspec.lock

**Applications (Flutter apps, CLI tools): YES, always commit it.**
- Ensures every developer on the team, every CI run, and every deployment uses exactly the same dependency versions
- Prevents "it works on my machine" bugs caused by someone else getting a newer (broken) transitive dependency
- `dart pub get` with a lock file is fast — no resolution needed

**Libraries (packages published to pub.dev): NO, don't commit it.**
- Libraries are consumed by other projects that have their own lock files
- Committing a lock file in a library would be misleading (it's not used by consumers)
- However, the lock file in a library is used when running the library's own tests — so it can be useful to keep around locally while not committing it
- Convention: add `pubspec.lock` to `.gitignore` for library packages

---

## pub Commands

### `dart pub get`

Reads `pubspec.yaml` and `pubspec.lock` (if present), downloads all dependencies, and populates the `.dart_tool/package_config.json`. If there's no lock file, it creates one. If there is a lock file, it respects it exactly (won't upgrade anything).

Run this after:
- Cloning a project
- Pulling changes that modified `pubspec.yaml`
- Adding a new dependency to `pubspec.yaml` manually

### `dart pub upgrade`

Ignores the lock file and resolves to the **newest allowed version** of every dependency (within the constraints in `pubspec.yaml`). Updates `pubspec.lock` with the new resolutions. Does not change `pubspec.yaml` itself.

Use this periodically to get bug fixes and security patches in your dependencies.

```bash
dart pub upgrade           # upgrade all packages within constraints
dart pub upgrade http      # upgrade only the http package
```

### `dart pub upgrade --major-versions`

Also updates `pubspec.yaml` to raise the lower bound constraints to allow major version upgrades. Use this when you want to opt into breaking changes intentionally. This is the command to run when migrating to a new major version of a package.

### `dart pub outdated`

Shows a table of all dependencies with their current version, the latest resolvable version (within constraints), the latest version available, and whether there are null-safety issues. Use this to audit your dependency health:

```
Package    Current  Upgradable  Resolvable  Latest
http       1.1.0    1.2.0       1.2.0       2.0.0
```

This output means: you have 1.1.0, you can get 1.2.0 without changing `pubspec.yaml`, but 2.0.0 (a major release) is available and would require constraint changes.

---

## Flutter-Specific Fields

### `flutter:` section

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/data/config.json

  fonts:
    - family: RobotoMono
      fonts:
        - asset: assets/fonts/RobotoMono-Regular.ttf
        - asset: assets/fonts/RobotoMono-Bold.ttf
          weight: 700
        - asset: assets/fonts/RobotoMono-Italic.ttf
          style: italic

  plugin:
    platforms:
      android:
        package: com.example.my_plugin
        pluginClass: MyPlugin
      ios:
        pluginClass: MyPlugin
```

**`assets`**: Lists files or directories to bundle into the app. Can use directory paths (ending in `/`) to include all files in that directory (but not subdirectories — each level must be listed explicitly).

**`fonts`**: Registers custom fonts. The `family` name is what you use in `TextStyle(fontFamily: 'RobotoMono')`. Multiple weights/styles within a family are listed under `fonts:`.

**`uses-material-design`**: Must be `true` to use Material Icons. Without this, the Material icon font won't be bundled.

**`plugin`**: Only present in plugin packages. Specifies the platform implementations.

---

## `publish_to: none`

```yaml
publish_to: none
```

Add this to any package that should **never be published to pub.dev**. When set, `dart pub publish` will refuse to publish. Use it for:
- Flutter apps (you don't publish apps to pub.dev)
- Internal tools
- Packages in monorepos that are not meant to be public

---

## Workspace Support (Dart 3.5+ Monorepos)

Dart 3.5 introduced native workspace support, eliminating the need for third-party tools like `melos` for basic monorepo workflows.

**Root `pubspec.yaml`:**
```yaml
name: my_monorepo
publish_to: none

workspace:
  - packages/core
  - packages/ui
  - apps/mobile
  - apps/web
```

**Each member package has its own `pubspec.yaml`** with a `resolution: workspace` field:
```yaml
name: core
version: 1.0.0
resolution: workspace

environment:
  sdk: '>=3.5.0 <4.0.0'
```

When you run `dart pub get` from the workspace root, a **single shared `pubspec.lock`** is generated for all workspace members. This guarantees all packages use the same version of every shared dependency — no more version conflicts between packages in the same monorepo.

Benefits:
- One lock file for the whole monorepo
- Cross-package path dependencies automatically resolved
- `dart pub upgrade` upgrades all packages atomically

---

## pub.dev Publishing Fields

### `topics`

```yaml
topics:
  - networking
  - http
  - rest-api
```

Tags that help users discover your package on pub.dev. Limited to 5 topics. Must use existing pub.dev taxonomy topics when possible.

### `screenshots`

```yaml
screenshots:
  - description: 'Main screen showing the widget in action'
    path: screenshots/main.png
  - description: 'Dark mode variant'
    path: screenshots/dark.png
```

Images shown on your pub.dev package page. Paths are relative to the package root. PNG or JPEG. Recommended size: at least 800x600 pixels. Having screenshots dramatically improves your package's pub.dev score.

### Other Publishing Fields

```yaml
description: >-
  A Flutter package for beautifully animated transitions.
  Supports iOS, Android, Web, and Desktop.

homepage: https://github.com/username/my_package
repository: https://github.com/username/my_package
issue_tracker: https://github.com/username/my_package/issues
documentation: https://username.github.io/my_package

funding:
  - https://github.com/sponsors/username
```

- `description`: Required for publishing. 60–180 characters, plain text.
- `repository`: Shown as "Source code" on pub.dev and used for pub points scoring.
- `funding`: Links shown in the "Fund" section on pub.dev.

---

## Full Field Reference Summary

| Field | Required | Purpose |
|---|---|---|
| `name` | Yes | Package identifier |
| `version` | For publishing | SemVer version |
| `environment.sdk` | Strongly recommended | SDK compatibility |
| `dependencies` | Usually | Runtime deps |
| `dev_dependencies` | Usually | Dev/test-only deps |
| `dependency_overrides` | Rarely | Force dep versions |
| `publish_to: none` | For apps | Prevent publishing |
| `flutter:` | Flutter only | Assets, fonts, plugins |
| `workspace:` | Monorepos | Workspace members |
| `topics` | For pub.dev | Discoverability |
| `screenshots` | For pub.dev | Visual showcase |
