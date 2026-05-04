// pattern_matching.dart
// Dart 3.0+ patterns: switch expressions, object/list/map/record patterns,
// guards, exhaustiveness checking, refutable vs irrefutable patterns.

// ---------------------------------------------------------------------------
// Background: what are patterns?
// ---------------------------------------------------------------------------
//
// A pattern is a syntactic form that can:
//   1. MATCH a value against a shape/type/value.
//   2. DESTRUCTURE (extract) parts of the value into variables.
//
// Patterns appear in:
//   - switch statements and switch expressions
//   - if-case statements
//   - variable declarations (irrefutable patterns only)
//   - for-loop variable declarations
//
// REFUTABLE pattern: may not match — used in switch/case and if-case.
// IRREFUTABLE pattern: always matches — used in variable declarations.

// ---------------------------------------------------------------------------
// 1. Switch expressions (Dart 3.0+)
// ---------------------------------------------------------------------------
//
// Unlike switch STATEMENTS, switch EXPRESSIONS:
//   - Are exhaustiveness-checked (compiler error if cases are incomplete)
//   - Return a value
//   - Use `=>` not `:` and no `break`

sealed class Shape {}

class Circle extends Shape {
  final double radius;
  const Circle(this.radius);
}

class Rectangle extends Shape {
  final double width, height;
  const Rectangle(this.width, this.height);
}

class Triangle extends Shape {
  final double base, height;
  const Triangle(this.base, this.height);
}

double area(Shape shape) => switch (shape) {
      // Object pattern: matches type AND destructures fields in one step.
      Circle(radius: var r) => 3.14159 * r * r,

      // Positional style also works for named fields (via name: binding):
      Rectangle(width: var w, height: var h) => w * h,

      Triangle(base: var b, height: var h) => 0.5 * b * h,
      // Because `Shape` is sealed, the compiler knows these three cases are
      // exhaustive — no default needed. If you add a new subclass without
      // adding a case here, you get a compile-time error.
    };

// ---------------------------------------------------------------------------
// 2. Object patterns — type match + field destructuring
// ---------------------------------------------------------------------------

class Point {
  final double x, y;
  const Point(this.x, this.y);
}

String classifyPoint(Point p) => switch (p) {
      // Object pattern with guard (when clause):
      Point(x: 0, y: 0) => 'origin',
      Point(x: var x, y: 0) => 'on x-axis at $x',
      Point(x: 0, y: var y) => 'on y-axis at $y',
      Point(x: var x, y: var y) when x == y => 'on diagonal at $x',
      Point(x: var x, y: var y) => '($x, $y)',
    };

// ---------------------------------------------------------------------------
// 3. List patterns
// ---------------------------------------------------------------------------

String describeList(List<int> list) => switch (list) {
      // Exact length match (no rest element):
      [] => 'empty',
      [var single] => 'singleton: $single',
      [var a, var b] => 'pair: $a and $b',

      // Rest element `...` matches zero or more remaining elements.
      // You can bind the rest to a variable with `...rest`.
      [var head, ...] => 'starts with $head',
    };

// Destructuring in variable declarations (irrefutable patterns):
void listDestructuring() {
  final [first, second, ...rest] = [10, 20, 30, 40, 50];
  print('first=$first second=$second rest=$rest');

  // Swap without a temp variable using list pattern:
  var a = 1, b = 2;
  [a, b] = [b, a];
  print('swapped: a=$a b=$b');
}

// ---------------------------------------------------------------------------
// 4. Map patterns
// ---------------------------------------------------------------------------

String parseCommand(Map<String, dynamic> cmd) => switch (cmd) {
      // Map pattern: keys must be present and values must match.
      // Unspecified keys are IGNORED (not required to be absent).
      {'type': 'move', 'dx': int dx, 'dy': int dy} =>
        'move by ($dx, $dy)',

      {'type': 'resize', 'factor': double f} =>
        'resize by ${f}x',

      {'type': 'delete'} => 'delete',

      // Wildcard for anything else:
      {'type': var t} => 'unknown command: $t',

      _ => 'invalid command',
    };

// ---------------------------------------------------------------------------
// 5. Record patterns
// ---------------------------------------------------------------------------

typedef Coordinate = (double lat, double lng);

String describeLocation((double, double) coord) => switch (coord) {
      (0.0, 0.0) => 'null island',
      (var lat, var lng) when lat > 0 && lng > 0 => 'NE: $lat, $lng',
      (var lat, var lng) when lat < 0 && lng < 0 => 'SW: $lat, $lng',
      (var lat, var lng) => 'other: $lat, $lng',
    };

// Named record patterns:
void namedRecordPattern() {
  final ({String name, int age}) person = (name: 'Alice', age: 30);
  final (:name, :age) = person; // shorthand destructuring
  print('$name is $age years old');
}

// ---------------------------------------------------------------------------
// 6. Logical-or patterns
// ---------------------------------------------------------------------------
//
// `pattern1 || pattern2` — matches if EITHER sub-pattern matches.
// Both sub-patterns must bind the SAME set of variables (same names, same types).

bool isWeekend(String day) => switch (day) {
      'Saturday' || 'Sunday' => true,
      _ => false,
    };

String classifyNumber(int n) => switch (n) {
      0 => 'zero',
      1 || 2 || 3 => 'small positive',
      < 0 => 'negative',
      _ => 'large positive',
    };

// ---------------------------------------------------------------------------
// 7. Relational patterns
// ---------------------------------------------------------------------------
//
// ==, !=, <, >, <=, >= — compare against a constant.
// Only work inside a switch/case (refutable context).

