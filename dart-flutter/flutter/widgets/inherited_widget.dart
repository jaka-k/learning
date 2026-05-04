// =============================================================================
// INHERITED WIDGET
// =============================================================================
// NOTE: This file is NOT runnable standalone. It requires a Flutter project
// with the Flutter SDK configured. It is intended as a learning reference.
//
// InheritedWidget is the fundamental mechanism for propagating data DOWN the
// widget tree in Flutter. It is the foundation on which Provider, Riverpod,
// Theme, MediaQuery, Navigator, Localizations, and essentially every Flutter
// framework feature that passes data through the tree is built.
//
// Understanding InheritedWidget means you understand *how* all state
// management solutions actually work under the hood.
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// PART 1: How InheritedWidget Works
// =============================================================================

// InheritedWidget solves a fundamental problem: how do you pass data to a
// deeply nested descendant WITHOUT threading it through every intermediate
// constructor?
//
// Without InheritedWidget (prop drilling):
//   App → Screen → Section → List → Item → Detail → Button
//   Each layer must accept and pass down the data even if it doesn't use it.
//
// With InheritedWidget:
//   App wraps with InheritedWidget (holds the data)
//   Button calls MyInherited.of(context) — done. No intermediate layers involved.
//
// THE MECHANISM:
// Every BuildContext has a reference to its position in the element tree.
// When you call context.dependOnInheritedWidgetOfExactType<T>(), Flutter:
//   1. Walks UP the element tree looking for an element of type T
//   2. When found, REGISTERS the calling element as a "dependent" of that InheritedElement
//   3. Returns the InheritedWidget data
//
// When the InheritedWidget is replaced (its data changes), Flutter:
//   1. Calls updateShouldNotify() on the new vs old InheritedWidget
//   2. If true, marks all registered dependents as dirty → they rebuild
//   3. Only the registered dependents rebuild — not siblings, not non-dependents

// =============================================================================
// PART 2: InheritedWidget is Immutable
// =============================================================================

// InheritedWidget itself is immutable — just like any other widget. It can't
// update its own data. To change the data it provides, you must REPLACE the
// InheritedWidget in the tree with a new instance containing new data.
//
// This is done by wrapping the InheritedWidget in a StatefulWidget:
//   StatefulWidget holds the data (mutable state)
//   InheritedWidget wraps the child tree and provides the data
//   When StatefulWidget calls setState, it rebuilds, creating a new InheritedWidget
//   instance with the updated data. The new InheritedWidget replaces the old one.

// =============================================================================
// PART 3: Building an InheritedWidget from Scratch
// =============================================================================

// Our custom theme data — what we want to propagate through the tree
class AppThemeData {
  final Color primaryColor;
  final Color backgroundColor;
  final double baseFontSize;
  final bool isDark;

  const AppThemeData({
    required this.primaryColor,
    required this.backgroundColor,
    required this.baseFontSize,
    required this.isDark,
  });

  // Light theme preset
  static const light = AppThemeData(
    primaryColor: Color(0xFF6200EE),
    backgroundColor: Color(0xFFFFFFFF),
    baseFontSize: 16.0,
    isDark: false,
  );

  // Dark theme preset
  static const dark = AppThemeData(
    primaryColor: Color(0xFFBB86FC),
    backgroundColor: Color(0xFF121212),
    baseFontSize: 16.0,
    isDark: true,
  );

  // copyWith — since this is immutable data, to "update" it we create a new
  // instance with selective field changes. This is the standard Dart pattern
  // for immutable value objects.
  AppThemeData copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    double? baseFontSize,
    bool? isDark,
  }) {
    return AppThemeData(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      isDark: isDark ?? this.isDark,
    );
  }
}

// THE INHERITED WIDGET
// This widget sits in the tree and "broadcasts" AppThemeData to all descendants.
// Immutable — all fields must be final.
class AppTheme extends InheritedWidget {
  // The data being propagated. Final, because InheritedWidget is immutable.
  final AppThemeData data;

  const AppTheme({
    super.key,
    required this.data,
    required super.child, // The widget subtree that has access to this data
  });

