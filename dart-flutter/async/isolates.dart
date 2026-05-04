// =============================================================================
// DART ISOLATES — advanced usage guide
// =============================================================================
// Run with:  dart run isolates.dart
// Dart SDK:  >= 2.19 (Isolate.run requires 2.19+)
// =============================================================================

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data'; // for TransferableTypedData demo

// ---------------------------------------------------------------------------
// WHY ISOLATES?
// ---------------------------------------------------------------------------
// Dart is single-threaded per isolate.  A single isolate cannot block on
// CPU work without freezing the event loop (and thus the UI in Flutter).
//
// Isolates solve this with TRUE parallelism:
//   • Each isolate has its OWN heap — NO shared memory.
//   • Communication only via message passing (SendPort / ReceivePort).
//   • Messages are COPIED (not referenced), except for a few special types.
//
// Sendable types (can be passed between isolates):
//   ✔ Primitives: null, bool, int, double, String
//   ✔ List, Map (containing only sendable types, recursively)
//   ✔ Uint8List and other typed data (copied)
//   ✔ TransferableTypedData (ZERO-COPY transfer — ownership moves)
//   ✔ SendPort, ReceivePort (for port references)
//   ✔ Capability, RegExp, Uri, DateTime, StackTrace
//   ✗ Closures / functions (NOT sendable — use top-level or static methods)
//   ✗ Arbitrary class instances with custom native state
//   ✗ Streams, Futures, StreamControllers

// ---------------------------------------------------------------------------
// 1. Isolate.run — simplest API for one-shot background work (Dart 2.19+)
// ---------------------------------------------------------------------------
// Isolate.run spawns a new isolate, runs the callback, returns the result,
// then tears the isolate down.  The callback MUST be a top-level or static
// function (no closures capturing local state across isolate boundary).
//
// Internally Isolate.run does the spawn + port handshake for you.
int _heavyComputation(int input) {
  // Simulate CPU-intensive work (e.g., JSON parsing, image decoding).
  int result = 0;
  for (int i = 0; i < input; i++) {
    result += i;
  }
  return result;
}

Future<void> isolateRunDemo() async {
  print('main isolate: starting heavy computation via Isolate.run');

  // Dart 2.19+: Isolate.run accepts a top-level/static function.
  // The argument is passed as a closure capture — Dart copies primitives.
  final result = await Isolate.run(() => _heavyComputation(1000000));

  print('Isolate.run result: $result'); // 499999500000

  // Error handling: if the isolate throws, Isolate.run re-throws in the
  // calling isolate wrapped in a RemoteError (or the original if sendable).
  try {
    await Isolate.run(() => throw FormatException('bad data from isolate'));
  } catch (e) {
    print('caught from Isolate.run: $e');
  }
}

// ---------------------------------------------------------------------------
// 2. Isolate.spawn — full control
// ---------------------------------------------------------------------------
// spawn() gives you direct access to the isolate lifecycle and ports.
// The entry point must be a TOP-LEVEL or STATIC function taking ONE argument
// (the message passed via the second argument of spawn).
//
// Pattern: pass a SendPort as the initial message so the spawned isolate can
// send results back.

// Entry point for the spawned isolate (must be top-level).
void _isolateEntryPoint(SendPort sendPort) {
  // The spawned isolate runs this function in its own event loop.
  print('[spawned isolate] started');

  // Do some work.
  final data = List.generate(5, (i) => i * i); // [0,1,4,9,16]

  // Send result back to the main isolate.
  sendPort.send(data);

  // The isolate will exit when this function returns (unless it has open
  // ports keeping the event loop alive).
}

