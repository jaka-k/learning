// =============================================================================
// DART FUTURES — advanced usage guide
// =============================================================================
// Run with:  dart run futures.dart
// Dart SDK:  >= 2.19 recommended
// =============================================================================

import 'dart:async';

// The `async` package ships with the Dart SDK but must be declared in
// pubspec.yaml if you want CancelableOperation.  Here we use only dart:async.

// ---------------------------------------------------------------------------
// 1. Future.value / Future.error — already-resolved futures
// ---------------------------------------------------------------------------
// Use these when you need to return a Future from a synchronous path (e.g.
// cached data, validation errors) without actually doing async work.
Future<int> cachedValue(bool useCache) {
  if (useCache) {
    // Resolves in the *next microtask*, not synchronously — important!
    // Callers that await this will still yield control once.
    return Future.value(42);
  }
  return Future.error(StateError('cache miss'), StackTrace.current);
}

// ---------------------------------------------------------------------------
// 2. async / await — syntactic sugar over Future chaining
// ---------------------------------------------------------------------------
// `async` turns a function into one that returns Future<T>.
// `await` unwraps a Future<T> into T, suspending only this function.
Future<String> fetchUser(int id) async {
  await Future.delayed(Duration(milliseconds: 50)); // simulate network
  if (id <= 0) throw ArgumentError('id must be positive');
  return 'User#$id';
}

// ---------------------------------------------------------------------------
// 3. Future.wait — run futures in PARALLEL, collect all results
// ---------------------------------------------------------------------------
// All futures start immediately (they were already created before passing to
// wait).  Future.wait merely waits for the last one to finish.
// Order of results matches order of the input list, regardless of completion
// order.
Future<void> parallelRequests() async {
  final futures = [
    Future.delayed(Duration(milliseconds: 80), () => 'A'),
    Future.delayed(Duration(milliseconds: 20), () => 'B'), // finishes first
    Future.delayed(Duration(milliseconds: 50), () => 'C'),
  ];

  final results = await Future.wait(futures);
  print('parallel results (always A,B,C order): $results');
  // → [A, B, C]
}

// ---------------------------------------------------------------------------
// 4. Future.wait with eagerError
// ---------------------------------------------------------------------------
// Default behaviour: wait collects ALL errors, then throws the first one after
// every future has settled (good for cleanup logic).
// eagerError: true — throws as soon as ANY future fails; remaining futures
// still run but their results/errors are silently discarded.
Future<void> waitEagerError() async {
  try {
    await Future.wait(
      [
        Future.delayed(Duration(milliseconds: 10), () => throw Exception('fast fail')),
        Future.delayed(Duration(milliseconds: 100), () => 'slow ok'),
      ],
      eagerError: true, // re-throw immediately on first error
    );
  } catch (e) {
    print('eagerError caught: $e'); // Exception: fast fail
  }
}

// ---------------------------------------------------------------------------
// 5. Future.any — first future to complete wins
// ---------------------------------------------------------------------------
// Useful for racing a network request against a cache lookup.
// All futures still run; only the first result is used.
Future<void> raceExample() async {
  final winner = await Future.any([
    Future.delayed(Duration(milliseconds: 100), () => 'slow'),
    Future.delayed(Duration(milliseconds: 10), () => 'fast'),
  ]);
  print('race winner: $winner'); // → fast
}

// ---------------------------------------------------------------------------
// 6. Chaining with .then().catchError().whenComplete()
// ---------------------------------------------------------------------------
// Prefer async/await for readability, but .then() is useful when you want to
// transform a future WITHOUT using async (e.g. in constructors, factories).
//
// PITFALL: .catchError() does NOT catch errors thrown inside .then() unless
// placed AFTER the .then() — it only catches errors from the previous step.
Future<void> chainingDemo() {
  return fetchUser(1)
      .then((user) {
        print('chained then: $user');
        return user.length; // transforms Future<String> → Future<int>
      })
      .catchError(
        (e) {
          // Catches errors from fetchUser AND from the .then() above.
          print('caught: $e');
          return -1; // must return same type as the successful path
        },
        // Optional test: only handle specific error types.
        test: (e) => e is ArgumentError,
      )
      .whenComplete(() {
        // Runs regardless of success or failure — like finally.
        // If whenComplete throws, that error replaces the original.
        print('whenComplete: always runs');
      });
}

// ---------------------------------------------------------------------------
// 7. Async error handling pitfalls
// ---------------------------------------------------------------------------

// PITFALL A: try/catch does NOT catch errors in unawaited futures.
Future<void> pitfallUnawaitedFuture() async {
  try {
    // ignore: unawaited_futures  ← lint suppression for demo purposes
    Future.delayed(Duration(milliseconds: 1), () => throw Exception('lost!'));
    // This exception escapes to the zone's uncaught error handler,
    // NOT to the catch block below.
    await Future.delayed(Duration(milliseconds: 10));
  } catch (e) {
    print('This will NOT print for the unawaited future above');
  }
  print('unawaited pitfall: exception above was silently swallowed');
}

// PITFALL B: try/catch scope — the await must be INSIDE the try block.
Future<void> pitfallTryCatchScope() async {
  final future = fetchUser(-1); // starts the future
  try {
    await future; // await is inside try: error IS caught here
  } catch (e) {
    print('caught correctly because await is inside try: $e');
  }
}