  // THE STATIC `of` METHOD — the conventional access pattern.
  // Every InheritedWidget should have a static method like this.
  // It provides a clean API: `AppTheme.of(context)` instead of
  // `context.dependOnInheritedWidgetOfExactType<AppTheme>()!.data`
  //
  // `dependOnInheritedWidgetOfExactType<T>()` does TWO things:
  //   1. Finds the nearest ancestor of type T
  //   2. REGISTERS the calling widget as a dependent
  //      → When this InheritedWidget's updateShouldNotify returns true,
  //        the dependent widget will rebuild
  //
  // This is the version that REGISTERS the dependency (rebuilds on change).
  static AppThemeData of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<AppTheme>();
    assert(inherited != null, 'No AppTheme found in context. '
        'Make sure to wrap your widget tree with AppTheme.');
    return inherited!.data;
  }

  // Optional: a NON-registering lookup for one-time reads that don't need
  // to trigger rebuilds when the theme changes.
  // Use `getElementForInheritedWidgetOfExactType` instead:
  static AppThemeData? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AppTheme>()?.data;
    // `getInheritedWidgetOfExactType` (no "depend") does NOT register a dependency
  }

  // UPDATESHOULDNOTIFY — The rebuild gate.
  // Called by Flutter when this InheritedWidget is replaced by a new instance.
  // `oldWidget` is the previous InheritedWidget. `this` is the new one.
  //
  // Return true → all registered dependents WILL rebuild
  // Return false → dependents WON'T rebuild (even if data technically changed)
  //
  // Be accurate here. Returning false incorrectly means widgets show stale data.
  // Returning true unnecessarily causes extra rebuilds.
  //
  // Most implementations just check if the data changed:
  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return data != oldWidget.data;
    // Since AppThemeData is a plain class (not @immutable with const), this is
    // a reference comparison (same object? → false, different object? → true).
    // For value equality, AppThemeData would need to implement == (or use Equatable/freezed).
  }
}

// =============================================================================
// PART 4: The Standard Pattern — StatefulWidget + InheritedWidget
// =============================================================================

// To make the InheritedWidget's data CHANGEABLE, wrap it in a StatefulWidget.
// The StatefulWidget holds the mutable state (the AppThemeData).
// When state changes (via setState), it rebuilds, creating a new AppTheme
// (InheritedWidget) instance with the new data. Flutter detects the replacement
// and calls updateShouldNotify to decide whether dependents need to rebuild.

class AppThemeProvider extends StatefulWidget {
  final AppThemeData initialTheme;
  final Widget child;

  const AppThemeProvider({
    super.key,
    required this.child,
    this.initialTheme = AppThemeData.light,
  });

  // Convenience method to get the NOTIFIER (State) from context.
  // This does NOT register a rebuild dependency — use it only in callbacks
  // where you want to call methods to change the theme.
  // Pattern: Provider.of(context, listen: false) equivalent.
  static _AppThemeProviderState? _stateOf(BuildContext context) {
    // `findAncestorStateOfType` walks up looking for a State of the given type.
    // This is NOT InheritedWidget — no dependency registration.
    return context.findAncestorStateOfType<_AppThemeProviderState>();
  }

  // Convenience method to toggle theme from any descendant
  static void toggleTheme(BuildContext context) {
    _stateOf(context)?._toggleTheme();
  }

  @override
  State<AppThemeProvider> createState() => _AppThemeProviderState();
}

class _AppThemeProviderState extends State<AppThemeProvider> {
  late AppThemeData _themeData;

  @override
  void initState() {
    super.initState();
    _themeData = widget.initialTheme;
  }

  void _toggleTheme() {
    setState(() {
      // Create a NEW AppThemeData object (we don't mutate the existing one).
      // This ensures updateShouldNotify's `!=` check returns true (different object).
      _themeData = _themeData.isDark ? AppThemeData.light : AppThemeData.dark;
    });
  }

  void updateTheme(AppThemeData newTheme) {
    setState(() => _themeData = newTheme);
  }

  @override
  Widget build(BuildContext context) {
    // Every time setState is called in this State, we rebuild — which means
    // we create a new AppTheme InheritedWidget with the updated data.
    // Flutter sees the replacement, calls updateShouldNotify, and if true,
    // rebuilds all dependents.
    return AppTheme(
      data: _themeData,
      child: widget.child,  // Pass through the child unchanged
    );
  }
}

// A widget that uses the theme via InheritedWidget lookup:
class ThemedCard extends StatelessWidget {
  final String title;
  final String body;

  const ThemedCard({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    // This call registers ThemedCard as a dependent of the nearest AppTheme.
    // When AppTheme's data changes, ThemedCard will rebuild.
    final theme = AppTheme.of(context);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: theme.baseFontSize * 1.25,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: theme.baseFontSize,
              color: theme.isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// A button that changes the theme — does NOT need to rebuild when theme changes
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    // We read if we're in dark mode to show the right icon.
    // This DOES register a dependency — the icon changes when theme changes.
    final isDark = AppTheme.of(context).isDark;

    return IconButton(
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      onPressed: () {
        // This does NOT use AppTheme.of (no rebuild registration).
        // It just triggers the toggle action on the provider's State.
        AppThemeProvider.toggleTheme(context);
      },
    );
  }
}

// =============================================================================
// PART 5: InheritedModel — Granular Rebuild Control
// =============================================================================

// InheritedWidget has a binary choice: rebuild ALL dependents or NONE.
// InheritedModel allows dependents to specify WHICH "aspect" of the data
// they depend on. They only rebuild when that specific aspect changes.
//
// Example: an InheritedModel holding {counter, username}.
// A widget that only shows the counter doesn't need to rebuild when username changes.

// Define the aspects as an enum or String constants
enum AppStateAspect { counter, username }

class AppState extends InheritedModel<AppStateAspect> {
  final int counter;
  final String username;

  const AppState({
    super.key,
    required this.counter,
    required this.username,
    required super.child,
  });

