# Dart & Flutter Learning Project

## Instructions

This folder contains files for learning Dart and Flutter in depth. When adding to or expanding this project, follow these guidelines:

- Create subdirectories by topic (e.g., `functions/`, `classes/`, `async/`, `collections/`, `types/`, `patterns/`, `pubspec/`, `flutter/`)
- In each subdir, create `.dart` files that serve the purpose of learning Dart/Flutter in and out
- Do a little bit of the basics, but **mostly focus on advanced stuff**
- Add a lot of inline comments explaining specific APIs and patterns
- Add a `pubspec/` folder explaining Dart's package management and `pubspec.yaml` concepts
- If a topic is too large for inline comments, add a `.md` file explaining it
- Pure Dart files should be runnable with `dart run` and include a `main()` function where possible
- Flutter files should be self-contained widgets or apps that can be dropped into a Flutter project

## Project Structure

```
dart-flutter/
├── CLAUDE.md                  ← this file
├── functions/                 ← closures, higher-order functions, extensions, typedefs, tear-offs
├── classes/                   ← OOP: mixins, abstract classes, interfaces, generics, factory constructors
├── async/                     ← async/await, Futures, Streams, Isolates, compute()
├── collections/               ← List/Map/Set operations, iterables, spreads, collection-if/for
├── types/                     ← null safety, type system, generics, covariance, type inference
├── patterns/                  ← pattern matching, records, sealed classes, functional patterns
├── pubspec/                   ← pub package manager, pubspec.yaml, versioning, workspaces
└── flutter/                   ← widgets, state management, navigation, layout, animations
    ├── widgets/               ← StatelessWidget, StatefulWidget, InheritedWidget, hooks
    ├── state/                 ← setState, Provider, Riverpod, BLoC patterns
    ├── navigation/            ← Navigator 2.0, go_router, deep links
    ├── layout/                ← constraints, flex, slivers, custom painters
    └── animations/            ← implicit, explicit, hero, custom animations
```

## Dart-specific focus areas

- Null safety (`?`, `!`, `late`, nullable types, promotion)
- Extension methods and extension types (Dart 3.x)
- Records and destructuring (Dart 3.0+)
- Sealed classes and exhaustive pattern matching (Dart 3.0+)
- Mixins vs abstract classes vs interfaces (Dart uses `implements`/`with`/`extends` distinctly)
- Isolates for true parallelism vs async for concurrency
- `Stream` vs `Future`: single vs multi-value async

## Flutter-specific focus areas

- Widget tree, element tree, render tree — how Flutter actually works
- `BuildContext` and why it matters
- Keys (`ValueKey`, `GlobalKey`, `UniqueKey`) and when to use them
- `InheritedWidget` as the foundation for state management
- Sliver-based scrolling for performance
- `LayoutBuilder` / `CustomPainter` / `CustomSingleChildLayout` for custom UI
- Performance: `const` constructors, `RepaintBoundary`, `ListView.builder`