Future<void> isolateSpawnDemo() async {
  // Create a ReceivePort in the main isolate to receive messages.
  final receivePort = ReceivePort();

  // Spawn the isolate, passing our SendPort as the initial message.
  final isolate = await Isolate.spawn(
    _isolateEntryPoint,
    receivePort.sendPort, // passed as the single argument
    debugName: 'worker-isolate', // visible in Observatory / DevTools
    errorsAreFatal: true, // default; uncaught errors kill the isolate
  );

  // Wait for one message then close the port.
  final result = await receivePort.first;
  print('spawned isolate result: $result'); // [0, 1, 4, 9, 16]

  receivePort.close(); // close port so main isolate event loop can exit
  isolate.kill(priority: Isolate.beforeNextEvent); // explicit cleanup (optional)
}

// ---------------------------------------------------------------------------
// 3. Bidirectional communication
// ---------------------------------------------------------------------------
// For ongoing communication (e.g., a worker that processes many tasks) use
// two ports: one for main→worker, one for worker→main.

// Message protocol: a simple sealed-style class approach.
// Since class instances aren't sendable, use plain maps or lists for messages.
// Convention: {'cmd': 'process', 'payload': ...}

void _bidirectionalWorker(SendPort mainSendPort) {
  // Create OUR receive port inside the spawned isolate.
  final workerReceivePort = ReceivePort();

  // First thing: send our SendPort to the main isolate so it can reach us.
  mainSendPort.send(workerReceivePort.sendPort);

  // Process messages in a loop.
  workerReceivePort.listen((message) {
    if (message is Map) {
      final cmd = message['cmd'] as String;
      if (cmd == 'echo') {
        mainSendPort.send({'result': (message['data'] as String).toUpperCase()});
      } else if (cmd == 'shutdown') {
        workerReceivePort.close(); // closing port exits the isolate event loop
      }
    }
  });
}

Future<void> bidirectionalDemo() async {
  final mainReceivePort = ReceivePort();
  await Isolate.spawn(_bidirectionalWorker, mainReceivePort.sendPort);

  // The worker's FIRST message is its own SendPort.
  final SendPort workerSendPort = await mainReceivePort.first as SendPort;

  // Now use a broadcast stream for subsequent messages (ReceivePort is a
  // single-subscription stream; cast to broadcast to listen multiple times).
  final responses = mainReceivePort.asBroadcastStream();

  workerSendPort.send({'cmd': 'echo', 'data': 'hello from main'});
  final r1 = await responses.first;
  print('bidirectional response: ${r1['result']}'); // HELLO FROM MAIN

  workerSendPort.send({'cmd': 'echo', 'data': 'second message'});
  final r2 = await responses.first;
  print('bidirectional response: ${r2['result']}'); // SECOND MESSAGE

  workerSendPort.send({'cmd': 'shutdown'});
  await Future.delayed(Duration(milliseconds: 50));
  mainReceivePort.close();
}

// ---------------------------------------------------------------------------
// 4. TransferableTypedData — ZERO-COPY large buffer transfer
// ---------------------------------------------------------------------------
// Copying large Uint8List between isolates is O(n).
// TransferableTypedData transfers the buffer WITHOUT copying — ownership moves
// to the receiving isolate.  The sender can no longer access it after transfer.
//
// Use case: passing raw pixel data, audio buffers, large binary payloads.

void _typedDataWorker(SendPort sendPort) {
  // Large buffer in the worker isolate.
  final buffer = Uint8List(1024 * 1024); // 1 MB
  buffer[0] = 0xDE;
  buffer[1] = 0xAD;

  // Wrap in TransferableTypedData — zero-copy on send.
  final transferable = TransferableTypedData.fromList([buffer]);
  // After this point 'buffer' is detached — reading it throws.
  sendPort.send(transferable);
}

Future<void> transferableDemo() async {
  final rp = ReceivePort();
  await Isolate.spawn(_typedDataWorker, rp.sendPort);

  final transferable = await rp.first as TransferableTypedData;
  // Materialize back into a usable typed list on the main isolate's heap.
  final data = transferable.materialize().asUint8List();
  print('TransferableTypedData: first two bytes = 0x${data[0].toRadixString(16)} 0x${data[1].toRadixString(16)}');
  rp.close();
}

