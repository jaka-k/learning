// =============================================================================
// RIVERPOD 2.x — STATE MANAGEMENT
// =============================================================================
// NOTE: This file is NOT runnable standalone. It requires a Flutter project
// with Riverpod. Add to pubspec.yaml:
//   dependencies:
//     flutter_riverpod: ^2.5.1
//     riverpod_annotation: ^2.3.5
//   dev_dependencies:
//     riverpod_generator: ^2.4.0
//     build_runner: ^2.4.9
//
// This file shows BOTH the manual style (no code gen) and annotates where the
// code-gen (@riverpod annotation) approach would differ.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// PART 1: Why Riverpod Over Provider?
// =============================================================================

// PROVIDER'S LIMITATIONS (the problems Riverpod solves):
//
// 1. RUNTIME ERRORS FROM WRONG CONTEXT
//    Provider requires a BuildContext to read providers. Accessing a provider
//    before it's in the tree, or from the wrong scope, causes runtime crashes.
//    Riverpod providers are global objects — no context needed to create or
//    read them (outside of widget builds).
//
// 2. NO PROVIDER FROM ANOTHER PROVIDER (without ProxyProvider boilerplate)
//    With Provider, a provider depending on another requires ProxyProvider setup.
//    With Riverpod: `ref.watch(otherProvider)` inside any provider — done.
//
// 3. TESTING IS PAINFUL
//    Provider requires a real widget tree with ChangeNotifierProvider to test.
//    Riverpod: override any provider in a ProviderContainer for unit tests.
//    No widgets required.
//
// 4. COMBINING ASYNC PROVIDERS
//    FutureProvider + chaining in Provider requires complex ProxyProvider setups.
//    Riverpod: `ref.watch(asyncProvider)` in another provider — handles AsyncValue.
//
// 5. NO COMPILE-TIME SAFETY ON TYPES
//    Provider<Animal> and Provider<Dog> can conflict silently at runtime.
//    Riverpod: each provider is a typed global variable — conflicts are compile errors.

// =============================================================================
// PART 2: ProviderScope — The Root Container
// =============================================================================

// REQUIRED: Wrap the entire app in ProviderScope.
// ProviderScope creates the provider container that holds all provider state.
// It's roughly analogous to MultiProvider at the root, but for Riverpod.
//
// In tests, you create a ProviderContainer directly (no Flutter widget needed).

void main() {
  runApp(
    const ProviderScope( // Everything inside this can access any Riverpod provider
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomeScreen());
  }
}

// =============================================================================
// PART 3: Provider Types
// =============================================================================

// ---------------------------------------------------------------------------
// Provider<T> — Read-only value, synchronous, never changes
// ---------------------------------------------------------------------------
// For constants, services, or configurations that don't change.
// Dependencies provided here are computed once and cached.

final greetingProvider = Provider<String>((ref) {
  return 'Hello from Riverpod!';
  // `ref` is a ProviderRef — used to read other providers and register lifecycle hooks
});

// ---------------------------------------------------------------------------
// StateProvider<T> — Simple mutable value without complex logic
// ---------------------------------------------------------------------------
// For simple state: counters, toggles, selected tab index, filter selections.
// When state logic grows beyond a single value, migrate to NotifierProvider.

final counterProvider = StateProvider<int>((ref) {
  return 0; // Initial value
});

final isDarkModeProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// FutureProvider<T> — Async data, computed once (or on invalidation)
// ---------------------------------------------------------------------------
// Wraps a Future and exposes an AsyncValue<T> to the UI.
// AsyncValue handles the loading/error/data states for you.

// Simulated data models
class User {
  final int id;
  final String name;
  final String email;

  const User({required this.id, required this.name, required this.email});
}

// Simulated repository (in real app, this would use Dio/http)
class UserRepository {
  Future<User> fetchUser(int id) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (id == 0) throw Exception('User not found');
    return User(id: id, name: 'Alice', email: 'alice@example.com');
  }

  Stream<List<User>> watchUsers() async* {
    yield [const User(id: 1, name: 'Alice', email: 'alice@example.com')];
    await Future.delayed(const Duration(seconds: 2));
    yield [
      const User(id: 1, name: 'Alice', email: 'alice@example.com'),
      const User(id: 2, name: 'Bob', email: 'bob@example.com'),
    ];
  }
}

// Repository provider — a good place to provide service objects
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
  // In tests, override this with a mock: container.override(userRepositoryProvider.overrideWith(...))
});

// FutureProvider that depends on another provider via ref.watch
final currentUserProvider = FutureProvider<User>((ref) async {
  // ref.watch(anotherProvider) inside a provider:
  //   - Reads the value from `anotherProvider`
  //   - If `anotherProvider` changes, this FutureProvider is automatically re-executed
  final repo = ref.watch(userRepositoryProvider);
  return repo.fetchUser(1);
});

