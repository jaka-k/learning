/// extensions.dart
///
/// Extension methods in Dart — advanced patterns and gotchas.
/// Run with: dart run extensions.dart

// ---------------------------------------------------------------------------
// WHAT ARE EXTENSION METHODS?
// ---------------------------------------------------------------------------
// Extension methods (Dart 2.7+) let you add methods, getters, setters, and
// operators to *existing* types without modifying or subclassing them.
// They are purely compile-time — the generated code is a static method call.
//
// Syntax:
//   extension <OptionalName> on <Type> { ... }
//
// The name is optional but recommended: named extensions can be explicitly
// imported/hidden to resolve conflicts.

// ---------------------------------------------------------------------------
// 1. EXTENSION ON BUILT-IN TYPES
// ---------------------------------------------------------------------------

// --- String extensions ---
extension StringUtils on String {
  // Getter — accessed like a property.
  bool get isPalindrome {
    final clean = toLowerCase().replaceAll(RegExp(r'\s'), '');
    return clean == clean.split('').reversed.join();
  }

  // Method with parameters.
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  // Operator overload — add a string repeat operator.
  // `'ab' * 3` already works (built-in), so let's add one that trims.
  String operator %(int times) => (this * times).trim();

  // Returning a new type.
  List<String> get words => trim().split(RegExp(r'\s+'));
}

// --- int extensions ---
extension IntUtils on int {
  // Range generator — mimics Python's range().
  Iterable<int> to(int end, {int step = 1}) sync* {
    assert(step != 0, 'step must not be zero');
    if (step > 0) {
      for (var i = this; i < end; i += step) yield i;
    } else {
      for (var i = this; i > end; i += step) yield i;
    }
  }

  bool get isInRange => this >= 0 && this <= 100; // arbitrary example

  Duration get seconds => Duration(seconds: this);
  Duration get milliseconds => Duration(milliseconds: this);
}

// --- Iterable extensions ---
extension IterableUtils<T> on Iterable<T> {
  // Chunk the iterable into fixed-size sub-lists.
  Iterable<List<T>> chunked(int size) sync* {
    assert(size > 0);
    var chunk = <T>[];
    for (final element in this) {
      chunk.add(element);
      if (chunk.length == size) {
        yield chunk;
        chunk = [];
      }
    }
    if (chunk.isNotEmpty) yield chunk;
  }

  // Zip with another iterable — stops at the shorter one.
  Iterable<(T, S)> zip<S>(Iterable<S> other) sync* {
    final itA = iterator;
    final itB = other.iterator;
    while (itA.moveNext() && itB.moveNext()) {
      yield (itA.current, itB.current);
    }
  }

  // Safe first — returns null instead of throwing on empty.
  T? get firstOrNull => isEmpty ? null : first;
}

void demoBuiltInExtensions() {
  print('\n--- 1. Extensions on built-in types ---');

  // String
  print('"racecar".isPalindrome = ${"racecar".isPalindrome}'); // true
  print('"hello".isPalindrome  = ${"hello".isPalindrome}');    // false
  print('"dart flutter".truncate(7) = ${"dart flutter".truncate(7)}');
  // dart...
  print('"ha" % 3 = ${"ha" % 3}'); // hahaha (trimmed)
  print('"one two three".words = ${"one two three".words}');

  // int
  print('1.to(5) = ${1.to(5).toList()}');       // [1, 2, 3, 4]
  print('10.to(0, step: -3) = ${10.to(0, step: -3).toList()}'); // [10, 7, 4, 1]
  print('5.seconds = ${5.seconds}');             // 0:00:05.000000

  // Iterable
  print('[1..9].chunked(3) = ${[1,2,3,4,5,6,7,8,9].chunked(3).toList()}');
  final zipped = [1, 2, 3].zip(['a', 'b', 'c']).toList();
  print('zipped: $zipped'); // [(1, a), (2, b), (3, c)]
  print('[].firstOrNull = ${<int>[].firstOrNull}'); // null
}

