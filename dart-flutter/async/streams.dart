// =============================================================================
// DART STREAMS — advanced usage guide
// =============================================================================
// Run with:  dart run streams.dart
// Dart SDK:  >= 2.19 recommended
// =============================================================================

import 'dart:async';

// ---------------------------------------------------------------------------
// 1. Stream.fromIterable — synchronous source wrapped in a stream
// ---------------------------------------------------------------------------
// The values are emitted asynchronously (each emission is a separate
// microtask/event), even though the source is sync.  This prevents stack
// overflows and keeps the event loop free.
void fromIterableDemo() {
  final stream = Stream.fromIterable([1, 2, 3, 4, 5]);

  // listen() is the most fundamental way to consume a stream.
  // Returns a StreamSubscription — hold it to cancel/pause later.
  final sub = stream.listen(
    (value) => print('fromIterable: $value'),
    onError: (e, st) => print('error: $e'),
    onDone: () => print('fromIterable: done'),
    cancelOnError: false, // default false: keep listening after errors
  );
  // For a single-subscription stream like this one, sub is discarded here
  // (it auto-cancels on done), but in long-lived streams you must cancel it.
  sub; // suppress unused warning
}

// ---------------------------------------------------------------------------
// 2. Stream.periodic — emit values on a timer
// ---------------------------------------------------------------------------
// Like setInterval in JS.  The computation callback receives the event index.
// IMPORTANT: Stream.periodic creates a broadcast stream (see section 3).
Stream<String> ticker(int count) {
  return Stream.periodic(
    Duration(milliseconds: 100),
    (i) => 'tick #$i', // index starts at 0
  ).take(count); // take() limits emissions — acts like takeWhile(i < count)
}

// ---------------------------------------------------------------------------
// 3. StreamController — manually push events
// ---------------------------------------------------------------------------
// Single-subscription: only ONE listener at a time.  Dart's canonical choice
// for streams that represent sequential work (HTTP response body, file read).
// Attempting a second listener throws a StateError.
StreamController<int> makeSingleSubController() {
  final ctrl = StreamController<int>(
    onListen: () => print('SC: someone subscribed'),
    onPause: () => print('SC: subscription paused'),
    onResume: () => print('SC: subscription resumed'),
    onCancel: () => print('SC: subscription cancelled'),
  );
  return ctrl;
}

// Broadcast: MULTIPLE listeners allowed.  Events emitted while no listener is
// attached are LOST (fire-and-forget semantics).  Great for event buses,
// widget notification streams, etc.
StreamController<String> makeBroadcastController() {
  // Pass broadcast: true OR use StreamController.broadcast() constructor.
  return StreamController<String>.broadcast(
    onListen: () => print('BC: first listener attached'),
    onCancel: () => print('BC: last listener removed'),
  );
}

// ---------------------------------------------------------------------------
// 4. Stream operators
// ---------------------------------------------------------------------------
// map, where, expand, asyncMap, asyncExpand all return NEW stream objects.
// The original stream is not mutated.  Operations are lazy — no work happens
// until you listen.

Stream<int> operatorsDemo() async* {
  // Source: numbers 1..5
  final source = Stream.fromIterable(List.generate(5, (i) => i + 1));

  // map: synchronous 1-to-1 transform
  final doubled = source.map((n) => n * 2); // Stream<int>

  // where: synchronous filter
  final evens = doubled.where((n) => n % 4 == 0); // keeps multiples of 4

  // expand: 1-to-many synchronous transform (like flatMap with sync iterable)
  final expanded = Stream.fromIterable([1, 2, 3]).expand((n) => [n, n * 10]);
  // → 1, 10, 2, 20, 3, 30

  // asyncMap: 1-to-1 transform that is itself async.
  // BACKPRESSURE: asyncMap buffers upstream events while the async callback
  // runs.  If the callback is slow and upstream is fast, memory grows.
  // Use asyncExpand + a buffer/window if you need proper backpressure.
  final fetched = Stream.fromIterable([1, 2]).asyncMap((id) async {
    await Future.delayed(Duration(milliseconds: 10));
    return 'user_$id';
  });

  // asyncExpand: 1-to-many async transform.
  // Each event maps to a Stream; inner streams are concatenated in order.
  final paginated = Stream.fromIterable([1, 2]).asyncExpand((page) async* {
    yield 'page$page-item1';
    yield 'page$page-item2';
  });

  print('\n--- operators: doubled, filtered to multiples of 4 ---');
  await for (final n in evens) print(n); // 4, 8 (only 4 and 8 from 2,4,6,8,10)

  print('--- expand ---');
  await for (final v in expanded) print(v);

  print('--- asyncMap ---');
  await for (final u in fetched) print(u);

  print('--- asyncExpand (pagination) ---');
  await for (final item in paginated) print(item);

  yield 0; // this function is declared async* so must yield something
}

