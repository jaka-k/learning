// =============================================================================
// DART ADVANCED ASYNC — zones, microtasks, transformers, backpressure
// =============================================================================
// Run with:  dart run advanced_async.dart
// Dart SDK:  >= 2.19
// =============================================================================

import 'dart:async';

// ---------------------------------------------------------------------------
// 1. Microtask queue vs Event queue
// ---------------------------------------------------------------------------
// Dart's event loop has TWO queues processed in strict priority order:
//
//   ┌─────────────────────────────────────────────────────────┐
//   │  1. Microtask queue   (scheduleMicrotask, Future.then)  │
//   │     → drained COMPLETELY before checking event queue    │
//   ├─────────────────────────────────────────────────────────┤
//   │  2. Event queue       (I/O, Timer, Future(() => ...))   │
//   │     → one event per cycle, then back to microtask check │
//   └─────────────────────────────────────────────────────────┘
//
// CRITICAL: never schedule infinite microtasks — they STARVE the event queue
// (timers never fire, I/O never completes).
void queueOrderDemo() {
  print('\n--- microtask vs event queue order ---');

  // Enqueue an event-queue item (Future constructor uses the event queue).
  Future(() => print('3: event queue (Future())'));

  // Enqueue a microtask.
  scheduleMicrotask(() => print('2: microtask queue (scheduleMicrotask)'));

  // Another event-queue item via Future.delayed with zero delay —
  // still goes on the event queue, after the microtask.
  Future.delayed(Duration.zero, () => print('4: event queue (Future.delayed 0)'));

  // Synchronous code runs first.
  print('1: synchronous');

  // Future.value().then() schedules the then-callback as a MICROTASK.
  Future.value(0).then((_) => print('2b: microtask (Future.value.then)'));

  // Order: 1(sync) → 2, 2b (microtasks, in schedule order) → 3, 4 (events)
}

// ---------------------------------------------------------------------------
// 2. Zone — intercepting and customising async behaviour
// ---------------------------------------------------------------------------
// A Zone is an execution context that can override:
//   • scheduleMicrotask / createTimer / createPeriodicTimer
//   • print
//   • handleUncaughtError  (the most important one in practice)
//   • registerCallback / registerUnaryCallback / registerBinaryCallback
//
// Every Dart program runs in the ROOT zone by default.
// Zone.current refers to the zone in which the current code is executing.
// Zones are inherited by async continuations (await, then, scheduleMicrotask)
// that are CREATED in that zone — this is how error propagation works.

void zoneDemo() {
  print('\n--- Zone basics ---');

  // runZoned: create a child zone with custom spec.
  runZoned(
    () {
      print('running inside custom zone');
      // scheduleMicrotask inside this zone will be intercepted.
      scheduleMicrotask(() => print('microtask inside custom zone'));
    },
    zoneSpecification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, f) {
        print('[zone intercepted scheduleMicrotask]');
        parent.scheduleMicrotask(zone, f); // must delegate to parent
      },
      print: (self, parent, zone, message) {
        parent.print(zone, '[ZONE LOG] $message'); // prefix all prints
      },
    ),
  );
  // Code here runs back in the parent zone — no more interception.
}

// ---------------------------------------------------------------------------
// 3. runZonedGuarded — top-level uncaught error handler
// ---------------------------------------------------------------------------
// The most common use of zones in Flutter/Dart apps:
// wrapping the entire app in runZonedGuarded so uncaught async errors (from
// unawaited futures, stream errors, etc.) are captured instead of crashing.
//
// In Flutter this is paired with FlutterError.onError for framework errors.
Future<void> runZonedGuardedDemo() async {
  print('\n--- runZonedGuarded ---');

  // Completer lets us wait for the guarded zone to finish.
  final done = Completer<void>();

  runZonedGuarded(
    () async {
      // Simulate a future that throws but is NOT awaited —
      // the error escapes to the zone handler, NOT to the nearest try/catch.
      unawaited(Future.error(StateError('unhandled background error')));

      await Future.delayed(Duration(milliseconds: 20));
      done.complete();
    },
    (error, stack) {
      // This is the zone's uncaught error handler.
      print('runZonedGuarded caught: $error');
      // In production: send to Sentry, Crashlytics, etc.
    },
  );

  await done.future;
}