// ---------------------------------------------------------------------------
// 2. EXTENSION ON NULLABLE TYPES
// ---------------------------------------------------------------------------
// You can write `extension on String?` — the receiver `this` may be null.
// Inside such an extension you must null-check `this` yourself.
// Regular (non-nullable) extension methods are NOT available on null values.

extension NullableStringUtils on String? {
  // Returns the string itself or a fallback if null/empty.
  String orDefault(String fallback) {
    final s = this; // promote `this` to a non-nullable local
    if (s == null || s.isEmpty) return fallback;
    return s;
  }

  // Safe length — 0 for null.
  int get safeLength => this?.length ?? 0;

  // isNullOrEmpty — commonly written as a standalone helper in other langs.
  bool get isNullOrEmpty {
    final s = this;
    return s == null || s.isEmpty;
  }
}

void demoNullableExtension() {
  print('\n--- 2. Nullable extension ---');

  String? maybeNull;
  String? empty = '';
  String? value = 'Dart';

  print(maybeNull.orDefault('(none)'));  // (none)
  print(empty.orDefault('(none)'));      // (none)
  print(value.orDefault('(none)'));      // Dart
  print('null.safeLength = ${maybeNull.safeLength}'); // 0
  print('value.safeLength = ${value.safeLength}');    // 4
  print('isNullOrEmpty: ${maybeNull.isNullOrEmpty}, ${value.isNullOrEmpty}');
}

// ---------------------------------------------------------------------------
// 3. GENERIC EXTENSION
// ---------------------------------------------------------------------------
// The type parameter on the extension is resolved per call-site.
// This lets you write truly generic utilities once.

extension MaybeExtension<T> on T? {
  // Apply a transformation if non-null, otherwise return null.
  R? let<R>(R Function(T value) transform) {
    final v = this;
    return v == null ? null : transform(v);
  }

  // Execute a side-effect if non-null, return `this` unchanged (builder pattern).
  T? also(void Function(T value) action) {
    final v = this;
    if (v != null) action(v);
    return this;
  }
}

extension ListExtension<T> on List<T> {
  // Safely access by index — returns null instead of RangeError.
  T? elementAtOrNull(int index) =>
      (index >= 0 && index < length) ? this[index] : null;
}

void demoGenericExtension() {
  print('\n--- 3. Generic extension ---');

  int? maybeInt = 42;
  final doubled = maybeInt.let((n) => n * 2);
  print('let doubled: $doubled'); // 84

  int? nullInt;
  print('let on null: ${nullInt.let((n) => n * 2)}'); // null

  String? name = 'Alice';
  name.also((n) => print('Hello, $n!')); // Hello, Alice!

  final list = ['a', 'b', 'c'];
  print(list.elementAtOrNull(1));  // b
  print(list.elementAtOrNull(99)); // null
}

// ---------------------------------------------------------------------------
// 4. NAME CONFLICTS AND RESOLUTION
// ---------------------------------------------------------------------------
// If two extensions define the same method on the same type and BOTH are in
// scope, the compiler raises an ambiguity error.
//
// Resolution strategies:
//   a) Qualify explicitly: ExtensionName(receiver).method()
//   b) Import with `show` / `hide`:
//        import 'other_file.dart' show OtherExtension;
//        import 'other_file.dart' hide ConflictingExtension;

// Two extensions adding `.describe()` to int — would conflict if both used.
extension IntDescribeA on int {
  String describeA() => 'IntDescribeA: $this';
}

extension IntDescribeB on int {
  String describeB() => 'IntDescribeB: ${this * 2}';
}

