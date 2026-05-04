/// generics.dart
///
/// Generics in Dart — type bounds, variance, covariant, and advanced patterns.
/// Run with: dart run generics.dart

// ---------------------------------------------------------------------------
// OVERVIEW
// ---------------------------------------------------------------------------
// Dart generics are *reified* — the type parameter is available at runtime
// (unlike Java's type erasure).  This means `list is List<String>` works.
// Type parameters can be bounded, inferred, constrained, and coerced.

// ---------------------------------------------------------------------------
// 1. GENERIC CLASSES
// ---------------------------------------------------------------------------

// A simple generic container (Box<T>).
class Box<T> {
  T value;
  Box(this.value);

  // Methods can use T directly.
  Box<R> map<R>(R Function(T) transform) => Box(transform(value));

  @override
  String toString() => 'Box<$T>($value)';
}

// Generic with multiple type parameters.
class Pair<A, B> {
  final A first;
  final B second;
  const Pair(this.first, this.second);

  Pair<B, A> swap() => Pair(second, first);

  @override
  String toString() => 'Pair($first, $second)';
}

void demoGenericClasses() {
  print('\n--- 1. Generic classes ---');

  final intBox = Box(42);
  final strBox = Box('hello');
  print(intBox);   // Box<int>(42)
  print(strBox);   // Box<String>(hello)

  // map transforms the type.
  final lengthBox = strBox.map((s) => s.length);
  print(lengthBox); // Box<int>(5)

  // Pair<A, B>.
  final p = Pair(1, 'one');
  print(p);         // Pair(1, one)
  print(p.swap());  // Pair(one, 1)

  // Reified types — the type parameter is known at runtime.
  print(intBox is Box<int>);    // true
  print(intBox is Box<String>); // false  ← reification makes this work
}

// ---------------------------------------------------------------------------
// 2. GENERIC METHODS
// ---------------------------------------------------------------------------
// A method can introduce its own type parameter, independent of the class.

T identity<T>(T value) => value;

// Swap two values via a generic function.
(B, A) swapArgs<A, B>(A a, B b) => (b, a);

// Safely cast or return null.
T? safeCast<T>(Object? value) => value is T ? value : null;

// Generic method that builds a summary.
String summarize<T>(List<T> items, String Function(T) toStr) =>
    items.map(toStr).join(', ');

void demoGenericMethods() {
  print('\n--- 2. Generic methods ---');

  print(identity(42));        // 42
  print(identity('hello'));   // hello

  final (b, a) = swapArgs('x', 99);
  print('swapped: $a, $b');   // 99, x

  print(safeCast<int>(42));      // 42
  print(safeCast<int>('text'));  // null

  final s = summarize([1, 2, 3], (n) => '#$n');
  print('summary: $s'); // #1, #2, #3
}

// ---------------------------------------------------------------------------
// 3. TYPE BOUNDS — `extends`
// ---------------------------------------------------------------------------
// `T extends SomeClass` restricts what types can be used as T.
// Inside the generic, you can call any method declared on SomeClass.

abstract class Shape {
  double get area;
  String get name;
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
  @override double get area => 3.14159 * radius * radius;
  @override String get name => 'Circle(r=$radius)';
}

class Rectangle extends Shape {
  final double width, height;
  Rectangle(this.width, this.height);
  @override double get area => width * height;
  @override String get name => 'Rect(${width}x$height)';
}

// `T extends Shape` — inside, we can call `.area` and `.name`.
T largest<T extends Shape>(List<T> shapes) {
  return shapes.reduce((a, b) => a.area >= b.area ? a : b);
}

double totalArea<T extends Shape>(Iterable<T> shapes) =>
    shapes.fold(0, (sum, s) => sum + s.area);

void demoTypeBounds() {
  print('\n--- 3. Type bounds ---');

  final shapes = [Circle(3), Rectangle(2, 5), Circle(1), Rectangle(4, 4)];
  print('largest: ${largest(shapes).name}');       // Rect(4x4)
  print('total area: ${totalArea(shapes).toStringAsFixed(2)}');

  // Bounded to Comparable — allows sorting.
  List<T> sorted<T extends Comparable<T>>(List<T> items) =>
      [...items]..sort();

  print('sorted: ${sorted([3, 1, 4, 1, 5])}'); // [1, 1, 3, 4, 5]
  print('sorted: ${sorted(['banana', 'apple'])}'); // [apple, banana]
}

// ---------------------------------------------------------------------------
// 4. `covariant` KEYWORD
// ---------------------------------------------------------------------------
// Dart uses *invariant* generics: `List<Dog>` is NOT a `List<Animal>`.
// This is type-safe but sometimes inconvenient.
//
// The `covariant` keyword on a method parameter relaxes this at the call site:
// it tells the runtime to do a type check instead of a compile-time check.
// It makes things *unsound* in theory but is often practical.
//
// Most commonly seen when overriding a method and narrowing the parameter type.

class Animal {
  String get name => 'Animal';
  void interact(covariant Animal other) {
    print('${name} interacts with ${other.name}');
  }
}

class Dog extends Animal {
  @override
  String get name => 'Dog';

  // Without `covariant` on the parent, this override would require `other`
  // to stay `Animal`.  With `covariant` on the parent declaration, we can
  // narrow the parameter type to Dog — the runtime will check it.
  @override
  void interact(Dog other) {
    print('Dogs ${name} and ${other.name} play fetch!');
  }
}

