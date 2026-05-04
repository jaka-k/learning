/// tear_offs.dart
///
/// Tear-offs in Dart — efficient function references without wrapper closures.
/// Run with: dart run tear_offs.dart

// ---------------------------------------------------------------------------
// WHAT IS A TEAR-OFF?
// ---------------------------------------------------------------------------
// A *tear-off* is a reference to a function or method obtained without
// calling it.  You "tear off" the method from its owner.
//
//   Regular call:        obj.method(arg)
//   Tear-off:            obj.method          ← a Function value
//   Using the tear-off:  final f = obj.method;  f(arg);
//
// Key distinction from a lambda wrapper:
//   Tear-off:   list.map(int.parse)       — no new object allocated
//   Lambda:     list.map((s) => int.parse(s)) — allocates a new closure
//
// The compiler can prove tear-offs refer to the same underlying method, so
// two tear-offs of the same method on the same instance are identical (==).

// ---------------------------------------------------------------------------
// 1. STATIC METHOD TEAR-OFFS
// ---------------------------------------------------------------------------
// Tearing off a static method (or top-level function) is the simplest case.
// There is no receiver to bind, so the tear-off is just a function pointer.

int double_(int n) => n * 2;
bool isEven(int n) => n % 2 == 0;

void demoStaticTearOffs() {
  print('\n--- 1. Static / top-level tear-offs ---');

  final nums = [1, 2, 3, 4, 5];

  // Tear-off of top-level function — pass directly, no wrapper needed.
  final doubled = nums.map(double_).toList();
  print('doubled: $doubled'); // [2, 4, 6, 8, 10]

  final evens = nums.where(isEven).toList();
  print('evens: $evens'); // [2, 4]

  // int.parse is a static method — classic tear-off for parsing.
  final strings = ['10', '20', '30'];
  final parsed = strings.map(int.parse).toList();
  print('parsed: $parsed'); // [10, 20, 30]

  // double.parse, bool.parse etc. work the same way.
  final doubles = ['1.5', '2.5'].map(double.parse).toList();
  print('doubles: $doubles'); // [1.5, 2.5]

  // Tear-offs can be stored and compared.
  final f1 = int.parse;
  final f2 = int.parse;
  // Static tear-offs of the same function are canonicalized — they are ==.
  print('f1 == f2: ${f1 == f2}'); // true
}

// ---------------------------------------------------------------------------
// 2. INSTANCE METHOD TEAR-OFFS
// ---------------------------------------------------------------------------
// When you tear off an instance method, Dart binds the instance as the
// implicit `this` receiver.  The tear-off is a closure over `this`.
//
// Two tear-offs of the same method on the same *instance* are ==.
// Two tear-offs on *different* instances are not.

class Multiplier {
  final int factor;
  const Multiplier(this.factor);

  int multiply(int n) => n * factor;
  String describe() => 'Multiplier(factor=$factor)';
}

void demoInstanceTearOffs() {
  print('\n--- 2. Instance method tear-offs ---');

  final triple = Multiplier(3);
  final quadruple = Multiplier(4);

  // Tear off `multiply` — the receiver (triple) is implicitly bound.
  final tripleIt = triple.multiply;   // int Function(int)
  final quadIt = quadruple.multiply;

  final nums = [1, 2, 3];
  print('tripled:    ${nums.map(tripleIt).toList()}');  // [3, 6, 9]
  print('quadrupled: ${nums.map(quadIt).toList()}');    // [4, 8, 12]

  // Identity: same instance, same method → ==.
  final a = triple.multiply;
  final b = triple.multiply;
  print('same instance tear-offs ==: ${a == b}'); // true

  // Different instances → not ==, even though the logic is the same.
  print('different instance tear-offs ==: ${tripleIt == quadIt}'); // false

  // Tear-offs of value types (like String) also work.
  final words = ['hello', 'world'];
  // toUpperCase is an instance method on String; words[0].toUpperCase is a
  // tear-off of THAT specific instance.  More commonly used with map:
  final uppercased = words.map((w) => w.toUpperCase()).toList();
  // (here a closure is needed since each `w` is different)
  print('uppercased: $uppercased'); // [HELLO, WORLD]

  // But for a single known object:
  final buf = StringBuffer();
  final addLine = buf.writeln; // tear-off bound to `buf`
  ['one', 'two', 'three'].forEach(addLine);
  print('buffer:\n${buf.toString().trim()}');
}

// ---------------------------------------------------------------------------
// 3. CONSTRUCTOR TEAR-OFFS (Dart 2.15+)
// ---------------------------------------------------------------------------
// Before 2.15 you had to wrap constructors in lambdas:
//   list.map((s) => MyClass(s))
//
// Since 2.15 you can tear off a constructor using the `.new` syntax:
//   list.map(MyClass.new)
//
// Named constructors are torn off using their full name:
//   list.map(MyClass.fromString)

class Point {
  final double x, y;
  const Point(this.x, this.y);

  // Named constructor.
  Point.origin() : x = 0, y = 0;

  // Named constructor from a list.
  Point.fromList(List<double> coords)
      : x = coords[0],
        y = coords[1];

  @override
  String toString() => 'Point($x, $y)';
}

class Box<T> {
  final T value;
  const Box(this.value);

  @override
  String toString() => 'Box<$T>($value)';
}

