// =============================================================================
// STATELESS WIDGETS
// =============================================================================
// NOTE: This file is NOT runnable standalone. It requires a Flutter project
// with the Flutter SDK configured. It is intended as a learning reference.
// To run Flutter code: `flutter create my_app`, then replace lib/main.dart.
//
// StatelessWidget is the simplest kind of Flutter widget. It describes part of
// the user interface that can be fully described by its configuration (the
// constructor arguments it receives). It has no mutable state.
// =============================================================================

import 'package:flutter/material.dart';

// =============================================================================
// PART 1: StatelessWidget Anatomy
// =============================================================================

// A StatelessWidget is a widget whose appearance depends entirely on:
//   1. The configuration passed to its constructor (immutable fields)
//   2. The ambient state from InheritedWidgets (Theme, MediaQuery, etc.)
//
// It does NOT manage any state of its own. Every time the parent rebuilds
// and passes new configuration, Flutter calls build() again. The widget
// itself is recreated from scratch (widget objects are cheap/short-lived
// in Flutter — the heavy-lifting is in the Element and RenderObject trees).
//
// The @immutable annotation is a signal (enforced by the analyzer when
// you use `package:meta`) that this class should have no mutable fields.
// Flutter's StatelessWidget already requires this at the framework level,
// but the annotation makes it explicit and lets the linter warn you if
// you accidentally add a non-final field.
@immutable
class MyLabel extends StatelessWidget {
  // All fields in a StatelessWidget MUST be final.
  // This is required for const constructors (see below) AND is semantically
  // correct — a StatelessWidget's configuration should never change after
  // construction (if it needs to change, you need StatefulWidget instead).
  final String text;
  final TextStyle? style;

  // CONST CONSTRUCTORS: The most important optimization in Flutter widget code.
  //
  // When a constructor is `const`, the Dart compiler can create the object
  // at compile time and reuse the same instance whenever the same arguments
  // are passed. This means Flutter's reconciliation algorithm can detect that
  // this widget hasn't changed (same instance in memory) and skip rebuilding
  // the subtree entirely.
  //
  // Requirements for a const constructor:
  //   1. All fields must be final
  //   2. All field values must be const-able (primitives, const objects, enums)
  //   3. The class must not extend a non-const class with non-const fields
  //      (StatelessWidget is const-compatible)
  //
  // Without const: Flutter must compare the old and new widget configurations
  // during reconciliation (checking each field). With const: Flutter can use
  // `identical()` — a single pointer comparison — which is O(1) and essentially free.
  const MyLabel({
    super.key, // The `super.key` forwarding pattern (Dart 2.17+). Equivalent
               // to: MyLabel({Key? key, ...}) : super(key: key);
               // The `key` parameter is defined in Widget base class.
    required this.text,
    this.style,
  });

  // build() is called whenever this widget's configuration changes OR when
  // an InheritedWidget ancestor it depends on changes (e.g., Theme changes,
  // MediaQuery changes like orientation flip).
  //
  // The @override annotation documents that we're overriding a method from
  // the superclass (Widget/StatelessWidget). The analyzer warns if the
  // signature doesn't match a parent method, catching typos in method names.
  //
  // BuildContext: A handle to the location of this widget in the widget tree.
  // It's used to:
  //   - Look up InheritedWidgets: Theme.of(context), MediaQuery.of(context)
  //   - Navigate: Navigator.of(context)
  //   - Show overlays: showDialog(context: context, ...)
  //   - Find ancestors: context.findAncestorStateOfType<MyState>()
  // IMPORTANT: Never store a BuildContext in a field. It can become invalid
  // (the widget might unmount). Use it synchronously inside build() or callbacks.
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.bodyMedium,
      // Theme.of(context) is an InheritedWidget lookup — it registers this
      // widget as a dependent of the nearest Theme. If the theme changes
      // (e.g., user switches dark/light mode), this widget will rebuild.
    );
  }
}

// =============================================================================
// PART 2: Widget Identity vs Configuration
// =============================================================================

// Flutter's reconciliation ("diffing") algorithm works on the widget tree.
// When parent rebuilds, Flutter compares the OLD widget tree with the NEW
// widget tree to figure out what actually changed.
//
// Flutter uses TWO criteria to decide if a widget is the "same" widget:
//   1. runtimeType must match
//   2. key must match (or both must be null)
//
// If both match, Flutter considers it the same widget and just updates the
// configuration (calls didUpdateWidget if stateful). If either differs,
// Flutter destroys the old element and creates a new one.
//
// The CONFIGURATION is the widget object itself — its constructor args.
// const widgets short-circuit this entire comparison with `identical()`.

