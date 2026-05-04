/// closures.dart
///
/// Advanced closure behavior in Dart.
/// Run with: dart run closures.dart

// ---------------------------------------------------------------------------
// 1. VARIABLE CAPTURE BY REFERENCE, NOT BY VALUE
// ---------------------------------------------------------------------------
// Dart closures capture the *variable binding* (the storage cell), not a
// snapshot of the value at creation time.  This means the closure always
// sees the *current* value of the captured variable, even if that value
// changed after the closure was created.

void captureByReference() {
  print('\n--- 1. Capture by reference ---');

  int counter = 0;

  // The closure captures the variable `counter`, not the integer 0.
  final increment = () => counter++;
  final read = () => counter;

  increment();
  increment();
  increment();

  // Prints 3, not 0 — the closure shares the same `counter` cell.
  print('counter via closure: ${read()}'); // 3
  print('counter directly:    $counter');  // 3 — same storage cell

  // Contrast: if Dart captured by value, `read()` would still return 0.
  // Languages like C++ with [=] capture actually copy; Dart never does this.
}

// ---------------------------------------------------------------------------
// 2. THE CLASSIC "LOOP VARIABLE CAPTURE" BUG — AND THE FIX
// ---------------------------------------------------------------------------
// Because closures capture by reference, all closures created inside a loop
// that capture the loop variable will share the *same* variable.  After the
// loop finishes, that variable holds the last value — so every closure
// returns the same (wrong) thing.

void loopCaptureBug() {
  print('\n--- 2. Loop capture bug ---');

  // BUG: `i` in a traditional for-loop is a single variable that is mutated.
  // All three closures capture the same `i`; when we call them, `i` is 3.
  final buggy = <Function>[];
  for (var i = 0; i < 3; i++) {
    buggy.add(() => i); // every closure references the SAME `i`
  }
  // After the loop `i` is 3 (the value that caused the condition to fail).
  print('buggy results: ${buggy.map((f) => f())}'); // (3, 3, 3)

  // FIX 1: Dart for-in / forEach gives each iteration its own variable.
  //         This is because `for (var x in iterable)` re-declares `x` each
  //         iteration, creating a fresh binding per closure.
  final fixed1 = <Function>[];
  for (var i in [0, 1, 2]) {
    fixed1.add(() => i); // each iteration's `i` is a distinct variable
  }
  print('fixed (for-in): ${fixed1.map((f) => f())}'); // (0, 1, 2)

  // FIX 2: Capture into a local copy inside the loop body.
  //         This works for traditional for-loops too.
  final fixed2 = <Function>[];
  for (var i = 0; i < 3; i++) {
    final captured = i; // new variable every iteration — separate binding
    fixed2.add(() => captured);
  }
  print('fixed (local copy): ${fixed2.map((f) => f())}'); // (0, 1, 2)

  // FIX 3: Use List.generate — the index is a fresh parameter each call.
  final fixed3 = List.generate(3, (i) => () => i);
  print('fixed (generate):   ${fixed3.map((f) => f())}'); // (0, 1, 2)
}

// ---------------------------------------------------------------------------
// 3. CLOSURE-BASED ENCAPSULATION — FACTORY FUNCTIONS RETURNING CLOSURES
// ---------------------------------------------------------------------------
// You can achieve data hiding without classes by having a factory function
// close over private state and return a set of operations as closures.
// The state is only accessible through those returned functions.

typedef Counter = ({
  int Function() value,
  void Function() increment,
  void Function() reset,
});

Counter makeCounter({int start = 0}) {
  // `_count` is completely private — callers have no way to access it
  // other than through the three functions below.
  var _count = start;

  return (
    value: () => _count,
    increment: () { _count++; },
    reset: () { _count = start; }, // `start` is also captured
  );
}

void closureEncapsulation() {
  print('\n--- 3. Closure-based encapsulation ---');

  final c = makeCounter(start: 10);
  c.increment();
  c.increment();
  print('value: ${c.value()}'); // 12
  c.reset();
  print('after reset: ${c.value()}'); // 10

  // Two independent counters — each has its own `_count` cell.
  final a = makeCounter();
  final b = makeCounter();
  a.increment();
  a.increment();
  b.increment();
  print('a=${a.value()}, b=${b.value()}'); // a=2, b=1
}

// ---------------------------------------------------------------------------
// 4. IMMEDIATELY-INVOKED FUNCTION EXPRESSION (IIFE)
// ---------------------------------------------------------------------------
// Dart has no dedicated IIFE syntax, but you can define an anonymous function
// and call it immediately.  Useful to:
//   • Create a local scope without polluting the surrounding scope.
//   • Compute a complex value that needs intermediate variables.
//   • Initialise a `final` variable from a multi-step computation.