void demoNameConflicts() {
  print('\n--- 4. Name conflicts and resolution ---');

  // These use different method names, so no conflict here.
  print(42.describeA()); // IntDescribeA: 42
  print(42.describeB()); // IntDescribeB: 84

  // If both had `.describe()`, you'd resolve by qualifying:
  //   IntDescribeA(42).describe()
  //   IntDescribeB(42).describe()
  //
  // In real multi-file projects this pattern is common for extension-heavy
  // libraries (e.g., `dart_extensions`, `collection`).
  print('(conflict demo: use IntDescribeA(n).method() to disambiguate)');
}

// ---------------------------------------------------------------------------
// 5. EXTENSIONS vs MONKEY-PATCHING
// ---------------------------------------------------------------------------
// In dynamic languages (JS, Ruby, Python) you can mutate a class at runtime
// (monkey-patching).  This is global, unscoped, and fragile.
//
// Dart extension methods are:
//   • Purely compile-time — no runtime cost, no dynamic dispatch.
//   • Scoped to the file/library that imports them.
//   • Cannot override existing methods (only add new ones).
//   • Do not pollute the original class or affect other libraries.
//
// This is fundamentally safer: two libraries can each define conflicting
// extension methods and they only clash if both are imported into the SAME
// file.  The original class is never touched.

// ---------------------------------------------------------------------------
// 6. EXTENSION GETTERS, SETTERS, AND OPERATORS
// ---------------------------------------------------------------------------

extension RangeCheck on num {
  // Getter
  bool get isPositive => this > 0;

  // Operator — let `num` support the `~` (bitwise NOT concept) for clamping.
  // (Overloading `[]` on non-collection types is also possible.)
  num clampTo(num min, num max) => this < min ? min : (this > max ? max : this);
}

extension PairExtension<A, B> on (A, B) {
  // Getters on a record type — records have positional accessors ($1, $2)
  // but named ones via extension are friendlier.
  A get first => $1;
  B get second => $2;

  // Swap the pair.
  (B, A) get swapped => ($2, $1);
}

void demoGettersOperators() {
  print('\n--- 6. Getters / operators ---');

  print('(-5).isPositive = ${(-5).isPositive}'); // false
  print('3.isPositive    = ${3.isPositive}');     // true
  print('150.clampTo(0, 100) = ${150.clampTo(0, 100)}'); // 100

  final pair = ('hello', 42);
  print('pair.first  = ${pair.first}');  // hello
  print('pair.second = ${pair.second}'); // 42
  print('pair.swapped = ${pair.swapped}'); // (42, hello)
}

// ---------------------------------------------------------------------------
// 7. EXTENSIONS CANNOT ADD INSTANCE FIELDS
// ---------------------------------------------------------------------------
// Extensions can define:
//   ✓ Methods
//   ✓ Getters (computed, not stored)
//   ✓ Setters (but they must delegate to existing state)
//   ✓ Operators
//   ✗ Instance fields (stored state) — NOT allowed
//
// Why: extension methods are desugared to static method calls at compile time.
//      There is no object to store the field in.
//
// Workaround: use an Expando<T> — a weakly-keyed external hash map that
// associates arbitrary data with an existing object instance.

// Simulate adding a "tag" field to any object via Expando.
final _tags = Expando<String>('tag');

extension TagExtension on Object {
  String? get tag => _tags[this];
  set tag(String? value) => _tags[this] = value;
}

void demoNoInstanceFields() {
  print('\n--- 7. No instance fields — Expando workaround ---');

  final list1 = [1, 2, 3];
  final list2 = ['a', 'b'];

  list1.tag = 'numbers';
  list2.tag = 'letters';

  print('list1.tag = ${list1.tag}'); // numbers
  print('list2.tag = ${list2.tag}'); // letters

  // Expando uses weak references — it doesn't prevent GC of the object.
  // Once the object is collected, its Expando entry disappears automatically.
  print('(Expando entries vanish when the object is GCed)');
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoBuiltInExtensions();
  demoNullableExtension();
  demoGenericExtension();
  demoNameConflicts();
  demoGettersOperators();
  demoNoInstanceFields();
}
