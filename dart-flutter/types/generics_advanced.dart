// generics_advanced.dart
// Advanced Dart generics: invariance, covariant, bounds, reification, Never, Object?.

// ---------------------------------------------------------------------------
// 1. Invariance — List<Dog> is NOT a List<Animal>
// ---------------------------------------------------------------------------
//
// In Dart, generic types are INVARIANT by default.
// Even if Dog extends Animal, List<Dog> is NOT a subtype of List<Animal>.
//
// Why? Because allowing it breaks type safety:
//   List<Dog> dogs = [Labrador()];
//   List<Animal> animals = dogs;   // if allowed...
//   animals.add(Cat());            // Cat is an Animal — compiles fine
//   Dog d = dogs[1];               // but dogs[1] is actually a Cat → crash!
//
// This is the classic "covariant generics break write safety" problem.
// Java makes arrays covariant (unsound!) but generics invariant.
// Dart makes ALL generics invariant by default (sound).

class Animal {
  String get sound => '...';
}

class Dog extends Animal {
  @override
  String get sound => 'woof';
  void fetch() => print('Fetching!');
}

class Cat extends Animal {
  @override
  String get sound => 'meow';
}

void invarianceDemo() {
  List<Dog> dogs = [Dog(), Dog()];

  // This line does NOT compile (uncomment to see):
  // List<Animal> animals = dogs;  // Error: List<Dog> is not List<Animal>

  // The safe alternative is to use a read-only supertype:
  // Iterable<Animal> — covariant in Dart's built-in collection interfaces
  // because Iterable is read-only (no add/write methods).
  Iterable<Animal> animals = dogs; // OK! Iterable<T> is covariant in T.
  for (final a in animals) print(a.sound);
}

// ---------------------------------------------------------------------------
// 2. `covariant` keyword — opting into covariant parameter checking
// ---------------------------------------------------------------------------
//
// The `covariant` keyword on a method parameter tells the compiler:
//   "I know this breaks strict subtype checking; enforce it at runtime instead."
//
// Primary use-case: operator== overrides and collection-style classes where
// you want subclass-specific parameter types without casting.

class Shape {
  bool intersects(covariant Shape other) => false;
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);

  // Without `covariant` on the parent, `other` here would need to be Shape.
  // With `covariant`, we can narrow the type to Circle. The runtime will
  // throw if the caller passes a non-Circle — it's a runtime contract, not
  // a compile-time one.
  @override
  bool intersects(Circle other) {
    // simplified: real impl would compute distance between centers
    return true;
  }
}

// ---------------------------------------------------------------------------
// 3. Bounded type parameters — T extends Comparable<T>
// ---------------------------------------------------------------------------
//
// Bounds restrict which types may be used as type arguments.
// This lets you call methods that are defined on the bound type.

class SortedList<T extends Comparable<T>> {
  final List<T> _items = [];

  void add(T item) {
    _items.add(item);
    _items.sort(); // OK because T has compareTo() from Comparable<T>
  }

  T get min => _items.first;
  T get max => _items.last;

  @override
  String toString() => _items.toString();
}

// Multiple bounds are not directly supported (Dart has no `&` intersection type),
// but the standard workaround is a mixin or abstract class that combines them:

mixin Printable {
  void printSelf();
}

// A class that satisfies BOTH Comparable and Printable:
class Score extends Comparable<Score> with Printable {
  final int value;
  Score(this.value);

  @override
  int compareTo(Score other) => value.compareTo(other.value);

  @override
  void printSelf() => print('Score($value)');

  @override
  String toString() => 'Score($value)';
}

// Now you can write a function that requires both:
// (Dart doesn't allow <T extends Comparable<T> & Printable>, but you can
// create an abstract base / mixin that merges the constraints.)
abstract class ComparableAndPrintable<T> implements Comparable<T>, Printable {}

// ---------------------------------------------------------------------------
// 4. Generic methods vs generic classes
// ---------------------------------------------------------------------------
//
// Generic CLASSES: the type parameter is fixed when the object is constructed.
// Generic METHODS: the type parameter is resolved at each call site independently.

class Pair<A, B> {
  final A first;
  final B second;
  const Pair(this.first, this.second);

  // A generic METHOD on a generic class — T is independent from A and B.
  Pair<A, T> withSecond<T>(T newSecond) => Pair(first, newSecond);
}

// Standalone generic function — T is inferred from the argument at each call site.
T identity<T>(T value) => value;

// Generic function with a bound:
T maxOf<T extends Comparable<T>>(T a, T b) => a.compareTo(b) >= 0 ? a : b;

// ---------------------------------------------------------------------------
// 5. Object? as the top type
// ---------------------------------------------------------------------------
//
// In Dart's sound null-safety type hierarchy:
//   Object?  — TOP type: every type (including Null) is a subtype of Object?
//   Object   — every non-null type is a subtype of Object
//   dynamic  — special: assignable to/from everything, disables static checks
//   void     — "discard this value" — only used as return type
//
// Object? is the true top because it includes null.
// Object is the top of the non-null hierarchy.