void iifePattern() {
  print('\n--- 4. IIFE pattern ---');

  // Compute a value using an IIFE so intermediates don't leak.
  final result = () {
    final a = 6;
    final b = 7;
    return a * b; // only `result` escapes
  }();
  print('IIFE result: $result'); // 42

  // Initialising a final variable from a loop — not possible with `for` alone.
  final firstEven = () {
    for (var n in [1, 3, 4, 7, 8]) {
      if (n.isEven) return n;
    }
    return null;
  }();
  print('firstEven: $firstEven'); // 4

  // async IIFE — fire-and-forget async work from a sync context.
  // (() async {
  //   await Future.delayed(Duration.zero);
  //   print('async IIFE ran');
  // })();
  // (Commented out to avoid async complexity here — pattern is valid though.)
}

// ---------------------------------------------------------------------------
// 5. CLOSURES AS CALLBACKS vs TEAR-OFFS
// ---------------------------------------------------------------------------
// A *tear-off* is a reference to an existing named function/method treated as
// a Function value.  A *closure* wraps a new anonymous function, possibly
// capturing variables.
//
// Key difference:
//   • Tear-off: `list.forEach(print)` — no new allocation for a wrapper.
//   • Closure:  `list.forEach((x) => print(x))` — allocates a new closure
//               object on every call-site evaluation, even if it just
//               delegates to the same function.
//
// Prefer tear-offs when you don't need to close over extra state; they are
// cheaper and arguably more readable.

String _shout(String s) => s.toUpperCase();

void callbacksVsTearOffs() {
  print('\n--- 5. Callbacks vs tear-offs ---');

  final words = ['hello', 'world'];

  // Tear-off: _shout is already a function; we pass its reference directly.
  final torn = words.map(_shout).toList();
  print('tear-off: $torn'); // [HELLO, WORLD]

  // Closure wrapper: functionally identical, but allocates a new Function
  // object whose only job is to forward to `_shout`.
  final wrapped = words.map((w) => _shout(w)).toList();
  print('closure:  $wrapped'); // [HELLO, WORLD]

  // When do you NEED a closure instead of a tear-off?
  // → When you must close over additional state.
  final prefix = 'Hi, ';
  final greeted = words.map((w) => '$prefix${_shout(w)}').toList();
  print('needs closure (extra state): $greeted'); // [Hi, HELLO, Hi, WORLD]

  // Instance method tear-off: each instance produces its own tear-off, which
  // implicitly closes over `this`.  Still cheaper than an explicit wrapper.
  final buf = StringBuffer();
  final addLine = buf.writeln; // tear-off of StringBuffer.writeln
  addLine('line 1');
  addLine('line 2');
  print('StringBuffer via tear-off:\n${buf.toString().trimRight()}');
}

// ---------------------------------------------------------------------------
// 6. MEMORY IMPLICATIONS OF CAPTURING LARGE OBJECTS
// ---------------------------------------------------------------------------
// A closure keeps its entire captured environment alive as long as the closure
// itself is alive.  If you accidentally capture a large object just to use one
// small piece of it, the large object cannot be garbage-collected.
//
// Pattern: extract only what you need *before* creating the closure.

void memoryImplications() {
  print('\n--- 6. Memory implications ---');

  // Simulate a "large" object.
  final largeList = List.generate(100000, (i) => i);

  // BAD: the closure captures `largeList` entirely.
  // As long as `leaky` is alive, so is the 100k-element list.
  final leaky = () => largeList.length;

  // GOOD: extract what you need first; the closure only captures `len`.
  final len = largeList.length; // small int, not the list
  final efficient = () => len;

  // Both return the same answer, but `efficient` does not keep `largeList` live.
  print('leaky():     ${leaky()}');     // 100000
  print('efficient(): ${efficient()}'); // 100000

  // In Flutter, this matters for stateful widgets, AnimationControllers,
  // and StreamSubscriptions that hold callbacks.  A common fix:
  //
  //   final _id = widget.item.id; // capture only the ID
  //   _sub = stream.listen((_) => doSomething(_id));
  //
  // instead of:
  //
  //   _sub = stream.listen((_) => doSomething(widget.item.id));
  //   // `widget` (and its entire subtree) stays alive via the closure.
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  captureByReference();
  loopCaptureBug();
  closureEncapsulation();
  iifePattern();
  callbacksVsTearOffs();
  memoryImplications();
}