// ---------------------------------------------------------------------------
// 5. Debounce pattern (no built-in — implement with Timer)
// ---------------------------------------------------------------------------
// Debounce: only emit after a quiet period.  Useful for search-as-you-type.
// Dart has no built-in debounce operator, but it's easy to build with a
// StreamController + Timer.
Stream<T> debounce<T>(Stream<T> source, Duration delay) {
  final ctrl = StreamController<T>();
  Timer? timer;

  final sub = source.listen(
    (event) {
      timer?.cancel(); // reset the timer on each new event
      timer = Timer(delay, () => ctrl.add(event)); // emit after quiet period
    },
    onError: ctrl.addError,
    onDone: () {
      timer?.cancel();
      ctrl.close();
    },
  );

  // Forward cancellation from the output stream back to the source.
  ctrl.onCancel = () {
    timer?.cancel();
    sub.cancel();
  };

  return ctrl.stream;
}

// ---------------------------------------------------------------------------
// 6. Terminal operations: first, last, single
// ---------------------------------------------------------------------------
// These convert a Stream into a Future — they "drain" the stream.
// first: completes with the first event (cancels the rest).
// last:  must consume the ENTIRE stream; returns the last event.
// single: must produce EXACTLY one event; throws if 0 or 2+ events.
Future<void> terminalOpsDemo() async {
  final stream = Stream.fromIterable([10, 20, 30]);

  final first = await stream.first; // 10
  // NOTE: after .first returns, the stream is cancelled — you cannot re-use it.
  // Each terminal op needs its own stream instance.
  final last = await Stream.fromIterable([10, 20, 30]).last; // 30
  final single = await Stream.fromIterable([42]).single; // 42

  print('first=$first, last=$last, single=$single');

  // firstWhere / lastWhere / singleWhere — filtered variants
  final found = await Stream.fromIterable([1, 2, 3, 4])
      .firstWhere((n) => n > 2); // returns 3
  print('firstWhere > 2: $found');
}

// ---------------------------------------------------------------------------
// 7. async* generator functions — yield / yield*
// ---------------------------------------------------------------------------
// async* creates a Stream lazily.  Execution pauses at each yield until the
// subscriber requests the next event (implicit backpressure).
Stream<int> fibonacci() async* {
  int a = 0, b = 1;
  while (true) {
    yield a; // emit current value, then PAUSE until listener wants more
    final next = a + b;
    a = b;
    b = next;
  }
}

// yield* delegates to another stream/iterable, emitting all its events inline.
Stream<int> mergeSequential(Stream<int> a, Stream<int> b) async* {
  yield* a; // emit all of a, then...
  yield* b; // ...emit all of b
}

Future<void> asyncStarDemo() async {
  // take(10) is essential here — fibonacci() is infinite.
  final fibs = await fibonacci().take(10).toList();
  print('fibonacci: $fibs');

  final merged = mergeSequential(
    Stream.fromIterable([1, 2]),
    Stream.fromIterable([3, 4]),
  );
  print('merged sequential: ${await merged.toList()}');
}

// ---------------------------------------------------------------------------
// 8. StreamTransformer — reusable stream operator
// ---------------------------------------------------------------------------
// StreamTransformer<S, T> converts Stream<S> into Stream<T>.
// Use .bind(stream) or the | operator (pipe) to apply it.
// This is how map/where/etc. are implemented internally.

// A transformer that multiplies int events by a factor and filters negatives.
StreamTransformer<int, int> scaleAndFilter(int factor) {
  return StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      final scaled = data * factor;
      if (scaled >= 0) sink.add(scaled); // filter negatives
    },
    handleError: (error, stack, sink) {
      // Transform or re-throw errors.
      sink.addError('Wrapped: $error', stack);
    },
    handleDone: (sink) {
      sink.close(); // MUST close the sink when source is done
    },
  );
}

