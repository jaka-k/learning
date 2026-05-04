// records.dart
// Dart 3.0+ records: anonymous immutable aggregates, positional vs named,
// value equality, multiple return values, destructuring, and switch patterns.

// ---------------------------------------------------------------------------
// 1. What are records?
// ---------------------------------------------------------------------------
//
// Records are anonymous, immutable aggregate types.
// They are STRUCTURAL VALUE TYPES — two records are equal if every field is
// equal, regardless of where they were created. No class definition needed.
//
// Use records when you need a quick bundle of values and:
//   - You don't need methods or named behavior
//   - The type will not be reused across many files
//   - You'd otherwise return a Map<String, dynamic> or a tuple-class

// ---------------------------------------------------------------------------
// 2. Positional records — (T1, T2, ...)
// ---------------------------------------------------------------------------

// The record type `(int, String)` is a structural type — it's anonymous.
// Access positional fields via $1, $2, ... (1-based index).

void positionalRecords() {
  (int, String) pair = (42, 'hello');
  print(pair.$1); // 42
  print(pair.$2); // hello
  print(pair); // (42, hello)

  // Three-element positional record:
  (double, double, double) rgb = (0.9, 0.2, 0.4);
  print('R=${rgb.$1} G=${rgb.$2} B=${rgb.$3}');

  // Type is inferred if you use `var`:
  var point = (3.0, 4.0); // (double, double)
  double x = point.$1;
  double y = point.$2;
  print('point: ($x, $y)');
}

// ---------------------------------------------------------------------------
// 3. Named records — ({Type name, ...})
// ---------------------------------------------------------------------------
//
// Named fields are accessed by name, not by position.
// The order of named fields does NOT matter for type identity:
//   ({int x, int y}) == ({int y, int x})   ← same type
// (Unlike positional records where order IS significant.)

void namedRecords() {
  ({String name, int age}) person = (name: 'Alice', age: 30);
  print(person.name); // Alice
  print(person.age); // 30

  // Order is irrelevant for named records:
  ({int age, String name}) reordered = (age: 30, name: 'Alice');
  // These two variables have the SAME static type — ({String name, int age})
  // and ({int age, String name}) are identical in Dart.
  print(person == reordered); // true — same values, same type
}

// ---------------------------------------------------------------------------
// 4. Mixed positional + named records
// ---------------------------------------------------------------------------
//
// You can combine positional and named fields.
// Positional come first; named come after (in any order).

void mixedRecords() {
  (int, double, {String label, bool active}) entry = (
    1,
    3.14,
    label: 'pi',
    active: true,
  );

  print(entry.$1); // 1 (positional)
  print(entry.$2); // 3.14 (positional)
  print(entry.label); // pi (named)
  print(entry.active); // true (named)
}

// ---------------------------------------------------------------------------
// 5. Records are value types (structural equality)
// ---------------------------------------------------------------------------
//
// Record equality is structural — based on the field values, not identity.
// This is unlike class instances, which use reference equality by default.

void valueEquality() {
  final a = (1, 'x', true);
  final b = (1, 'x', true);
  final c = (1, 'x', false);

  print(a == b); // true — same values
  print(a == c); // false — different last field
  print(identical(a, b)); // false — different objects, same value

  // Named records:
  final p1 = (x: 3, y: 4);
  final p2 = (x: 3, y: 4);
  print(p1 == p2); // true

  // hashCode is consistent with ==:
  print(p1.hashCode == p2.hashCode); // true

  // Compare to classes (default reference equality):
  final o1 = _Point(3, 4);
  final o2 = _Point(3, 4);
  print(o1 == o2); // false (unless == is overridden)
}

class _Point {
  final int x, y;
  _Point(this.x, this.y);
}

// ---------------------------------------------------------------------------
// 6. Records as multiple return values
// ---------------------------------------------------------------------------
//
// This is the most common practical use of records.
// Before Dart 3.0, you'd return a Map, a custom class, or a List.
// Records are cleaner and type-safe.

(String, int) splitAtFirst(String s, String separator) {
  final idx = s.indexOf(separator);
  if (idx == -1) return (s, -1);
  return (s.substring(0, idx), idx);
}

// Named record for clarity when there are many return values:
({double mean, double stdDev, double min, double max}) statistics(
    List<double> data) {
  if (data.isEmpty) return (mean: 0, stdDev: 0, min: 0, max: 0);
  final n = data.length;
  final mean = data.reduce((a, b) => a + b) / n;
  final variance =
      data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
  return (
    mean: mean,
    stdDev: variance > 0 ? variance : 0,
    min: data.reduce((a, b) => a < b ? a : b),
    max: data.reduce((a, b) => a > b ? a : b),
  );
}