// ---------------------------------------------------------------------------
// StreamProvider<T> — Async data from a Stream (real-time updates)
// ---------------------------------------------------------------------------
// Like FutureProvider but for Streams. Automatically cancels the subscription
// when the provider is disposed (no manual StreamSubscription management).

final usersStreamProvider = StreamProvider<List<User>>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUsers();
});

// ---------------------------------------------------------------------------
// NotifierProvider<N, T> — Synchronous state with methods (replaces StateNotifierProvider)
// ---------------------------------------------------------------------------
// N = the Notifier class, T = the state type
// This is the standard choice for complex synchronous state with logic.
// Replaces StateNotifierProvider (deprecated in Riverpod 2.x).

class CounterNotifier extends Notifier<int> {
  // `build()` returns the initial state. Called once when provider is first accessed.
  @override
  int build() => 0; // Initial state

  // Methods to mutate state. Access current state via `state`.
  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
  void incrementBy(int amount) => state += amount;
}

// The provider — declares the Notifier type and creates it
final counterNotifierProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new, // Constructor tear-off: same as () => CounterNotifier()
);

// ---------------------------------------------------------------------------
// AsyncNotifierProvider<N, T> — Async state with methods
// ---------------------------------------------------------------------------
// For state that is loaded asynchronously and can be mutated.
// Combines FutureProvider (for loading) with Notifier (for mutations).

class UserNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    // Called when provider is first accessed. Returns initial async state.
    final repo = ref.watch(userRepositoryProvider);
    return repo.fetchUser(1);
  }

  // Async mutation — typical pattern for optimistic updates or API calls
  Future<void> updateName(String newName) async {
    // Pattern 1: Show loading while updating
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // AsyncValue.guard runs the async function and wraps exceptions in AsyncError
      // so you don't need try/catch
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      final currentUser = await future; // `future` gives access to current data
      return currentUser.copyWith(name: newName); // imagining copyWith exists
    });
  }
}

extension on User {
  User copyWith({String? name}) => User(id: id, name: name ?? this.name, email: email);
}

final userNotifierProvider = AsyncNotifierProvider<UserNotifier, User>(
  UserNotifier.new,
);

// =============================================================================
// PART 4: ConsumerWidget and ConsumerStatefulWidget
// =============================================================================

