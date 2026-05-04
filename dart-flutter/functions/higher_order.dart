/// higher_order.dart
///
/// Higher-order functions and lazy Iterable chains in Dart.
/// Run with: dart run higher_order.dart

// ---------------------------------------------------------------------------
// SETUP — sample data used throughout the file
// ---------------------------------------------------------------------------
const _words = ['apple', 'banana', 'cherry', 'date', 'elderberry', 'fig'];
const _numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

// ---------------------------------------------------------------------------
// 1. map — transform every element
// ---------------------------------------------------------------------------
// Returns a lazy Iterable<R>; no work is done until the elements are consumed.
// Use .toList() / .toSet() to force evaluation and materialise a collection.

void demoMap() {
  print('\n--- 1. map ---');

  // Basic transformation.
  final lengths = _words.map((w) => w.length);
  // `lengths` is an Iterable<int>; the lambdas have NOT run yet.
  print('lengths (lazy): $lengths');        // (5, 6, 6, 4, 10, 3)
  print('lengths (list): ${lengths.toList()}');

  // Chaining maps — still lazy; only ONE pass happens when consumed.
  final result = _numbers
      .map((n) => n * 2)   // double
      .map((n) => n + 1);  // then add 1
  print('double then +1: ${result.toList()}');
  // [3, 5, 7, 9, 11, 13, 15, 17, 19, 21]

  // map on Map entries (Map.entries returns Iterable<MapEntry>).
  final scores = {'Alice': 90, 'Bob': 75, 'Carol': 85};
  final graded = scores.entries.map((e) => '${e.key}: ${e.value >= 80 ? "A" : "B"}');
  print('graded: ${graded.toList()}');
}

// ---------------------------------------------------------------------------
// 2. where — filter elements matching a predicate
// ---------------------------------------------------------------------------
// Also lazy.  Equivalent to `filter` in most other languages.

void demoWhere() {
  print('\n--- 2. where ---');

  final evens = _numbers.where((n) => n.isEven);
  print('evens: ${evens.toList()}'); // [2, 4, 6, 8, 10]

  // Combining where + map (still one lazy chain):
  final squaredOdds = _numbers
      .where((n) => n.isOdd)
      .map((n) => n * n);
  print('squared odds: ${squaredOdds.toList()}'); // [1, 9, 25, 49, 81]

  // whereType<T> — filter AND cast to a specific type.
  final mixed = <Object>[1, 'two', 3, 'four', 5];
  final ints = mixed.whereType<int>();
  print('ints from mixed: ${ints.toList()}'); // [1, 3, 5]
}

// ---------------------------------------------------------------------------
// 3. reduce — combine elements using a binary function (no seed)
// ---------------------------------------------------------------------------
// Throws on an empty iterable.  The accumulator type must match the element
// type.  Use `fold` when you need a different result type or a seed value.

void demoReduce() {
  print('\n--- 3. reduce ---');

  final sum = _numbers.reduce((acc, n) => acc + n);
  print('sum: $sum'); // 55

  final max = _numbers.reduce((a, b) => a > b ? a : b);
  print('max: $max'); // 10

  // Finding the longest word:
  final longest = _words.reduce((a, b) => a.length >= b.length ? a : b);
  print('longest word: $longest'); // elderberry
}

// ---------------------------------------------------------------------------
// 4. fold — like reduce but with an explicit seed and can change type
// ---------------------------------------------------------------------------
// fold<R>(R seed, R Function(R acc, T element) combine)
// Because R can differ from T, fold is strictly more powerful than reduce.

void demoFold() {
  print('\n--- 4. fold ---');

  // Sum (same type, but with explicit seed — safe on empty list).
  final sum = _numbers.fold(0, (acc, n) => acc + n);
  print('sum (fold): $sum'); // 55

  // Result type differs: fold a list of words into a frequency map.
  final freq = _words.fold(<String, int>{}, (map, word) {
    map[word[0]] = (map[word[0]] ?? 0) + 1; // first letter frequency
    return map;
  });
  print('first-letter freq: $freq');

  // Build a string from numbers — R is String, T is int.
  final sentence = _numbers.fold('', (s, n) => s.isEmpty ? '$n' : '$s, $n');
  print('joined: $sentence');
}

// ---------------------------------------------------------------------------
// 5. any / every — short-circuit predicates
// ---------------------------------------------------------------------------
// any returns true as soon as one element matches (short-circuits).
// every returns false as soon as one element fails (short-circuits).
// Both return bool, not a lazy Iterable.