String grade(int score) => switch (score) {
      >= 90 => 'A',
      >= 80 => 'B',
      >= 70 => 'C',
      >= 60 => 'D',
      _ => 'F',
    };

// ---------------------------------------------------------------------------
// 8. Const patterns and variable patterns
// ---------------------------------------------------------------------------

const int kMaxRetries = 3;

// Const pattern: matches against a specific constant value.
String describeRetries(int n) => switch (n) {
      0 => 'no retries',
      kMaxRetries => 'hit the max (${kMaxRetries})',
      var x when x > kMaxRetries => 'exceeded max: $x',
      var x => '$x retries remaining',
    };

// ---------------------------------------------------------------------------
// 9. Wildcard `_` and named wildcards
// ---------------------------------------------------------------------------
//
// `_` is the wildcard: it matches anything and discards the value.
// Named wildcards like `var _` also discard but can appear in lists/maps
// to skip a specific position.

void wildcardDemo() {
  final (_, second, third) = (1, 2, 3); // skip first
  print('second=$second third=$third');

  final [_, ...middle, last] = [10, 20, 30, 40, 50];
  print('middle=$middle last=$last');

  // In map patterns, _ skips a value you don't care about:
  final {'a': _, 'b': var b} = {'a': 99, 'b': 42, 'c': 7};
  print('b=$b');
}

// ---------------------------------------------------------------------------
// 10. Exhaustiveness checking
// ---------------------------------------------------------------------------
//
// The compiler checks exhaustiveness for:
//   - sealed class hierarchies (all subclasses must be covered)
//   - enum values
//   - bool
//   - Records and tuples of the above
//
// If you miss a case, you get a compile-time error (not a runtime one!).

sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}

// This switch is exhaustive because Result is sealed with exactly 2 subclasses:
String showResult(Result<int> r) => switch (r) {
      Success(value: var v) => 'Got: $v',
      Failure(error: var e) => 'Error: $e',
      // No default needed — compiler knows these two cases cover everything.
    };

// ---------------------------------------------------------------------------
// 11. if-case statement
// ---------------------------------------------------------------------------
//
// `if (expr case pattern) { ... }` — tests a single pattern without a switch.
// Ideal when you want to destructure one specific shape.

void ifCaseDemo(Object value) {
  // Type + destructure in one step:
  if (value case Circle(radius: var r) when r > 0) {
    print('Circle with radius $r, area = ${3.14159 * r * r}');
  } else if (value case Rectangle(width: var w, height: var h)) {
    print('Rectangle ${w}x${h}');
  }

  // Destructuring a list with if-case:
  if (value case [int x, int y, int z]) {
    print('3-int list: $x, $y, $z');
  }

  // Null-checking pattern with if-case:
  if (value case String s when s.isNotEmpty) {
    print('Non-empty string: $s');
  }
}

// ---------------------------------------------------------------------------
// 12. Patterns in for loops
// ---------------------------------------------------------------------------

void forLoopPatterns() {
  final entries = {'a': 1, 'b': 2, 'c': 3};

  // Destructure MapEntry in a for-in loop:
  for (final MapEntry(key: k, value: v) in entries.entries) {
    print('$k => $v');
  }

  // Destructure a list of records:
  final points = [(1.0, 2.0), (3.0, 4.0), (5.0, 6.0)];
  for (final (x, y) in points) {
    print('x=$x y=$y');
  }
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== Switch expression (sealed shapes) ===');
  for (final shape in [Circle(5), Rectangle(3, 4), Triangle(6, 8)]) {
    print('area=${area(shape).toStringAsFixed(2)}');
  }

  print('\n=== Object patterns ===');
  for (final p in [
    Point(0, 0),
    Point(3, 0),
    Point(0, 5),
    Point(4, 4),
    Point(1, 2),
  ]) {
    print(classifyPoint(p));
  }

  print('\n=== List patterns ===');
  for (final list in [
    <int>[],
    [42],
    [1, 2],
    [7, 8, 9, 10],
  ]) {
    print(describeList(list));
  }

  print('\n=== List destructuring ===');
  listDestructuring();

  print('\n=== Map patterns ===');
  for (final cmd in [
    {'type': 'move', 'dx': 10, 'dy': -5},
    {'type': 'resize', 'factor': 1.5},
    {'type': 'delete'},
    {'type': 'paint', 'color': 'red'},
  ]) {
    print(parseCommand(cmd));
  }

  print('\n=== Record patterns ===');
  for (final coord in [(0.0, 0.0), (10.0, 20.0), (-5.0, -3.0)]) {
    print(describeLocation(coord));
  }
  namedRecordPattern();

  print('\n=== Logical-or patterns ===');
  print(isWeekend('Saturday')); // true
  print(isWeekend('Monday')); // false
  for (final n in [-3, 0, 2, 5, 100]) {
    print('$n → ${classifyNumber(n)}');
  }

  print('\n=== Relational patterns ===');
  for (final s in [95, 85, 75, 65, 55]) {
    print('$s → ${grade(s)}');
  }

  print('\n=== Const patterns ===');
  for (final n in [0, 1, 3, 5]) {
    print('$n → ${describeRetries(n)}');
  }

  print('\n=== Wildcard ===');
  wildcardDemo();

  print('\n=== Exhaustiveness (sealed Result) ===');
  print(showResult(Success(42)));
  print(showResult(Failure('not found')));

  print('\n=== if-case ===');
  ifCaseDemo(Circle(7));
  ifCaseDemo(Rectangle(3, 4));
  ifCaseDemo([1, 2, 3]);
  ifCaseDemo('hello');

  print('\n=== for-loop patterns ===');
  forLoopPatterns();
}