void demoCovariant() {
  print('\n--- 4. covariant ---');

  final dog1 = Dog();
  final dog2 = Dog();
  dog1.interact(dog2); // Dogs Dog and Dog play fetch!

  // Treating as Animal still works at compile time.
  Animal a = dog1;
  // a.interact(dog2); // ok — dog2 is Animal at compile time, Dog at runtime
  a.interact(dog2); // runtime checks dog2 is Dog ✓

  // Invariance of List:
  final List<Dog> dogs = [Dog(), Dog()];
  // List<Animal> animals = dogs; // compile error: List<Dog> not List<Animal>
  // With covariant, you can write a method that accepts List<covariant Dog>
  // but the general solution is to use a type-bounded generic instead.
  print('List<Dog> is List<Animal>: ${dogs is List<Animal>}');
  // true! Dart lists ARE covariant in their element type at runtime
  // (this is a deliberate unsound choice for usability, like Java arrays).
}

// ---------------------------------------------------------------------------
// 5. Object? AS THE TOP TYPE — Never AS BOTTOM TYPE
// ---------------------------------------------------------------------------
// Dart's type hierarchy:
//   Object?  — top type: every type is a subtype.
//   Object   — non-nullable top.
//   dynamic  — opts out of static checking; assignable to/from everything.
//   Null     — only null.
//   Never    — bottom type: subtype of every type; a value of type Never
//               can never exist (functions that always throw return Never).
//
// `void` is special: assignable to Object? but its value cannot be used.

// A function that always throws has return type Never.
Never fail(String message) => throw StateError(message);

// Generic function bounded by Object? (accepts nullable types).
bool isNullOrEmpty<T extends Object?>(T? value) {
  if (value == null) return true;
  if (value is String) return value.isEmpty;
  if (value is Iterable) return value.isEmpty;
  return false;
}

void demoTopBottom() {
  print('\n--- 5. Object? top type, Never bottom type ---');

  // Object? holds anything.
  Object? x = 42;
  x = 'hello';
  x = null;
  print('Object? can hold null: $x'); // null

  // dynamic bypasses static checks — use sparingly.
  dynamic d = 'text';
  print(d.length); // 4 — no compile-time check; runtime dispatch

  // Never: a function returning Never can be used anywhere a value is needed
  // because Never is a subtype of all types.  Useful for exhaustive checks.
  int nonNull(int? v) => v ?? fail('expected non-null'); // fail returns Never

  print(nonNull(5));   // 5
  try { nonNull(null); } catch (e) { print('caught: $e'); }

  print(isNullOrEmpty(null));    // true
  print(isNullOrEmpty(''));      // true
  print(isNullOrEmpty('hi'));    // false
  print(isNullOrEmpty(<int>[])); // true
}

// ---------------------------------------------------------------------------
// 6. TYPE INVARIANCE — why List<Dog> is not List<Animal>
// ---------------------------------------------------------------------------
// Dart *generics* are invariant by design for safety:
//   List<Dog> is NOT a List<Animal>
//
// If it were, you could do:
//   List<Animal> animals = dogs; // hypothetical
//   animals.add(Cat());          // no compile error
//   Dog d = dogs[0];             // runtime crash — Cat is not Dog!
//
// However, Dart's BUILT-IN List is covariant at runtime (for Java compat):
//   dogs is List<Animal>  → true at runtime
//   But adding a Cat would throw at runtime (checked covariance).

class Cat extends Animal {
  @override String get name => 'Cat';
}

void demoInvariance() {
  print('\n--- 6. Invariance of generics ---');

  final dogs = <Dog>[Dog(), Dog()];

  // Compile error (uncomment to see):
  // List<Animal> animals = dogs;

  // Workaround 1: use a type-bounded generic method.
  void feedAll<T extends Animal>(List<T> list) {
    for (final a in list) print('feeding ${a.name}');
  }
  feedAll(dogs); // fine — T inferred as Dog

  // Workaround 2: cast (unsound, use carefully).
  final List<Animal> animals = dogs.cast<Animal>(); // runtime copy cast
  print('cast works: ${animals.length}');

  // Workaround 3: use List<Animal> from the start.
  final List<Animal> mixed = [Dog(), Cat()];
  for (final a in mixed) print(a.name);
}

// ---------------------------------------------------------------------------
// 7. FACTORY CONSTRUCTORS WITH GENERICS
// ---------------------------------------------------------------------------
// Factory constructors can inspect the type parameter at runtime (reification)
// and return different implementations.

abstract class Repository<T> {
  T? findById(int id);

  // Factory that selects an implementation based on T.
  factory Repository.inMemory(Map<int, T> data) = _InMemoryRepository<T>;
}

class _InMemoryRepository<T> implements Repository<T> {
  final Map<int, T> _data;
  _InMemoryRepository(this._data);

  @override
  T? findById(int id) => _data[id];
}

void demoFactoryWithGenerics() {
  print('\n--- 7. Factory constructors with generics ---');

  final repo = Repository<String>.inMemory({
    1: 'Alice',
    2: 'Bob',
    3: 'Carol',
  });

  print(repo.findById(2));   // Bob
  print(repo.findById(99));  // null

  // Type is reified — you can check it.
  print(repo is Repository<String>); // true
  print(repo is Repository<int>);    // false
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoGenericClasses();
  demoGenericMethods();
  demoTypeBounds();
  demoCovariant();
  demoTopBottom();
  demoInvariance();
  demoFactoryWithGenerics();
}
