// type_system.dart
// Dart's type hierarchy, dynamic vs Object, var/final/const, promotion,
// casts, typedefs, and structural vs nominal typing.

// ---------------------------------------------------------------------------
// 1. Dart's type hierarchy
// ---------------------------------------------------------------------------
//
//  Object?          ← top type (every type is a subtype, including Null)
//    ├── Object     ← top of non-null types
//    │     ├── num
//    │     │    ├── int
//    │     │    └── double
//    │     ├── String
//    │     ├── bool
//    │     ├── List<T>
//    │     ├── ... all other non-null types
//    │     └── Null is NOT a subtype of Object (sound null safety!)
//    ├── Null       ← the type of the literal `null`
//    └── dynamic    ← special: assignable to/from Object? but disables checks
//
//  Never            ← bottom type (subtype of everything, inhabits no values)
//
// Key insight: Null is a sibling of Object under Object?, NOT a subtype of
// Object. This is what makes null safety SOUND: Object is guaranteed non-null.

// ---------------------------------------------------------------------------
// 2. dynamic vs Object vs Object?
// ---------------------------------------------------------------------------

void dynamicVsObject() {
  // --- dynamic ---
  // Assignable to/from any type (the compiler trusts you completely).
  // No static type checks — errors only at runtime (NoSuchMethodError, etc.).
  // Avoid except for truly unknown types (JSON, reflection, interop).
  dynamic d = 'hello';
  d = 42; // reassignment to int — allowed (no type constraint)
  print(d.isEven); // compiles! But would throw if d were a String.
  // The compiler silently generates a dynamic dispatch; the runtime checks.

  // --- Object ---
  // The non-null supertype of everything. You CAN assign any non-null value.
  // But you can only call the methods defined on Object itself:
  //   ==, hashCode, toString, runtimeType, noSuchMethod
  Object o = 'hello';
  o = 42; // reassignment — allowed (int is-a Object)
  print(o.toString()); // OK: toString is on Object
  // print(o.isEven); // compile error — Object has no `isEven`
  // You must cast or type-check to use subtype methods.

  // --- Object? ---
  // Same as Object but also accepts null.
  Object? nullable = null; // fine
  nullable = 'now a string';
  // nullable.length; // compile error — might be null, might be non-String

  // Summary:
  //   dynamic  → gives up ALL static checking
  //   Object   → keeps static checking, accepts any non-null value
  //   Object?  → keeps static checking, accepts any value including null

  print('dynamic/Object/Object? demo done');
}

// ---------------------------------------------------------------------------
// 3. var, final, const
// ---------------------------------------------------------------------------
//
// These are BINDING modifiers, not type annotations.
// They control reassignability and compile-time evaluation, not the type itself.

void varFinalConst() {
  // var — type inferred from initializer; can be reassigned.
  var x = 42; // inferred as int
  x = 100; // OK — `var` is just `int x`

  // final — single assignment; cannot be reassigned after first assignment.
  //         The VALUE may still be mutable (e.g., a List you can still add to).
  final y = [1, 2, 3]; // inferred as List<int>
  y.add(4); // OK — the list is mutable
  // y = []; // compile error — y cannot be reassigned

  // const — compile-time constant. Deep immutability.
  //   1. The value must be fully known at compile time.
  //   2. The object graph is transitively immutable (canonical/interned).
  //   3. Two const objects with identical structure share the same identity.
  const z = [1, 2, 3]; // const List<int>
  // z.add(4); // throws UnsupportedError at runtime (immutable list)
  // z = [];   // compile error — const cannot be reassigned

  // Compile-time constant expressions:
  const pi = 3.14159;
  const area = pi * 2 * 2; // arithmetic on consts is const
  const greeting = 'Hello, ${"World"}'; // string interpolation of const is const

  // Deep immutability: const objects share identity if structurally equal.
  const a = [1, 2];
  const b = [1, 2];
  print(identical(a, b)); // true — same object in memory (canonicalized)

  final c = [1, 2];
  final d = [1, 2];
  print(identical(c, d)); // false — two separate List objects

  print('var=$x, final=$y, const=$z, pi=$pi, area=$area');
}

// const constructors: the whole object graph must be immutable.
class Point {
  final double x, y;
  const Point(this.x, this.y); // const constructor

  double get distanceFromOrigin => (x * x + y * y);
}

// ---------------------------------------------------------------------------
// 4. Type promotion with `is`
// ---------------------------------------------------------------------------

abstract class Shape {
  double get area;
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
  @override
  double get area => 3.14159 * radius * radius;
}

class Rectangle extends Shape {
  final double width, height;
  Rectangle(this.width, this.height);
  @override
  double get area => width * height;
}

void typePromotion(Shape shape) {
  // `is` check promotes the type inside the branch.
  if (shape is Circle) {
    // shape is promoted to Circle here — no cast needed.
    print('Circle with radius ${shape.radius}, area ${shape.area}');
  } else if (shape is Rectangle) {
    // shape is promoted to Rectangle here.
    print('Rectangle ${shape.width}x${shape.height}, area ${shape.area}');
  }

  // Promotion also applies in switch expressions with pattern matching (Dart 3+):
  String description = switch (shape) {
    Circle c => 'circle r=${c.radius}',
    Rectangle r => 'rect ${r.width}x${r.height}',
    _ => 'unknown shape',
  };
  print(description);
}

// ---------------------------------------------------------------------------
// 5. Type tests and casts: is, is!, as
// ---------------------------------------------------------------------------

