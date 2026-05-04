/// factories.dart
///
/// Constructors in Dart — factory, named, redirecting, const, singleton, subtype.
/// Run with: dart run factories.dart

// ---------------------------------------------------------------------------
// 1. GENERATIVE vs FACTORY CONSTRUCTORS
// ---------------------------------------------------------------------------
// A *generative* constructor always creates a new instance of the class.
// A *factory* constructor may:
//   • Return a cached/existing instance (singleton, object pool).
//   • Return a subtype (polymorphic factory).
//   • Perform complex initialisation that cannot be expressed in an
//     initializer list.
//   • NOT call `super()` — it is responsible for returning a valid instance
//     (which it typically creates by calling a generative constructor).
//
// Declared with the `factory` keyword; must contain a `return` statement.

class Point {
  final double x, y;

  // Generative constructor — always creates a new instance.
  const Point(this.x, this.y);

  // Named generative constructor.
  Point.origin() : x = 0, y = 0;

  // Factory constructor — could return cached instance (see singleton below).
  factory Point.fromList(List<double> coords) {
    if (coords.length != 2) throw ArgumentError('need exactly 2 coords');
    return Point(coords[0], coords[1]);
  }

  factory Point.fromMap(Map<String, double> map) {
    return Point(map['x'] ?? 0, map['y'] ?? 0);
  }

  double get distanceFromOrigin => (x * x + y * y).abs().toDouble();

  @override
  String toString() => 'Point($x, $y)';
}

void demoGenerativeVsFactory() {
  print('\n--- 1. Generative vs factory ---');

  final p1 = Point(3, 4);
  final p2 = Point.origin();
  final p3 = Point.fromList([1.0, 2.0]);
  final p4 = Point.fromMap({'x': 5.0, 'y': 6.0});

  print(p1); // Point(3.0, 4.0)
  print(p2); // Point(0.0, 0.0)
  print(p3); // Point(1.0, 2.0)
  print(p4); // Point(5.0, 6.0)
}

// ---------------------------------------------------------------------------
// 2. NAMED CONSTRUCTORS — .fromJson, .fromMap, etc.
// ---------------------------------------------------------------------------
// Dart does not support overloaded constructors; named constructors serve
// as the alternative.  By convention:
//   `.fromJson(Map<String,dynamic>)` — deserialise from JSON map
//   `.fromMap(Map<String,dynamic>)`  — similar
//   `.empty()`                       — empty/default state
//   `.copyWith(...)` is NOT a constructor; it's a method

class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  // Primary generative constructor.
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isAdmin = false,
  });

  // Named constructor: deserialization from a JSON-like map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }

  // Named constructor: build a "guest" user.
  const User.guest()
      : id = 0,
        name = 'Guest',
        email = '',
        isAdmin = false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'is_admin': isAdmin,
      };

  @override
  String toString() => 'User(id=$id, name=$name, admin=$isAdmin)';
}

void demoNamedConstructors() {
  print('\n--- 2. Named constructors ---');

  final u = User(id: 1, name: 'Alice', email: 'alice@example.com', isAdmin: true);
  final guest = User.guest();
  final fromJson = User.fromJson({'id': 2, 'name': 'Bob', 'email': 'b@b.com'});

  print(u);        // User(id=1, name=Alice, admin=true)
  print(guest);    // User(id=0, name=Guest, admin=false)
  print(fromJson); // User(id=2, name=Bob, admin=false)
  print(u.toJson());
}

// ---------------------------------------------------------------------------
// 3. REDIRECTING CONSTRUCTORS
// ---------------------------------------------------------------------------
// A redirecting constructor delegates to another constructor of the SAME class
// using the `: this(...)` syntax.  It cannot have a body.
// Useful for providing convenience overloads or default values.

class Temperature {
  final double celsius;

  const Temperature(this.celsius);

  // Redirecting constructor — no body, just delegates.
  const Temperature.fromFahrenheit(double f) : this((f - 32) * 5 / 9);
  const Temperature.fromKelvin(double k)     : this(k - 273.15);
  const Temperature.absoluteZero()           : this(-273.15);

  double get fahrenheit => celsius * 9 / 5 + 32;
  double get kelvin => celsius + 273.15;

  @override
  String toString() =>
      '${celsius.toStringAsFixed(2)}°C / ${fahrenheit.toStringAsFixed(2)}°F';
}

void demoRedirectingConstructors() {
  print('\n--- 3. Redirecting constructors ---');

  final boiling = Temperature(100);
  final body    = Temperature.fromFahrenheit(98.6);
  final abs0    = Temperature.absoluteZero();

  print('boiling: $boiling');  // 100.00°C / 212.00°F
  print('body:    $body');     // 37.00°C / 98.60°F
  print('abs0:    $abs0');     // -273.15°C / -459.67°F
}

// ---------------------------------------------------------------------------
// 4. CONST CONSTRUCTORS AND CANONICALIZATION
// ---------------------------------------------------------------------------
// A `const` constructor:
//   • All fields must be `final`.
//   • The class must not extend any class with non-trivial state (effectively
//     must extend Object directly, or another const-constructible class).
//   • Evaluated at compile time when called with constant arguments.
//   • The runtime *canonicalizes* identical const instances: two `const`
//     constructions with the same arguments return the SAME object (identical).
//
// IMPORTANT: `const MyClass(...)` is only canonical when the surrounding
// context is also a constant expression.  In non-const contexts, each call
// may return a new object even with a const constructor.