Future<void> transformerDemo() async {
  final result = await Stream.fromIterable([-1, 2, -3, 4])
      .transform(scaleAndFilter(3))
      .toList();
  print('transformer result: $result'); // [6, 12]  (-1*3 and -3*3 filtered)
}

// ---------------------------------------------------------------------------
// 9. Converting between streams and futures
// ---------------------------------------------------------------------------
// Stream → Future:  stream.first / .last / .single / .toList() / .fold()
// Future → Stream:  Stream.fromFuture(f) emits one event then closes
//                   Stream.fromFutures([f1,f2]) emits results as they resolve
Future<void> conversionDemo() async {
  // Future → Stream (single value)
  final singleStream = Stream.fromFuture(Future.value('hello'));
  print('fromFuture: ${await singleStream.first}');

  // Future → Stream (multiple, in completion order, not input order)
  final multiStream = Stream.fromFutures([
    Future.delayed(Duration(milliseconds: 30), () => 'slow'),
    Future.delayed(Duration(milliseconds: 5), () => 'fast'),
  ]);
  print('fromFutures order: ${await multiStream.toList()}'); // [fast, slow]

  // Stream → Future via fold (like List.fold but async)
  final sum = await Stream.fromIterable([1, 2, 3, 4]).fold<int>(0, (acc, n) => acc + n);
  print('stream fold sum: $sum'); // 10
}

// ---------------------------------------------------------------------------
// 10. Pause / resume a StreamSubscription
// ---------------------------------------------------------------------------
// Single-subscription streams support backpressure via pause/resume.
// Broadcast streams allow pause/resume per subscription but the source stream
// itself keeps running — events are buffered PER subscription while paused.
Future<void> pauseResumeDemo() async {
  final ctrl = StreamController<int>();
  final sub = ctrl.stream.listen((n) => print('received: $n'));

  ctrl.add(1);
  ctrl.add(2);

  sub.pause(); // buffer events from this point
  ctrl.add(3); // buffered — not yet delivered
  ctrl.add(4); // buffered

  print('subscription is paused: ${sub.isPaused}');

  // Resume after a brief delay.
  await Future.delayed(Duration(milliseconds: 20));
  sub.resume(); // delivers buffered 3 and 4

  await Future.delayed(Duration(milliseconds: 10));
  await ctrl.close();
  await sub.cancel(); // cancel is a Future — await it for clean teardown
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() async {
  print('\n--- 1. Stream.fromIterable ---');
  fromIterableDemo();
  await Future.delayed(Duration(milliseconds: 50));

  print('\n--- 2. Stream.periodic ---');
  await for (final t in ticker(3)) print(t);

  print('\n--- 3. StreamController: single-sub ---');
  final singleCtrl = makeSingleSubController();
  singleCtrl.stream.listen((n) => print('SC received: $n'), onDone: () => print('SC done'));
  singleCtrl.add(10);
  singleCtrl.add(20);
  await singleCtrl.close();

  print('\n--- 3b. StreamController: broadcast ---');
  final bcast = makeBroadcastController();
  // Two listeners on the same broadcast stream:
  bcast.stream.listen((s) => print('listener1: $s'));
  bcast.stream.listen((s) => print('listener2: $s'));
  bcast.add('event A');
  bcast.add('event B');
  await bcast.close();

  print('\n--- 4. Stream operators ---');
  await for (final _ in operatorsDemo()) {} // drain the async* demo

  print('\n--- 5. Debounce ---');
  final inputCtrl = StreamController<String>();
  final debounced = debounce(inputCtrl.stream, Duration(milliseconds: 50));
  debounced.listen((s) => print('debounced: $s'));
  inputCtrl.add('a');
  inputCtrl.add('ab');
  inputCtrl.add('abc'); // only this should emit (quiet after it)
  await Future.delayed(Duration(milliseconds: 200));
  await inputCtrl.close();

  print('\n--- 6. Terminal ops ---');
  await terminalOpsDemo();

  print('\n--- 7. async* generator ---');
  await asyncStarDemo();

  print('\n--- 8. StreamTransformer ---');
  await transformerDemo();

  print('\n--- 9. Stream ↔ Future conversion ---');
  await conversionDemo();

  print('\n--- 10. Pause/resume ---');
  await pauseResumeDemo();
}