  // Standard `of` — subscribes to ALL aspects (equivalent to InheritedWidget)
  static AppState of(BuildContext context) {
    return InheritedModel.inheritFrom<AppState>(context)!;
  }

  // Aspect-specific `of` — subscribes ONLY to the given aspect
  static AppState ofAspect(BuildContext context, AppStateAspect aspect) {
    return InheritedModel.inheritFrom<AppState>(context, aspect: aspect)!;
  }

  @override
  bool updateShouldNotify(AppState oldWidget) {
    // Called first — if false, updateShouldNotifyDependent is never called
    return counter != oldWidget.counter || username != oldWidget.username;
  }

  @override
  bool updateShouldNotifyDependent(
    AppState oldWidget,
    Set<AppStateAspect> dependencies,
  ) {
    // `dependencies` is the set of aspects this specific dependent subscribed to.
    // Only rebuild if the aspects they care about actually changed.
    if (dependencies.contains(AppStateAspect.counter)) {
      if (counter != oldWidget.counter) return true;
    }
    if (dependencies.contains(AppStateAspect.username)) {
      if (username != oldWidget.username) return true;
    }
    return false;
  }
}

// This widget only rebuilds when the counter changes, not when username changes:
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    // Only subscribes to the `counter` aspect
    final state = AppState.ofAspect(context, AppStateAspect.counter);
    return Text('Counter: ${state.counter}');
  }
}

// This widget only rebuilds when the username changes:
class UsernameDisplay extends StatelessWidget {
  const UsernameDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.ofAspect(context, AppStateAspect.username);
    return Text('User: ${state.username}');
  }
}

// =============================================================================
// PART 6: Theme.of(context) — A Familiar InheritedWidget Example
// =============================================================================

// Flutter's own Theme is implemented exactly like our AppTheme above.
// MaterialApp builds a Theme widget internally:
//
//   Theme (InheritedWidget) {
//     data: ThemeData(...)    ← The propagated data
//     child: ...              ← Your app's widget tree
//   }
//
// When you call Theme.of(context):
//   → context.dependOnInheritedWidgetOfExactType<Theme>()!.data
//   → Registers the caller as a dependent
//   → Returns ThemeData
//
// When you call Navigator.of(context):
//   → Same pattern, but for NavigatorState
//
// When you call MediaQuery.of(context):
//   → Same pattern, but for MediaQueryData
//   → MediaQueryData includes screen size, orientation, text scale, etc.
//
// ALL of these are InheritedWidget under the hood. Understanding one means
// understanding all of them.

// =============================================================================
// PART 7: How Provider, Riverpod, and Theme Build on InheritedWidget
// =============================================================================

// Provider (the package) is essentially:
//   ChangeNotifierProvider → StatefulWidget wrapping an InheritedWidget
//   The InheritedWidget holds the ChangeNotifier
//   context.watch<T>() → dependOnInheritedWidgetOfExactType + listen to notifier
//   context.read<T>() → getInheritedWidgetOfExactType (no dependency registration)
//   context.select<T,R>() → dependOnInheritedWidgetOfExactType + compare selected value
//
// Riverpod is NOT directly built on InheritedWidget. It uses a single
// ProviderScope (a StatefulWidget with an InheritedWidget-like structure) that
// holds all providers in a container. But the mechanisms for notifying and
// rebuilding widgets use Flutter's rebuild scheduling, similar in spirit.
//
// The key insight: all Flutter state management is ultimately about:
//   1. Storing data somewhere (outside the widget)
//   2. Triggering widget rebuilds when data changes
//   3. Providing efficient access to data from arbitrary widget depths

// =============================================================================
// PART 8: Full Usage Example
// =============================================================================

class InheritedWidgetDemoApp extends StatelessWidget {
  const InheritedWidgetDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppThemeProvider wraps the entire tree, making AppTheme data available
    // to all descendants.
    return AppThemeProvider(
      initialTheme: AppThemeData.light,
      child: Builder(
        // Builder is needed here because we need a BuildContext that is a
        // DESCENDANT of AppThemeProvider. The context in THIS build() is
        // the parent of AppThemeProvider, so it cannot see AppTheme.
        // Builder creates a new context that IS a descendant.
        builder: (context) {
          // Now we can access the theme from context
          final theme = AppTheme.of(context);
          return MaterialApp(
            title: 'InheritedWidget Demo',
            theme: ThemeData(
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
            ),
            home: const _DemoScreen(),
          );
        },
      ),
    );
  }
}

class _DemoScreen extends StatelessWidget {
  const _DemoScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InheritedWidget Demo'),
        actions: const [
          // ThemeToggleButton reads and depends on AppTheme
          ThemeToggleButton(),
        ],
      ),
      body: const Column(
        children: [
          ThemedCard(
            title: 'Welcome',
            body: 'This card reads its styles from the AppTheme InheritedWidget.',
          ),
          ThemedCard(
            title: 'How It Works',
            body: 'Toggle the theme button. Both cards rebuild because both '
                  'called AppTheme.of(context) and registered as dependents.',
          ),
        ],
      ),
    );
  }
}