// ---------------------------------------------------------------------------
// 7. Destructuring records in local variables
// ---------------------------------------------------------------------------
//
// Dart 3.0 pattern-based variable declarations let you destructure records.

void destructuringDemo() {
  // Positional destructuring:
  final (name, idx) = splitAtFirst('hello world', ' ');
  print('name="$name" at=$idx');

  // Named destructuring (shorthand `:`):
  final (:mean, :stdDev, :min, :max) =
      statistics([1.0, 2.0, 3.0, 4.0, 5.0]);
  print('mean=$mean stdDev=$stdDev min=$min max=$max');

  // Mixed destructuring:
  (int, {String label}) tagged = (99, label: 'score');
  final (score, :label) = tagged;
  print('$label = $score');

  // Nested record destructuring:
  ((int, int), String) nested = ((3, 4), 'point');
  final ((x, y), description) = nested;
  print('$description: ($x, $y)');
}

// ---------------------------------------------------------------------------
// 8. Records in switch / pattern matching
// ---------------------------------------------------------------------------

String classifyPair((int, int) pair) => switch (pair) {
      (0, 0) => 'origin',
      (var x, 0) => 'x-axis at $x',
      (0, var y) => 'y-axis at $y',
      (var x, var y) when x == y => 'diagonal: $x',
      (var x, var y) when x > 0 && y > 0 => 'Q1: ($x, $y)',
      (var x, var y) => 'other: ($x, $y)',
    };

// With named records:
String describeConfig({required ({bool debug, int port, String host}) cfg}) =>
    switch (cfg) {
      (:var debug, port: 443, :var host) when !debug =>
        'production at $host:443',
      (:var debug, :var port, :var host) when debug =>
        'development at $host:$port',
      _ => 'other config',
    };

// ---------------------------------------------------------------------------
// 9. Records vs classes — when to use each
// ---------------------------------------------------------------------------
//
// Use RECORDS when:
//   - You need a quick, temporary bundle of values (return type, local grouping)
//   - Structural equality is desirable (grouping inputs for a Map key, etc.)
//   - No methods or behavior beyond field access
//   - The type does not need to be named/exported/documented
//
// Use CLASSES when:
//   - The type has methods, inheritance, or polymorphism
//   - The type is part of your public API (needs documentation, versioning)
//   - You need mutability
//   - You need factory constructors or const constructors with complex logic
//   - The concept deserves a name for clarity across many files
//
// Records as Map keys (structural equality makes this work correctly!):

void recordsAsMapKeys() {
  final cache = <(int, int), String>{};
  cache[(0, 0)] = 'origin';
  cache[(1, 2)] = 'one-two';
  print(cache[(0, 0)]); // 'origin' — lookup works because (0,0)==(0,0)
  print(cache[(1, 2)]); // 'one-two'
}

// ---------------------------------------------------------------------------
// 10. Spread is NOT supported — field access only
// ---------------------------------------------------------------------------
//
// Records do not support spread (`...`) into other records or function calls.
// You must access each field individually.

void spreadLimitation() {
  final r = (1, 2, 3);

  // There is no `someFunction(...r)` syntax.
  // You must do:
  someFunction(r.$1, r.$2, r.$3);

  // Merging two records also requires manual field copying:
  final a = (x: 1, y: 2);
  final b = (z: 3, w: 4);
  // No spread — build a new record explicitly:
  final merged = (x: a.x, y: a.y, z: b.z, w: b.w);
  print(merged);
}

void someFunction(int a, int b, int c) => print('$a $b $c');

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== Positional records ===');
  positionalRecords();

  print('\n=== Named records ===');
  namedRecords();

  print('\n=== Mixed positional + named ===');
  mixedRecords();

  print('\n=== Value equality ===');
  valueEquality();

  print('\n=== Multiple return values ===');
  final (word, pos) = splitAtFirst('foo:bar:baz', ':');
  print('"$word" separator at index $pos');

  print('\n=== Destructuring ===');
  destructuringDemo();

  print('\n=== Records in switch ===');
  for (final pair in [(0, 0), (3, 0), (0, 4), (5, 5), (2, 3)]) {
    print(classifyPair(pair));
  }
  print(describeConfig(cfg: (debug: false, port: 443, host: 'example.com')));
  print(describeConfig(cfg: (debug: true, port: 8080, host: 'localhost')));

  print('\n=== Records as Map keys ===');
  recordsAsMapKeys();

  print('\n=== Spread limitation ===');
  spreadLimitation();
}