class Color {
  final int r, g, b;

  // const constructor requires all fields to be final.
  const Color(this.r, this.g, this.b);

  static const red   = Color(255, 0, 0);
  static const green = Color(0, 255, 0);
  static const blue  = Color(0, 0, 255);

  @override
  bool operator ==(Object other) =>
      other is Color && r == other.r && g == other.g && b == other.b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'Color($r, $g, $b)';
}

void demoConstConstructors() {
  print('\n--- 4. const constructors & canonicalization ---');

  // With the `const` keyword → canonicalized → identical.
  const c1 = Color(255, 0, 0);
  const c2 = Color(255, 0, 0);
  print('const identical: ${identical(c1, c2)}'); // true — same object!

  // Without the `const` keyword → new objects (not identical, but equal).
  final c3 = Color(255, 0, 0);
  final c4 = Color(255, 0, 0);
  print('non-const identical: ${identical(c3, c4)}'); // false — different objects
  print('non-const equal:     ${c3 == c4}');          // true

  // Static const singletons are always identical to each other.
  print('Color.red identical to const: ${identical(Color.red, const Color(255, 0, 0))}'); // true

  // Const objects are deeply immutable — cannot set fields, cannot be mutated.
  // color.r = 0; // compile error: final field
}

// ---------------------------------------------------------------------------
// 5. SINGLETON VIA FACTORY CONSTRUCTOR
// ---------------------------------------------------------------------------
// The classic Dart singleton pattern: the factory constructor returns the
// same instance every time.  The actual instance lives in a static field.

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  // The factory returns the cached instance — no new object is ever created.
  factory AppConfig() => _instance;

  // Private generative constructor — prevents external instantiation.
  AppConfig._internal() {
    print('  [AppConfig] initialised');
  }

  String theme = 'light';
  String locale = 'en';

  @override
  String toString() => 'AppConfig(theme=$theme, locale=$locale)';
}

void demoSingleton() {
  print('\n--- 5. Singleton via factory ---');

  final cfg1 = AppConfig();   // prints "initialised" once
  final cfg2 = AppConfig();   // returns cached — no new instance

  cfg1.theme = 'dark';
  print('cfg2.theme = ${cfg2.theme}'); // dark — same object
  print('identical: ${identical(cfg1, cfg2)}'); // true
}

// ---------------------------------------------------------------------------
// 6. FACTORY FOR SUBTYPE SELECTION
// ---------------------------------------------------------------------------
// A factory on an abstract class can inspect arguments and return the
// appropriate concrete subclass.  Callers only know the abstract type.

abstract class Logger {
  void log(String message);

  // Factory selects a concrete implementation.
  factory Logger(String type) {
    switch (type) {
      case 'console': return _ConsoleLogger();
      case 'null':    return _NullLogger();
      case 'prefix':  return _PrefixLogger('[APP]');
      default:        throw ArgumentError('Unknown logger type: $type');
    }
  }

  // Named factory for a common variant.
  factory Logger.prefixed(String prefix) => _PrefixLogger(prefix);
}

class _ConsoleLogger implements Logger {
  @override void log(String m) => print('[CONSOLE] $m');
}

class _NullLogger implements Logger {
  @override void log(String m) {} // discard
}

class _PrefixLogger implements Logger {
  final String prefix;
  _PrefixLogger(this.prefix);
  @override void log(String m) => print('$prefix $m');
}

void demoSubtypeFactory() {
  print('\n--- 6. Factory for subtype selection ---');

  final loggers = [
    Logger('console'),
    Logger('null'),
    Logger.prefixed('[DEBUG]'),
  ];

  for (final logger in loggers) {
    logger.log('hello from ${logger.runtimeType}');
  }
  // [CONSOLE] hello from _ConsoleLogger
  // (silent)
  // [DEBUG] hello from _PrefixLogger
}

// ---------------------------------------------------------------------------
// 7. `external` CONSTRUCTORS (brief)
// ---------------------------------------------------------------------------
// An `external` constructor (or method) declares the signature in Dart but
// has its implementation provided by a platform-specific file (via a
// conditional import or dart:ffi / package:js interop).
//
// Syntax:
//   external MyClass(int value);
//   external factory MyClass.fromNative(Pointer<Void> ptr);
//
// The linker will supply the body at compile time via:
//   @patch class MyClass { MyClass(int v) { ... } }
//
// Used by: dart:core (DateTime, String), dart:io (Socket), Flutter engine.
// Rarely written by application code; mostly SDK / FFI / JS interop.
//
// (No runtime demo — would require a multi-file setup.)

void demoExternal() {
  print('\n--- 7. external constructors (notes only) ---');
  print('  Used in SDK internals and FFI/JS interop.');
  print('  Declares a constructor in Dart; implementation is platform-supplied.');
  print('  Example: DateTime.now() is external in dart:core.');
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoGenerativeVsFactory();
  demoNamedConstructors();
  demoRedirectingConstructors();
  demoConstConstructors();
  demoSingleton();
  demoSubtypeFactory();
  demoExternal();
}