void typeCasts() {
  Object value = 'hello world';

  // `is`  — returns bool, promotes type in scope
  if (value is String) {
    print(value.length); // promoted to String
  }

  // `is!` — negation of is; does NOT promote (you'd be in the false branch)
  if (value is! int) {
    print('not an int'); // value is still Object here
  }

  // `as`  — hard cast; throws CastError if the type is wrong at runtime.
  //         Use only when you are CERTAIN the type is correct.
  //         Prefer `is` check first to avoid surprises.
  String s = value as String; // OK here
  print(s.toUpperCase());

  // DANGER: as can throw at runtime:
  // int n = value as int; // throws: type 'String' is not a subtype of type 'int'

  // Safe pattern: check then cast (or just use the promoted variable from `is`):
  if (value is String) {
    // `value` is already String here — no need for `as`.
    print(value.split(' ').length);
  }

  // When `as` is appropriate:
  //   - You are converting between compatible numeric types (rarely needed in Dart)
  //   - You're asserting a type from an API that returns Object/dynamic and you
  //     have guaranteed knowledge of the runtime type.
  //   - After a nullable assertion: (value as String?) ← less common, use !
}

// ---------------------------------------------------------------------------
// 6. typedef — type aliases
// ---------------------------------------------------------------------------

// Classic use: alias a function signature so it can be named and reused.
typedef Predicate<T> = bool Function(T);
typedef Transformer<A, B> = B Function(A);
typedef JsonMap = Map<String, dynamic>;

// Dart 2.13+ generalized typedefs — alias ANY type, not just functions.
typedef StringList = List<String>;
typedef NullableInt = int?;
typedef Callback = void Function();

// Typedefs are purely cosmetic for the type system — they are aliases,
// NOT new distinct types. Predicate<int> IS bool Function(int).

bool isEven(int n) => n.isEven;
int doubled(int n) => n * 2;

void typedefDemo() {
  Predicate<int> pred = isEven; // same as bool Function(int)
  Transformer<int, int> transform = doubled;

  print(pred(4)); // true
  print(transform(5)); // 10

  JsonMap data = {'name': 'Alice', 'age': 30};
  print(data);

  // You can use the alias anywhere the underlying type is expected:
  StringList names = ['Alice', 'Bob'];
  print(names);
}

// ---------------------------------------------------------------------------
// 7. Structural vs nominal typing
// ---------------------------------------------------------------------------
//
// NOMINAL typing: a type relationship is defined by explicit declarations
//   (extends, implements, with). Two classes with identical structure but no
//   declared relationship are NOT substitutable.
//
// STRUCTURAL typing: compatibility is determined by shape (duck typing).
//   TypeScript uses structural typing for objects.
//
// Dart uses NOMINAL typing for classes and `implements` relationships.
// HOWEVER: Dart's implicit interface system makes it LOOK structural:
//   Every class implicitly defines an interface matching its public API.
//   Any other class can `implements` that interface without `extends`.
//   This is often called "implicit structural compatibility" or
//   "duck-typed at the declaration level."

class Logger {
  void log(String message) => print('[LOG] $message');
}

class AuditLogger {
  // AuditLogger has NO declared relationship to Logger.
  // But it can `implements Logger` because Logger's interface is implicit.
  void log(String message) => print('[AUDIT] $message');
}

// Function that takes a Logger — only a Logger (or subtype) works.
void doSomething(Logger logger) {
  logger.log('doing something');
}

// But because of implicit interfaces, AuditLogger CAN implement Logger:
class BetterAuditLogger implements Logger {
  @override
  void log(String message) => print('[AUDIT+] $message');
}

void structuralDemo() {
  doSomething(Logger()); // nominal
  doSomething(BetterAuditLogger()); // implements Logger — allowed

  // AuditLogger has no `implements Logger` — cannot be passed to doSomething.
  // AuditLogger al = AuditLogger();
  // doSomething(al); // compile error — AuditLogger is not a subtype of Logger
}

// ---------------------------------------------------------------------------
// 8. Intersection types — not supported, workarounds
// ---------------------------------------------------------------------------
//
// Dart does not have `A & B` intersection types.
// Workarounds:
//   a) Create an abstract class / mixin that inherits both.
//   b) Use generics with bounds + mixins.

abstract class Serializable {
  String serialize();
}

abstract class Cacheable {
  String get cacheKey;
}

// "Intersection": a type that IS BOTH Serializable AND Cacheable.
// Workaround: declare an abstract base that combines them.
abstract class SerializableAndCacheable
    implements Serializable, Cacheable {}

class User implements SerializableAndCacheable {
  final String id, name;
  const User(this.id, this.name);

  @override
  String serialize() => '{"id":"$id","name":"$name"}';

  @override
  String get cacheKey => 'user:$id';
}

// Now you can write functions that require BOTH capabilities:
void cacheAndSend(SerializableAndCacheable item) {
  print('Cache at key: ${item.cacheKey}');
  print('Payload: ${item.serialize()}');
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== dynamic vs Object vs Object? ===');
  dynamicVsObject();

  print('\n=== var / final / const ===');
  varFinalConst();

  // const Point canonicalization:
  const p1 = Point(1.0, 2.0);
  const p2 = Point(1.0, 2.0);
  print('Identical const Points: ${identical(p1, p2)}'); // true

  print('\n=== Type promotion ===');
  typePromotion(Circle(5.0));
  typePromotion(Rectangle(3.0, 4.0));

  print('\n=== Type casts: is, is!, as ===');
  typeCasts();

  print('\n=== typedef ===');
  typedefDemo();

  print('\n=== Structural vs Nominal typing ===');
  structuralDemo();

  print('\n=== Intersection type workaround ===');
  cacheAndSend(User('u1', 'Alice'));
}