// Example: Understanding when build() is called
class ParentWidget extends StatelessWidget {
  const ParentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Each time ParentWidget rebuilds:
    //   - If Flutter sees `const MyLabel(text: 'hello')` and the previous
    //     render also had `const MyLabel(text: 'hello')`, they are literally
    //     the SAME object in memory (const canonicalization). Flutter skips
    //     rebuilding MyLabel entirely.
    //   - If it's NOT const (e.g., using a variable), Flutter creates a new
    //     MyLabel instance and must compare it with the previous one.
    return const Column(
      children: [
        // These const widgets will NEVER rebuild due to ParentWidget rebuilding.
        // The `const` keyword here applies to the Column AND propagates down —
        // the entire subtree is a compile-time constant.
        MyLabel(text: 'Static header'),
        Padding(
          padding: EdgeInsets.all(16),  // EdgeInsets.all(16) is const
          child: MyLabel(text: 'Static body'),
        ),
      ],
    );
  }
}

// =============================================================================
// PART 3: Keys and StatelessWidgets
// =============================================================================

// Keys help Flutter match widgets in the old and new trees when the type alone
// is ambiguous. For StatelessWidgets in simple layouts, you rarely need keys.
//
// You NEED keys when:
//   - Reordering widgets of the same type in a list
//   - Preserving State when widgets move around (keys apply to StatefulWidget State)
//
// For StatelessWidgets, keys matter primarily in two cases:
//   1. The widget has a StatefulWidget *descendant* whose state you want preserved
//      even when the StatelessWidget moves in the tree
//   2. Performance optimization when Flutter can't efficiently reconcile without keys

class ColorTile extends StatelessWidget {
  final Color color;
  final String label;

  // const constructor — note how Color and String are const-compatible
  const ColorTile({
    super.key,  // Accept but don't require a key
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: color,
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

// In a list of same-type widgets, Flutter uses position by default.
// If you add/remove/reorder items, Flutter may misidentify which is which.
// Keys fix this:
class TileList extends StatelessWidget {
  final List<({Color color, String label})> tiles;

  const TileList({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tiles.map((tile) => ColorTile(
        // ValueKey uses the value's == for matching.
        // If `tile.label` is unique, this is a good key.
        // Flutter uses this to correctly match tiles when the list is reordered.
        key: ValueKey(tile.label),
        color: tile.color,
        label: tile.label,
      )).toList(),
    );
  }
}

// =============================================================================
// PART 4: Composing Small const Widgets for Performance
// =============================================================================

// Flutter's rendering is fast because it reuses unchanged subtrees.
// The pattern for maximum performance is to extract small, const-constructable
// widgets instead of building large monolithic build methods.

// ANTI-PATTERN: Large build method that always rebuilds entirely
class BigMonolithicWidget extends StatelessWidget {
  final String userName;
  final String userBio;
  final String? avatarUrl;

  const BigMonolithicWidget({
    super.key,
    required this.userName,
    required this.userBio,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    // If userName changes, the ENTIRE subtree (including the static header,
    // all the padding, the bio section) rebuilds. We can do better.
    return Column(
      children: [
        const Padding(  // This part is const and could be extracted
          padding: EdgeInsets.only(bottom: 8),
          child: Text('User Profile', style: TextStyle(fontSize: 24)),
        ),
        Text(userName),  // Only this actually changed
        const SizedBox(height: 4),
        Text(userBio),   // Or this
      ],
    );
  }
}

// BETTER PATTERN: Extract static parts into const widgets
class _ProfileHeader extends StatelessWidget {
  // This widget has no dynamic content — it's purely const.
  // Extract it so Flutter can skip it during parent rebuilds.
  const _ProfileHeader(); // Private constructor with underscore name (_)
                          // signals this is an internal implementation detail.
                          // No `key` needed since it won't be in lists.

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text('User Profile', style: TextStyle(fontSize: 24)),
    );
  }
}

// =============================================================================
// PART 5: Practical Examples
// =============================================================================

// -----------------------------------------------------------------------------
// Example A: Reusable const Button Widget
// -----------------------------------------------------------------------------

// Design goals:
//   - const-constructable when all params are compile-time constants
//   - Flexible enough for common use cases
//   - Clear about what can and can't be const (callbacks cannot be const)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;  // VoidCallback = void Function()
                                   // Nullable: null means the button is disabled
  final ButtonStyle? style;
  final Widget? leadingIcon;
  final bool isFullWidth;

  // Note: VoidCallback is a function type and functions are NOT const in Dart.
  // So `const AppButton(...)` is only valid if onPressed is null (compile-time).
  // In practice, you'll use `AppButton(...)` without const when providing a callback.
  //
  // However, the `const` constructor still enables const for static/disabled buttons:
  //   const AppButton(label: 'Submit') // no callback = const-able = never rebuilt
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style,
    this.leadingIcon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    // Read the theme once — this registers a dependency on the Theme
    // InheritedWidget. If the theme changes, this widget rebuilds.
    final theme = Theme.of(context);

    Widget button = ElevatedButton(
      onPressed: onPressed, // null disables the button automatically
      style: style ?? ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      child: leadingIcon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,  // Shrink-wrap the row
              children: [
                leadingIcon!,
                const SizedBox(width: 8),
                Text(label),
              ],
            )
          : Text(label),
    );