void demoAnyEvery() {
  print('\n--- 5. any / every ---');

  print('any > 9:    ${_numbers.any((n) => n > 9)}');    // true  (10)
  print('any > 100:  ${_numbers.any((n) => n > 100)}');  // false
  print('every > 0:  ${_numbers.every((n) => n > 0)}');  // true
  print('every even: ${_numbers.every((n) => n.isEven)}'); // false

  // Useful for validation:
  final emails = ['a@x.com', 'b@x.com', 'not-an-email'];
  final allValid = emails.every((e) => e.contains('@'));
  print('all valid emails: $allValid'); // false
}

// ---------------------------------------------------------------------------
// 6. expand — flatMap equivalent (map then flatten one level)
// ---------------------------------------------------------------------------
// Each element is mapped to an Iterable, and all those iterables are
// concatenated.  This is Dart's flatMap / SelectMany.

void demoExpand() {
  print('\n--- 6. expand (flatMap) ---');

  // Each word expands to its characters.
  final chars = ['hi', 'yo'].expand((w) => w.split(''));
  print('chars: ${chars.toList()}'); // [h, i, y, o]

  // Nested lists flattened one level.
  final nested = [[1, 2], [3, 4], [5]];
  final flat = nested.expand((l) => l);
  print('flat: ${flat.toList()}'); // [1, 2, 3, 4, 5]

  // Generating multiple items per input element.
  final repeated = [1, 2, 3].expand((n) => List.filled(n, n));
  print('repeated: ${repeated.toList()}'); // [1, 2, 2, 3, 3, 3]
}

// ---------------------------------------------------------------------------
// 7. firstWhere / lastWhere with orElse
// ---------------------------------------------------------------------------
// firstWhere throws StateError if nothing matches and orElse is not given.
// Providing orElse avoids the exception; the callback supplies a default.

void demoFirstLastWhere() {
  print('\n--- 7. firstWhere / lastWhere ---');

  final firstEven = _numbers.firstWhere((n) => n.isEven);
  print('firstEven: $firstEven'); // 2

  final lastEven = _numbers.lastWhere((n) => n.isEven);
  print('lastEven: $lastEven'); // 10

  // Safe fallback when no match exists:
  final firstOver100 = _numbers.firstWhere(
    (n) => n > 100,
    orElse: () => -1, // orElse must return the same type as the element
  );
  print('firstOver100 (orElse): $firstOver100'); // -1

  // Without orElse on a failing predicate:
  try {
    _numbers.firstWhere((n) => n > 100);
  } on StateError catch (e) {
    print('StateError without orElse: $e');
  }
}

// ---------------------------------------------------------------------------
// 8. takeWhile / skipWhile
// ---------------------------------------------------------------------------
// takeWhile yields elements as long as the predicate is true, then stops
// (even if later elements would match).
// skipWhile discards elements as long as the predicate is true, then yields
// all remaining elements unconditionally.

void demoTakeSkipWhile() {
  print('\n--- 8. takeWhile / skipWhile ---');

  final data = [2, 4, 6, 7, 8, 10];

  // takeWhile: takes 2, 4, 6 — stops at 7 (odd), never sees 8 or 10.
  print('takeWhile(even): ${data.takeWhile((n) => n.isEven).toList()}');
  // [2, 4, 6]

  // skipWhile: skips 2, 4, 6 — yields everything from 7 onwards.
  print('skipWhile(even): ${data.skipWhile((n) => n.isEven).toList()}');
  // [7, 8, 10]

  // Practical: skip a CSV header line.
  final lines = ['id,name', '1,Alice', '2,Bob'];
  final dataLines = lines.skipWhile((l) => l.startsWith('id'));
  print('CSV data rows: ${dataLines.toList()}'); // [1,Alice, 2,Bob]
}

// ---------------------------------------------------------------------------
// 9. LAZY vs EAGER — Iterable is lazy; toList() forces evaluation
// ---------------------------------------------------------------------------
// The key insight: every method on Iterable that returns an Iterable is LAZY.
// No element is processed until you iterate (for-in, toList, first, etc.).
// This means long chains are efficient — only one pass over the data.