void demoConstructorTearOffs() {
  print('\n--- 3. Constructor tear-offs (Dart 2.15+) ---');

  // Default constructor tear-off: Point.new is `(double, double) → Point`.
  final pairs = [(1.0, 2.0), (3.0, 4.0), (5.0, 6.0)];
  final points = pairs.map((p) => Point(p.$1, p.$2)).toList();
  print('points: $points'); // [Point(1.0, 2.0), ...]

  // Named constructor tear-off: Point.fromList.
  final coordLists = [
    [0.0, 1.0],
    [2.0, 3.0],
  ];
  final fromLists = coordLists.map(Point.fromList).toList();
  print('fromList: $fromLists'); // [Point(0.0, 1.0), Point(2.0, 3.0)]

  // Generic constructor tear-off — type is inferred at call site.
  final values = [1, 2, 3];
  final boxes = values.map(Box.new).toList(); // Box<int>.new
  print('boxes: $boxes'); // [Box<int>(1), Box<int>(2), Box<int>(3)]

  // Storing a constructor tear-off in a variable.
  final makePoint = Point.new; // (double, double) → Point
  print(makePoint(7.0, 8.0)); // Point(7.0, 8.0)

  // Factory constructor tear-offs also work.
  // (See factories.dart for more on factory constructors.)
}

// ---------------------------------------------------------------------------
// 4. TEAR-OFFS IN COLLECTION OPERATIONS
// ---------------------------------------------------------------------------
// The most common everyday use: passing a named function directly to map,
// where, forEach, sort, etc.

void demoTearOffsInCollections() {
  print('\n--- 4. Tear-offs in collection operations ---');

  final strings = ['  hello  ', '  world  ', '  dart  '];

  // String.trim is an instance method — but each element is different, so we
  // CAN use a tear-off only if we have a single consistent object.
  // For transforming each element, a closure is needed (each `s` is the receiver).
  // The idiomatic form is still shorter than an explicit call:
  final trimmed = strings.map((s) => s.trim()).toList();
  print('trimmed: $trimmed');

  // Where a STATIC method applies uniformly, the tear-off wins:
  final rawInts = ['1', '2', 'bad', '4'];
  // Safe parse using tryParse (static method tear-off).
  final safeInts = rawInts.map(int.tryParse).whereType<int>().toList();
  print('safeInts: $safeInts'); // [1, 2, 4]

  // print is a top-level function — usable as a tear-off.
  [1, 2, 3].forEach(print); // 1, 2, 3 on separate lines

  // Sorting with a static comparator.
  final words = ['banana', 'apple', 'cherry'];
  // String has no static compare, but we can define one.
  int compareLength(String a, String b) => a.length.compareTo(b.length);
  words.sort(compareLength); // tear-off of top-level function
  print('by length: $words'); // [apple, banana, cherry]
}

// ---------------------------------------------------------------------------
// 5. CLOSURES vs TEAR-OFFS — PERFORMANCE AND IDENTITY
// ---------------------------------------------------------------------------
// When the compiler sees a tear-off expression it can create a canonical
// object (especially for static/const tear-offs).
// Each time a *closure* expression is evaluated, a NEW object is allocated
// even if the code is identical.

void demoClosureVsTearOff() {
  print('\n--- 5. Closures vs tear-offs ---');

  // Tear-off: evaluated once → same object.
  final t1 = int.parse;
  final t2 = int.parse;
  print('static tear-offs ==:  ${t1 == t2}'); // true

  // Closure: each evaluation creates a new object.
  final c1 = (String s) => int.parse(s);
  final c2 = (String s) => int.parse(s);
  print('closures ==:          ${c1 == c2}'); // false — different objects

  // This matters in Flutter's `build()` method:
  //   Bad:  onPressed: () => handleTap()    // new closure every rebuild
  //   Good: onPressed: handleTap            // stable reference, avoids needless diffs
  //
  // Widget tree diffing compares callbacks by identity; a new closure forces
  // the subtree to consider the callback as "changed" even if it's logically
  // the same.  Tear-offs give stable references.

  // Instance tear-offs: same instance → same tear-off (==).
  final m = Multiplier(5);
  final mt1 = m.multiply;
  final mt2 = m.multiply;
  print('instance tear-offs == (same obj): ${mt1 == mt2}'); // true
}

// ---------------------------------------------------------------------------
// 6. NAMED CONSTRUCTOR TEAR-OFFS
// ---------------------------------------------------------------------------
// Named constructors are torn off by fully qualifying them: ClassName.named
// (without calling them — no parentheses).

class Color {
  final int r, g, b;
  const Color(this.r, this.g, this.b);

  // Named constructors.
  Color.red()   : r = 255, g = 0,   b = 0;
  Color.green() : r = 0,   g = 255, b = 0;
  Color.blue()  : r = 0,   g = 0,   b = 255;

  Color.fromHex(String hex)
      : r = int.parse(hex.substring(1, 3), radix: 16),
        g = int.parse(hex.substring(3, 5), radix: 16),
        b = int.parse(hex.substring(5, 7), radix: 16);

  @override
  String toString() => 'Color(r=$r, g=$g, b=$b)';
}

void demoNamedConstructorTearOffs() {
  print('\n--- 6. Named constructor tear-offs ---');

  // Tear off named constructors and store them.
  final makeRed   = Color.red;    // () → Color
  final makeGreen = Color.green;  // () → Color
  final makeBlue  = Color.blue;   // () → Color

  final palette = [makeRed, makeGreen, makeBlue].map((make) => make()).toList();
  print('palette: $palette');

  // Tear off a named constructor that takes a parameter.
  final hexStrings = ['#ff0000', '#00ff00', '#0000ff'];
  final fromHex = Color.fromHex; // (String) → Color
  final colors = hexStrings.map(fromHex).toList();
  print('from hex: $colors');
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoStaticTearOffs();
  demoInstanceTearOffs();
  demoConstructorTearOffs();
  demoTearOffsInCollections();
  demoClosureVsTearOff();
  demoNamedConstructorTearOffs();
}