// ConsumerWidget replaces StatelessWidget.
// It provides a `WidgetRef ref` parameter in build() for accessing providers.
//
// ConsumerStatefulWidget replaces StatefulWidget.
// Its State class is ConsumerState<T>, which has `ref` available throughout
// the lifecycle (initState, build, dispose, etc.).

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  // Note the extra `ref` parameter in build — this is the WidgetRef
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch — registers this widget as a dependent. Rebuilds on change.
    // This is the primary way to READ data and REACT to changes.
    final counter = ref.watch(counterProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Counter: $counter'),
        actions: [
          Switch(
            value: isDark,
            onChanged: (value) {
              // ref.read — one-time access, no rebuild registration.
              // Use in callbacks. `.notifier` accesses the StateController
              // which has `.state` setter and `.update()` method.
              ref.read(isDarkModeProvider.notifier).state = value;
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          CounterDisplay(),
          UserDisplay(),
          UsersListDisplay(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Incrementing StateProvider state via the notifier
          ref.read(counterProvider.notifier).state++;
          // Or using update() for safe atomic updates:
          // ref.read(counterProvider.notifier).update((state) => state + 1);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CounterDisplay extends ConsumerWidget {
  const CounterDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using NotifierProvider — access to both state and methods
    final counter = ref.watch(counterNotifierProvider);
    final notifier = ref.watch(counterNotifierProvider.notifier);
    // `.notifier` gives you the CounterNotifier instance itself,
    // so you can call its methods directly.

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: notifier.decrement,   // Method reference
          icon: const Icon(Icons.remove),
        ),
        Text('$counter', style: const TextStyle(fontSize: 24)),
        IconButton(
          onPressed: notifier.increment,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

// =============================================================================
// PART 5: Handling AsyncValue — Loading, Error, Data
// =============================================================================

class UserDisplay extends ConsumerWidget {
  const UserDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch on a FutureProvider or AsyncNotifierProvider returns AsyncValue<T>
    // AsyncValue<T> is a sealed class with three variants:
    //   AsyncData<T>    — has data: value.data
    //   AsyncLoading<T> — loading, may have previous data: value.data (nullable)
    //   AsyncError<T>   — has error + stack trace
    final userAsync = ref.watch(currentUserProvider);

    // Pattern 1: .when() — exhaustive handling of all three states
    return userAsync.when(
      // Called when data is available
      data: (user) => ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
      ),
      // Called while loading. `hasValue` is true if there's previous cached data.
      loading: () => const Center(child: CircularProgressIndicator()),
      // Called on error. skipError: true in .when would show previous data instead.
      error: (error, stackTrace) => Text('Error: $error'),
      // Optional: skipLoadingOnRefresh: true — show old data while refreshing
      skipLoadingOnRefresh: true, // Great for pull-to-refresh UX
    );

    // Pattern 2: switch expression (Dart 3+, exhaustive via sealed class)
    // return switch (userAsync) {
    //   AsyncData(:final value) => Text(value.name),
    //   AsyncError(:final error) => Text('Error: $error'),
    //   AsyncLoading() => const CircularProgressIndicator(),
    // };

    // Pattern 3: .maybeWhen() — handle some states, provide orElse for rest
    // Pattern 4: .value — nullable, returns data or null (ignores loading/error)
    // Pattern 5: .requireValue — throws if not in data state (use carefully)
  }
}

class UsersListDisplay extends ConsumerWidget {
  const UsersListDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // StreamProvider also returns AsyncValue<T>
    final usersAsync = ref.watch(usersStreamProvider);

    return usersAsync.when(
      data: (users) => Column(
        children: users.map((u) => Text(u.name)).toList(),
      ),
      loading: () => const Text('Loading users...'),
      error: (e, st) => Text('Stream error: $e'),
    );
  }
}

// =============================================================================
// PART 6: ref.listen — Side Effects without Rebuilding
// =============================================================================

class SideEffectExample extends ConsumerStatefulWidget {
  const SideEffectExample({super.key});

  @override
  ConsumerState<SideEffectExample> createState() => _SideEffectExampleState();
}

class _SideEffectExampleState extends ConsumerState<SideEffectExample> {
  @override
  void initState() {
    super.initState();
    // ref.listen is available throughout ConsumerState (not just in build).
    // It's like a subscription: callback fires when provider value changes.
    // Used for SIDE EFFECTS: navigation, SnackBars, dialogs — NOT for rebuilding UI.
    //
    // The subscription is automatically cancelled when the State is disposed.
    ref.listen<AsyncValue<User>>(
      userNotifierProvider,
      (previous, next) {
        // `previous` is the old AsyncValue, `next` is the new one
        if (next is AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${next.error}')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// =============================================================================
// PART 7: Family Modifier — Parameterized Providers
// =============================================================================

// `.family` lets you create a provider that takes an argument.
// Think of it as a function that returns a provider for a given parameter.
// Each unique parameter value gets its own provider instance and cache.

// FutureProvider with family — fetch a specific user by ID
final userByIdProvider = FutureProvider.family<User, int>((ref, userId) async {
  // `userId` is the parameter passed when using the provider
  final repo = ref.watch(userRepositoryProvider);
  return repo.fetchUser(userId);
  // Each call with a different userId creates a separate cached provider:
  // ref.watch(userByIdProvider(1)) — own cache
  // ref.watch(userByIdProvider(42)) — own cache
});

// Using a family provider in a widget:
class UserByIdWidget extends ConsumerWidget {
  final int userId;

  const UserByIdWidget({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pass the argument when calling the family provider
    final userAsync = ref.watch(userByIdProvider(userId));
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

// Family with complex parameters — use an object with == and hashCode:
// (Riverpod uses == to identify the parameter, so make sure it's correct)
class UserFilter {
  final bool activeOnly;
  final String? nameQuery;

  const UserFilter({required this.activeOnly, this.nameQuery});

  @override
  bool operator ==(Object other) =>
    other is UserFilter &&
    other.activeOnly == activeOnly &&
    other.nameQuery == nameQuery;

  @override
  int get hashCode => Object.hash(activeOnly, nameQuery);
}

final filteredUsersProvider = FutureProvider.family<List<User>, UserFilter>(
  (ref, filter) async {
    final repo = ref.watch(userRepositoryProvider);
    final all = await repo.watchUsers().first;
    return all.where((u) =>
      filter.nameQuery == null || u.name.contains(filter.nameQuery!),
    ).toList();
  },
);

// =============================================================================
// PART 8: AutoDispose Modifier
// =============================================================================

// By default, Riverpod providers are PERSISTENT — once created, they live as
// long as the ProviderScope is alive. Their state is kept even if no widgets
// are watching them.
//
// `.autoDispose` changes this: the provider is destroyed when it has NO listeners.
// When a widget stops watching (navigates away), the provider is disposed.
// When a new widget starts watching it, it's recreated from scratch.
//
// Use autoDispose for:
//   - Screen-specific providers (don't need state beyond the screen's lifetime)
//   - Search results, filtered lists that should reset when user leaves
//   - Providers with side effects that should stop when unused (streams, polling)
//
// DON'T use autoDispose for:
//   - Global app state (user session, settings) — you want this to persist
//   - Expensive computations you want cached across screens

// autoDispose FutureProvider — disposed when no widgets are watching
final searchResultsProvider = FutureProvider.autoDispose.family<List<User>, String>(
  (ref, query) async {
    // The HTTP request is automatically cancelled if the user navigates away
    // before it completes, because the provider is disposed.
    // ref.onDispose is called when the provider is about to be disposed.
    ref.onDispose(() {
      // Cancel any in-progress work here (close streams, cancel HTTP, etc.)
      debugPrint('searchResultsProvider for "$query" was disposed');
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Debounce simulation
    final repo = ref.watch(userRepositoryProvider);
    final all = await repo.watchUsers().first;
    return all.where((u) => u.name.toLowerCase().contains(query.toLowerCase())).toList();
  },
);

// `keepAlive()` — opt a specific instance back in to persistence
// Useful inside autoDispose providers for selective caching:
final cachedSearchProvider = FutureProvider.autoDispose.family<List<User>, String>(
  (ref, query) async {
    // If query is short enough to warrant caching, keep it alive
    if (query.length < 3) {
      ref.keepAlive(); // This specific instance won't be disposed on zero listeners
    }
    return []; // Placeholder
  },
);

// =============================================================================
// PART 9: Provider Overrides — Testing and Scoping
// =============================================================================

// Overriding providers is Riverpod's killer feature for testing.
// You can replace any provider with a fake/mock implementation without
// modifying production code or injecting through constructors.

class MockUserRepository extends UserRepository {
  @override
  Future<User> fetchUser(int id) async {
    return const User(id: 1, name: 'Mock User', email: 'mock@test.com');
  }
}

// In a test:
// void main() {
//   test('UserDisplay shows user name', () async {
//     final container = ProviderContainer(
//       overrides: [
//         // Replace the real repository with a mock — no widgets needed
//         userRepositoryProvider.overrideWithValue(MockUserRepository()),
//       ],
//     );
//     addTearDown(container.dispose);
//
//     // Read the provider directly, no BuildContext required
//     final user = await container.read(currentUserProvider.future);
//     expect(user.name, 'Mock User');
//   });
// }

// In widgets, use ProviderScope's overrides for widget tests:
// testWidgets('shows mock user', (tester) async {
//   await tester.pumpWidget(
//     ProviderScope(
//       overrides: [
//         userRepositoryProvider.overrideWithValue(MockUserRepository()),
//       ],
//       child: const MaterialApp(home: UserDisplay()),
//     ),
//   );
//   await tester.pumpAndSettle();
//   expect(find.text('Mock User'), findsOneWidget);
// });

// SCOPED OVERRIDES in widget tree — override for a SUBTREE only:
// ProviderScope(
//   overrides: [
//     counterProvider.overrideWith((ref) => 42), // Only in this subtree
//   ],
//   child: SomeFeatureWidget(),
// )
// This is extremely useful for:
//   - Feature flags (override a provider with a feature-flagged implementation)
//   - Multi-instance screens (each instance gets its own provider state)
//   - Storybook/screenshot testing (seed specific states)

// =============================================================================
// PART 10: Code Generation Style (@riverpod annotation)
// =============================================================================

// With `riverpod_annotation` + `build_runner`, you can define providers like:
//
// @riverpod
// String greeting(GreetingRef ref) {
//   return 'Hello!';
// }
// // Generates: greetingProvider
//
// @riverpod
// Future<User> currentUser(CurrentUserRef ref) async {
//   final repo = ref.watch(userRepositoryProvider);
//   return repo.fetchUser(1);
// }
// // Generates: currentUserProvider (a FutureProvider)
//
// @riverpod
// class Counter extends _$Counter {
//   @override
//   int build() => 0;       // Initial state
//   void increment() => state++;
// }
// // Generates: counterProvider (a NotifierProvider)
//
// @riverpod
// class UserNotifier extends _$UserNotifier {
//   @override
//   Future<User> build(int userId) async { // `userId` makes it a .family
//     final repo = ref.watch(userRepositoryProvider);
//     return repo.fetchUser(userId);
//   }
// }
// // Generates: userNotifierProvider (an AsyncNotifierProvider.family)
//
// Benefits of code gen:
//   - Type-safe ref types (GreetingRef, CounterRef — each has only the methods relevant)
//   - autoDispose inferred from context
//   - family inferred from build() parameters
//   - Less boilerplate
//
// Run: dart run build_runner build
// Watch: dart run build_runner watch