// ---------------------------------------------------------------------------
// 8. FutureOr<T> — a value that may or may not be async
// ---------------------------------------------------------------------------
// FutureOr<T> is the union type `T | Future<T>`.  It's used in APIs that
// accept both sync and async callbacks (e.g. onValue in .then()).
// You rarely declare your own FutureOr variables; it's mostly for API design.
FutureOr<int> maybeAsync(bool sync) {
  if (sync) return 99; // plain int satisfies FutureOr<int>
  return Future.value(99); // Future<int> also satisfies FutureOr<int>
}

// Receiving a FutureOr: await works on both cases transparently.
Future<void> consumeFutureOr() async {
  final a = await maybeAsync(true);  // int → await is a no-op
  final b = await maybeAsync(false); // Future<int> → actually suspends
  print('FutureOr results: $a, $b');
}

// ---------------------------------------------------------------------------
// 9. Completer — wrapping callback-based APIs into a Future
// ---------------------------------------------------------------------------
// Legacy libraries (e.g. old database drivers, platform channel callbacks)
// use callbacks.  Completer bridges them into the Future world.
//
// Rule: complete / completeError must be called EXACTLY once.
// Calling twice throws a StateError.
Future<String> wrapCallback() {
  final completer = Completer<String>();

  // Simulates a callback-based API (e.g. a timer, platform call, etc.)
  Timer(Duration(milliseconds: 30), () {
    // In a real scenario this would be the callback from the native layer.
    completer.complete('callback result');
    // completer.complete('again'); // ← would throw StateError
  });

  // Return the future immediately — caller awaits it.
  return completer.future;
}

// Completer.sync — completes synchronously inside the event that calls
// complete().  Use with EXTREME care; can cause subtle re-entrancy bugs.
Future<void> completerSyncDemo() async {
  final c = Completer<int>.sync();
  // With .sync, the then-callback runs synchronously during c.complete(1).
  c.future.then((v) => print('sync completer resolved with $v'));
  c.complete(1); // then-callback fires HERE, before the next line
  print('this prints AFTER the then-callback with .sync completer');
}

// ---------------------------------------------------------------------------
// 10. Future.timeout — imposing a deadline
// ---------------------------------------------------------------------------
// timeout() wraps the future and races it against a timer.
// If the timer fires first it throws TimeoutException by default,
// or calls `onTimeout` if provided.
Future<void> timeoutDemo() async {
  try {
    final result = await Future.delayed(Duration(seconds: 5), () => 'done')
        .timeout(
          Duration(milliseconds: 50),
          onTimeout: () => 'fallback value', // return a value instead of throw
        );
    print('timeout demo: $result'); // → fallback value
  } on TimeoutException catch (e) {
    print('timed out: $e');
  }
}

// Without onTimeout, TimeoutException is thrown:
Future<void> timeoutThrows() async {
  try {
    await Future.delayed(Duration(seconds: 1))
        .timeout(Duration(milliseconds: 10));
  } on TimeoutException {
    print('TimeoutException thrown as expected');
  }
}

// ---------------------------------------------------------------------------
// 11. unawaited() — intentionally ignoring a future
// ---------------------------------------------------------------------------
// The `unawaited_futures` lint warns when you discard a future silently.
// dart:async exports `unawaited()` to explicitly document the intent and
// silence the lint without suppression comments.
//
// Errors from unawaited futures propagate to the current Zone's error handler
// (see advanced_async.dart for runZonedGuarded).
Future<void> unawaitedDemo() async {
  // This fire-and-forget pattern is intentional:
  unawaited(Future.delayed(Duration(milliseconds: 10), () {
    print('background task finished (fire-and-forget)');
  }));
  // We deliberately do not await — execution continues immediately.
  print('unawaited: continued without waiting for background task');
  await Future.delayed(Duration(milliseconds: 50)); // let it finish for demo
}

// ---------------------------------------------------------------------------
// main — run all demos sequentially
// ---------------------------------------------------------------------------
void main() async {
  print('\n--- 1. Future.value / Future.error ---');
  print(await cachedValue(true)); // 42
  try {
    await cachedValue(false);
  } catch (e) {
    print('error: $e');
  }

  print('\n--- 2. async/await ---');
  print(await fetchUser(7));
  try {
    await fetchUser(-1);
  } catch (e) {
    print('fetchUser error: $e');
  }

  print('\n--- 3. Future.wait (parallel) ---');
  await parallelRequests();

  print('\n--- 4. Future.wait eagerError ---');
  await waitEagerError();

  print('\n--- 5. Future.any race ---');
  await raceExample();

  print('\n--- 6. .then().catchError().whenComplete() ---');
  await chainingDemo();

  print('\n--- 7a. unawaited future pitfall ---');
  await pitfallUnawaitedFuture();

  print('\n--- 7b. try/catch scope pitfall ---');
  await pitfallTryCatchScope();

  print('\n--- 8. FutureOr<T> ---');
  await consumeFutureOr();

  print('\n--- 9. Completer ---');
  print(await wrapCallback());
  await completerSyncDemo();

  print('\n--- 10. Future.timeout ---');
  await timeoutDemo();
  await timeoutThrows();

  print('\n--- 11. unawaited() ---');
  await unawaitedDemo();
}