// ---------------------------------------------------------------------------
// 4. async/await under the hood — state machine compilation
// ---------------------------------------------------------------------------
// The Dart compiler transforms async functions into a state machine.
// Each `await` is a suspension point — the compiler splits the function body
// into states and uses Future callbacks to resume.
//
// Conceptual equivalent of:
//   Future<int> example() async {
//     final a = await fetchA();
//     final b = await fetchB(a);
//     return a + b;
//   }
//
// Compiles roughly to:
//   Future<int> example() {
//     // State 0: initial
//     return fetchA().then((a) {
//       // State 1: after fetchA
//       return fetchB(a).then((b) {
//         // State 2: after fetchB
//         return a + b;
//       });
//     });
//   }
//
// Key implications:
//   • The Zone captured at the first await is used for subsequent continuations.
//   • Stack traces in async code show "async gap" — use package:stack_trace for
//     readable chains.
//   • Each await is essentially a .then() — errors propagate via Future chain.
//   • `await` only suspends the CURRENT function, not the whole isolate.

Future<int> fetchA() async => 10;
Future<int> fetchB(int a) async => a * 2;

Future<void> stateMachineNote() async {
  print('\n--- async/await state machine ---');
  // These two are semantically equivalent:
  final result1 = await fetchA().then((a) => fetchB(a)).then((b) => b + 1);
  final result2 = () async {
    final a = await fetchA();
    final b = await fetchB(a);
    return b + 1;
  }();
  print('both produce: ${await result2}, $result1');
}

// ---------------------------------------------------------------------------
// 5. Custom StreamTransformer using StreamTransformer class
// ---------------------------------------------------------------------------
// For more control than fromHandlers, implement StreamTransformer directly.
// bind() returns a new Stream; it is called when someone listens.
// The transformer must handle pause/resume signals to support backpressure.

class ThrottleTransformer<T> extends StreamTransformer<T, T> {
  final Duration interval;
  ThrottleTransformer(this.interval);

  @override
  Stream<T> bind(Stream<T> stream) {
    // Create the output controller, mirroring the input stream type.
    late StreamController<T> controller;
    late StreamSubscription<T> subscription;
    DateTime? lastEmit;

    controller = StreamController<T>(
      onListen: () {
        subscription = stream.listen(
          (event) {
            final now = DateTime.now();
            if (lastEmit == null || now.difference(lastEmit!) >= interval) {
              lastEmit = now;
              controller.add(event); // emit this event
            }
            // else: drop the event (throttle)
          },
          onError: controller.addError,
          onDone: controller.close,
        );
      },
      // Forward pause/resume to the source subscription for backpressure.
      onPause: () => subscription.pause(),
      onResume: () => subscription.resume(),
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }

  // cast() is required by StreamTransformer contract.
  @override
  StreamTransformer<RS, RT> cast<RS, RT>() =>
      StreamTransformer.castFrom<T, T, RS, RT>(this);
}

Future<void> customTransformerDemo() async {
  print('\n--- custom StreamTransformer (throttle) ---');

  // Emit 5 events rapidly; throttle should only pass the first one per 50ms.
  final source = Stream.fromIterable(List.generate(5, (i) => i));
  final throttled = source.transform(ThrottleTransformer(Duration(milliseconds: 50)));
  final results = await throttled.toList();
  print('throttled (should be 1 item per 50ms window): $results');
}

// ---------------------------------------------------------------------------
// 6. CancelableOperation pattern — manual implementation
// ---------------------------------------------------------------------------
// The `async` pub package provides CancelableOperation<T>.  Here we show how
// to build a similar concept from scratch using a Completer + flag.
//
// Use case: cancel a pending network request when the user navigates away.

class CancelableOperation<T> {
  final Future<T> _future;
  final void Function() _onCancel;
  bool _cancelled = false;

  CancelableOperation._(this._future, this._onCancel);