// ---------------------------------------------------------------------------
// 5. Error handling across isolate boundaries
// ---------------------------------------------------------------------------
// By default, uncaught errors in a spawned isolate are fatal and print to
// stderr.  To handle them in the main isolate:
//   • Pass an error listener port via Isolate.spawn's onError parameter, OR
//   • Set errorsAreFatal: false to keep the isolate alive after errors.
//
// The error port receives a list: [errorString, stackTraceString].
// Note: the original exception is NOT sendable; it's stringified.

void _crashingWorker(SendPort _) {
  Timer(Duration(milliseconds: 10), () {
    throw StateError('worker crashed!');
  });
}

Future<void> errorHandlingDemo() async {
  final resultPort = ReceivePort();
  final errorPort = ReceivePort(); // receives [error, stackTrace] lists

  await Isolate.spawn(
    _crashingWorker,
    resultPort.sendPort,
    onError: errorPort.sendPort, // route uncaught errors here
    errorsAreFatal: false,        // don't kill the isolate on error
  );

  final error = await errorPort.first as List;
  print('isolate error intercepted: ${error[0]}'); // string of the error
  // error[1] is the stack trace as a String

  resultPort.close();
  errorPort.close();
}

// ---------------------------------------------------------------------------
// 6. compute() — Flutter's convenience wrapper
// ---------------------------------------------------------------------------
// flutter/foundation.dart exports compute(fn, arg) which is essentially:
//
//   Future<R> compute<Q, R>(FutureOr<R> Function(Q) callback, Q arg) =>
//       Isolate.run(() => callback(arg));  // simplified
//
// In Flutter apps, prefer compute() for one-shot background work because:
//   • It handles spawning/teardown automatically.
//   • Works on both mobile and web (web falls back to async).
//   • Integrates with Flutter's error reporting.
//
// Since this is a plain Dart file (not Flutter), we simulate it:
Future<R> compute<Q, R>(R Function(Q) fn, Q arg) => Isolate.run(() => fn(arg));

int _parseJson(String json) {
  // Simulate slow JSON parsing.
  return json.length; // placeholder
}

Future<void> computeDemo() async {
  final length = await compute(_parseJson, '{"key": "value"}');
  print('compute() result: $length');
}

// ---------------------------------------------------------------------------
// 7. Isolate groups (Dart 2.15+)
// ---------------------------------------------------------------------------
// By default, Isolate.spawn creates isolates in the SAME isolate group as the
// spawner.  Isolates in the same group share the HEAP for immutable data
// (class metadata, constant literals, compiled code) via "copy-on-write"
// semantics — this makes spawning faster and reduces memory overhead.
//
// Isolate.spawnUri creates an isolate in a NEW group (separate heap, slower
// spawn, needed for loading separate .dart/.js files).
//
// You cannot directly query which group an isolate belongs to from Dart code;
// this is a runtime/VM implementation detail.
//
// Key implications:
//   • Same-group isolates share compiled code → lower memory for many workers.
//   • Mutable state is STILL NOT shared — each isolate has its own mutable heap.
//   • Hot reload in Flutter updates ALL isolates in the group simultaneously.
void isolateGroupNote() {
  print('''
Isolate groups (informational):
  Isolate.spawn  → same group as parent (faster, shared code)
  Isolate.spawnUri → new group (separate VM process, slower)
  Mutable state is NEVER shared regardless of group.
  ''');
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() async {
  print('\n=== 1. Isolate.run (one-shot, Dart 2.19+) ===');
  await isolateRunDemo();

  print('\n=== 2. Isolate.spawn (full control) ===');
  await isolateSpawnDemo();

  print('\n=== 3. Bidirectional communication ===');
  await bidirectionalDemo();

  print('\n=== 4. TransferableTypedData (zero-copy) ===');
  await transferableDemo();

  print('\n=== 5. Error handling across isolate boundary ===');
  await errorHandlingDemo();

  print('\n=== 6. compute() wrapper ===');
  await computeDemo();

  print('\n=== 7. Isolate groups ===');
  isolateGroupNote();
}