void topTypeDemo() {
  // Object? accepts absolutely anything:
  Object? anything = 42;
  anything = 'string';
  anything = null;
  anything = [1, 2, 3];

  // To use it, you must cast or type-check:
  if (anything is List) {
    print(anything.length); // promoted to List inside this block
  }

  // Object (non-nullable top) — still need a cast to call subtype methods:
  Object nonNullTop = 'hello';
  // nonNullTop.length; // compile error — Object has no `length`
  print((nonNullTop as String).length); // must cast
}

// ---------------------------------------------------------------------------
// 6. Never as the bottom type
// ---------------------------------------------------------------------------
//
// Never is a subtype of every type — it sits at the very bottom of the
// type hierarchy. A function returning Never never returns normally:
// it either throws, loops forever, or calls exit().
//
// Practical uses:
//   - Type inference: Never means "this branch is unreachable" and the
//     compiler treats its type as compatible with anything.
//   - `throw` expressions have type Never, which is why you can write:
//       int x = condition ? 42 : throw StateError('...');
//     The ternary is (int, Never) — Never widens to int, so the result is int.

Never fail(String message) => throw ArgumentError(message);

// The return type Never also appears in the Dart SDK:
//   external Never _throwConcurrentModificationError();

void neverDemo() {
  // Because throw has type Never, this is valid:
  int value = DateTime.now().second.isEven ? 1 : throw StateError('odd!');
  print(value);

  // Never is a subtype of int, String, List — anything.
  // So `fail()` can be used wherever any type is expected:
  // String s = fail('problem');  // compiles — Never <: String
}

// ---------------------------------------------------------------------------
// 7. Dart RETAINS generic type info at runtime (reification)
// ---------------------------------------------------------------------------
//
// Unlike Java (which erases generics at runtime), Dart REIFIES generic types:
// the full parameterized type is available at runtime via runtimeType and `is`.
//
// This means:
//   - `is List<String>` works correctly at runtime.
//   - You can print the exact generic type.
//   - There is no equivalent of Java's "unchecked cast" warning.

void reificationDemo() {
  final List<String> strings = ['a', 'b'];
  final List<int> ints = [1, 2, 3];
  final List<dynamic> dynamics = ['x', 1];

  // Runtime type checks on parameterized types:
  print(strings is List<String>); // true
  print(strings is List<int>); // false — NOT erased, unlike Java!
  print(ints is List<int>); // true
  print(dynamics is List<String>); // false
  print(dynamics is List<dynamic>); // true

  // The full generic type is preserved in runtimeType:
  print(strings.runtimeType); // List<String>
  print(ints.runtimeType); // List<int>

  // This is why you can write type-safe factory functions at runtime:
  dynamic mystery = pickOne(strings, ints);
  if (mystery is List<String>) {
    print('Got string list: ${mystery.join(', ')}');
  } else if (mystery is List<int>) {
    print('Got int list: $mystery');
  }
}

dynamic pickOne(dynamic a, dynamic b) =>
    DateTime.now().second.isEven ? a : b;

// ---------------------------------------------------------------------------
// 8. `is` checks with generics
// ---------------------------------------------------------------------------
//
// Because Dart reifies generics, `is` checks work for fully parameterized types.
// However, you cannot use a type VARIABLE in an `is` check at runtime.

void isChecksWithGenerics() {
  // Works: fully-specified parameterized types
  Object val = <String>['hello'];
  print(val is List<String>); // true
  print(val is List<int>); // false

  // Using a type parameter in `is` — the type variable is ERASED:
  // bool isListOf<T>(Object obj) => obj is List<T>;  // T is erased to Object
  // Instead, use a workaround with type tokens or `TypeMatcher`.

  // Workaround: pass the type as an explicit argument using `is` + a helper.
  print(isListOf<String>(val)); // true
  print(isListOf<int>(val)); // false
}

// This is a common pattern: use the reified type T in a helper via generic method.
bool isListOf<T>(Object obj) {
  // At each call site T is reified to the actual type argument supplied.
  // `obj is List<T>` works correctly because T is reified by the caller.
  return obj is List<T>;
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== Invariance demo ===');
  invarianceDemo();

  print('\n=== covariant keyword ===');
  final c1 = Circle(3), c2 = Circle(5);
  print('c1 intersects c2: ${c1.intersects(c2)}');

  print('\n=== Bounded type parameter ===');
  final sl = SortedList<int>();
  sl..add(5)..add(2)..add(8)..add(1);
  print('Sorted: $sl | min=${sl.min} | max=${sl.max}');

  final scores = SortedList<Score>();
  scores..add(Score(70))..add(Score(95))..add(Score(50));
  print('Scores: $scores | best=${scores.max}');

  print('\n=== Generic methods ===');
  print(identity<String>('hello'));
  print(identity(42)); // T inferred as int
  print(maxOf(3, 7));
  print(maxOf('apple', 'zebra'));

  final pair = Pair('key', 100);
  final newPair = pair.withSecond(3.14); // T inferred as double
  print('${newPair.first} => ${newPair.second}');

  print('\n=== Object? top type ===');
  topTypeDemo();

  print('\n=== Never bottom type ===');
  neverDemo();

  print('\n=== Reification (generics at runtime) ===');
  reificationDemo();

  print('\n=== is checks with generics ===');
  isChecksWithGenerics();
}