  factory CancelableOperation.fromFuture(
    Future<T> future, {
    void Function()? onCancel,
  }) {
    final completer = Completer<T>();
    bool cancelled = false;
    void cancelFn() {
      cancelled = true;
      onCancel?.call();
      if (!completer.isCompleted) {
        // We can't truly cancel the underlying future, but we can prevent
        // the result from propagating to callers.
        completer.completeError(CancelledException());
      }
    }

    future.then((v) {
      if (!cancelled && !completer.isCompleted) completer.complete(v);
    }).catchError((e, st) {
      if (!cancelled && !completer.isCompleted) completer.completeError(e, st);
    });

    final op = CancelableOperation<T>._(completer.future, cancelFn);
    op._cancelled = cancelled;
    return op;
  }

  Future<T> get value => _future;
  bool get isCancelled => _cancelled;
  void cancel() => _onCancel();
}

class CancelledException implements Exception {
  @override
  String toString() => 'CancelledException';
}

Future<void> cancelableDemo() async {
  print('\n--- CancelableOperation pattern ---');

  final op = CancelableOperation.fromFuture(
    Future.delayed(Duration(milliseconds: 200), () => 'network result'),
    onCancel: () => print('cancel callback: underlying request would be aborted'),
  );

  // Cancel after 50ms — before the future resolves.
  Future.delayed(Duration(milliseconds: 50), () => op.cancel());

  try {
    final result = await op.value;
    print('result: $result'); // won't print
  } on CancelledException {
    print('operation was cancelled (as expected)');
  }
}

// ---------------------------------------------------------------------------
// 7. Backpressure in streams
// ---------------------------------------------------------------------------
// Backpressure = the consumer controlling the rate of the producer.
// Single-subscription streams support it natively via pause/resume.
// asyncMap does NOT implement proper backpressure — it buffers upstream events.
//
// For true backpressure, use a manual controller + subscription pause/resume.

Stream<int> fastProducer() async* {
  for (int i = 0; i < 10; i++) {
    print('  producer: emitting $i');
    yield i;
  }
}

Future<void> backpressureDemo() async {
  print('\n--- backpressure with pause/resume ---');

  // Manual buffering stream with backpressure:
  // When the consumer is busy, we pause the producer.
  final controller = StreamController<int>();
  late StreamSubscription<int> sourceSub;

  sourceSub = fastProducer().listen(
    (event) {
      // Pause the source while we "process" this event.
      sourceSub.pause();
      // Simulate slow consumer.
      Future.delayed(Duration(milliseconds: 30), () {
        controller.add(event);
        sourceSub.resume(); // now ready for next event
      });
    },
    onDone: () => Future.delayed(Duration(milliseconds: 50), controller.close),
  );

  // Collect results (should still be 0..9, just slowed down).
  final results = await controller.stream.toList();
  print('backpressure results (all 10, rate-limited): $results');
}

// ---------------------------------------------------------------------------
// 8. Zone overriding createTimer — custom scheduler
// ---------------------------------------------------------------------------
// Useful for testing (fake timers), performance monitoring, or rate limiting
// all timer creation in a subsystem.
void timerZoneOverrideDemo() {
  print('\n--- Zone overriding createTimer ---');

  int timerCount = 0;

  runZoned(
    () {
      // These Timers will be intercepted.
      Timer(Duration(milliseconds: 10), () => print('timer A fired'));
      Timer(Duration(milliseconds: 20), () => print('timer B fired'));
      print('scheduled $timerCount timers via custom zone');
    },
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) {
        timerCount++;
        print('[zone] creating timer #$timerCount (duration: $duration)');
        return parent.createTimer(zone, duration, callback);
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() async {
  queueOrderDemo();
  await Future.delayed(Duration(milliseconds: 50)); // let event queue drain

  zoneDemo();
  await Future.delayed(Duration(milliseconds: 10));

  await runZonedGuardedDemo();
  await stateMachineNote();
  await customTransformerDemo();
  await cancelableDemo();
  await backpressureDemo();

  timerZoneOverrideDemo();
  await Future.delayed(Duration(milliseconds: 50)); // let timers fire
}