    // Optionally expand to full width
    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}

// Usage examples:
//   AppButton(label: 'Save', onPressed: () => _save())    // normal
//   AppButton(label: 'Back', onPressed: () => pop())      // normal
//   const AppButton(label: 'Loading...')                  // const (disabled)
//   AppButton(                                            // with icon
//     label: 'Download',
//     leadingIcon: const Icon(Icons.download),
//     onPressed: _download,
//     isFullWidth: true,
//   )

// -----------------------------------------------------------------------------
// Example B: ProfileCard Widget
// -----------------------------------------------------------------------------

// A data class to carry the profile information.
// Using a simple class here — in real apps you might use @freezed or records.
class UserProfile {
  final String name;
  final String title;
  final String? avatarUrl;
  final List<String> tags;

  const UserProfile({
    required this.name,
    required this.title,
    this.avatarUrl,
    this.tags = const [],  // Default to const empty list
  });
}

class ProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onTap;
  final bool isSelected;

  const ProfileCard({
    super.key,
    required this.profile,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Accessing theme from context — a dependency registration on the Theme
    // InheritedWidget. Any Theme change will trigger this widget to rebuild.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),  // const: EdgeInsets is const
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Avatar — conditional rendering based on whether URL is provided
                  CircleAvatar(
                    radius: 24,
                    // backgroundImage is not const (requires runtime URL resolution)
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    // Fallback icon when no avatar is available
                    child: profile.avatarUrl == null
                        ? const Icon(Icons.person)  // const — always the same
                        : null,
                  ),
                  const SizedBox(width: 12),  // const spacer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Tags section — only render if tags are present
              if (profile.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: profile.tags.map(_TagChip.new).toList(),
                  // _TagChip.new is a constructor tear-off — equivalent to
                  // (tag) => _TagChip(tag) but more concise. Added in Dart 2.15.
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// A small private widget for the tag chips.
// Extracted as a const-constructable widget to avoid rebuilding when ProfileCard
// re-evaluates for other reasons (like `isSelected` changing).
class _TagChip extends StatelessWidget {
  final String label;

  // Note: positional constructor parameter here (not named).
  // This enables the tear-off pattern: _TagChip.new in map()
  const _TagChip(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

// =============================================================================
// SUMMARY: StatelessWidget Rules
// =============================================================================
//
// DO:
//   ✓ Make all fields final
//   ✓ Provide a const constructor
//   ✓ Use const when instantiating widgets with known-at-compile-time values
//   ✓ Extract small private sub-widgets for static parts of a layout
//   ✓ Forward the `key` parameter via `super.key`
//   ✓ Use @override on build()
//   ✓ Use @immutable annotation
//
// DON'T:
//   ✗ Add mutable fields to a StatelessWidget
//   ✗ Store BuildContext in a field
//   ✗ Perform side effects in build() (no HTTP calls, no setState)
//   ✗ Make build() expensive — it may be called frequently
//   ✗ Use StatelessWidget when you need to manage changing data
//     (use StatefulWidget or an InheritedWidget/state management solution)