void demoLazyVsEager() {
  print('\n--- 9. Lazy vs eager ---');

  var callCount = 0;

  // Build a lazy pipeline — nothing executes yet.
  final pipeline = _numbers
      .where((n) { callCount++; return n.isOdd; })
      .map((n) => n * 10);

  print('callCount before consuming: $callCount'); // 0 — nothing ran yet!

  // Taking only the first element — Dart only processes elements until it
  // finds a match.  It does NOT evaluate the whole list.
  final firstOddTimesTen = pipeline.first;
  print('first odd*10: $firstOddTimesTen'); // 10
  print('callCount after .first: $callCount'); // 1 — only one element checked

  callCount = 0;

  // toList() forces the entire pipeline.
  final all = pipeline.toList();
  print('callCount after toList: $callCount'); // 10 (all numbers checked)
  print('all odd*10: $all');

  // EAGER alternative: using List methods that return List directly.
  // (There aren't many built-ins; usually you call .toList() explicitly.)
  // The point: don't call toList() in the middle of a chain if you only need
  // the final result — it creates a needless intermediate list.

  // BAD (extra allocation):
  // _numbers.where((n) => n.isOdd).toList().map((n) => n * 10).toList()

  // GOOD (single lazy pass):
  // _numbers.where((n) => n.isOdd).map((n) => n * 10).toList()
}

// ---------------------------------------------------------------------------
// 10. CUSTOM HIGHER-ORDER FUNCTIONS — functions that return functions
// ---------------------------------------------------------------------------
// A higher-order function either accepts a function as a parameter, returns
// a function, or both.  This enables partial application and composition.

// Partial application: fix one argument, return a new function.
int Function(int) adder(int addend) => (n) => n + addend;

// Function composition: combine two functions f and g into g(f(x)).
T Function(A) compose<A, B, T>(B Function(A) f, T Function(B) g) =>
    (A x) => g(f(x));

// Memoize: wrap any single-argument function with a cache.
R Function(A) memoize<A, R>(R Function(A) fn) {
  final cache = <A, R>{};
  return (A arg) => cache.putIfAbsent(arg, () => fn(arg));
}

// Retry: retry a function up to `n` times on exception.
T Function() withRetry<T>(T Function() fn, {int retries = 3}) {
  return () {
    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        return fn();
      } catch (e) {
        if (attempt == retries) rethrow;
        print('  attempt $attempt failed: $e — retrying...');
      }
    }
    throw StateError('unreachable');
  };
}

void demoCustomHOF() {
  print('\n--- 10. Custom higher-order functions ---');

  // Partial application.
  final add5 = adder(5);
  final add10 = adder(10);
  print('add5(3)=${add5(3)}, add10(3)=${add10(3)}'); // 8, 13

  // Composition: double then stringify.
  final doubleIt = (int n) => n * 2;
  final stringify = (int n) => 'value=$n';
  final doubleThenStringify = compose(doubleIt, stringify);
  print(doubleThenStringify(7)); // value=14

  // Memoize an expensive-ish computation.
  var calls = 0;
  int expensive(int n) { calls++; return n * n; }
  final memoExpensive = memoize(expensive);
  memoExpensive(4); memoExpensive(4); memoExpensive(5);
  print('expensive calls (with memo): $calls'); // 2 (4 and 5, not 4 twice)

  // Retry.
  var attempts = 0;
  final flaky = withRetry(() {
    attempts++;
    if (attempts < 3) throw Exception('not ready');
    return 'success';
  });
  print(flaky()); // success after 2 retries
}

// ---------------------------------------------------------------------------
// 11. Function.apply — dynamic invocation
// ---------------------------------------------------------------------------
// Function.apply(fn, positionalArgs, namedArgs) lets you call a function when
// you don't know its signature at compile time (e.g., plugin systems, testing
// harnesses, serialisation frameworks).

void demoFunctionApply() {
  print('\n--- 11. Function.apply ---');

  int add(int a, int b) => a + b;
  print(Function.apply(add, [3, 4])); // 7

  // Named arguments via a Map<Symbol, dynamic>.
  String greet({required String name, String greeting = 'Hello'}) =>
      '$greeting, $name!';

  print(Function.apply(greet, [], {#name: 'Dart'}));
  // Hello, Dart!

  print(Function.apply(greet, [], {#name: 'World', #greeting: 'Hi'}));
  // Hi, World!

  // Dynamic dispatch — you could store functions in a Map and invoke them
  // by name at runtime.
  final dispatch = <String, Function>{
    'add': (int a, int b) => a + b,
    'mul': (int a, int b) => a * b,
  };
  final op = 'mul';
  final result = Function.apply(dispatch[op]!, [6, 7]);
  print('dispatch[$op](6,7) = $result'); // 42
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoMap();
  demoWhere();
  demoReduce();
  demoFold();
  demoAnyEvery();
  demoExpand();
  demoFirstLastWhere();
  demoTakeSkipWhile();
  demoLazyVsEager();
  demoCustomHOF();
  demoFunctionApply();
}
