/// mixins.dart
///
/// Mixins in Dart — composition, linearization, and practical patterns.
/// Run with: dart run mixins.dart

// ---------------------------------------------------------------------------
// OVERVIEW: mixin vs class
// ---------------------------------------------------------------------------
// A `mixin` is a unit of reuse that can be layered onto a class hierarchy
// WITHOUT inheritance.  It is not a standalone class — you cannot instantiate
// a mixin directly.
//
//   class Dog extends Animal with Swimmer, Runner {}
//
// Key differences from a class:
//   • `mixin` cannot have generative constructors (no constructor with body).
//   • `mixin` must be declared with the `mixin` keyword (or `mixin class`).
//   • Applied with `with`, not `extends`.
//   • Multiple mixins are allowed; a class can only extend one class.
//
// `mixin class` (Dart 3): can be used both as a standalone class AND as a
// mixin.  See abstract_interfaces.dart for more on Dart 3 modifiers.

// ---------------------------------------------------------------------------
// 1. BASIC MIXIN — no constraint
// ---------------------------------------------------------------------------
mixin Printable {
  // Mixins can declare abstract members (no `abstract` keyword needed —
  // an unimplemented member is implicitly abstract in a mixin).
  String get displayName;

  void printInfo() {
    print('[Printable] $displayName');
  }
}

mixin Timestamped {
  // A mixin CAN have field declarations (just not constructor parameters).
  // The field is initialised inline.
  final DateTime createdAt = DateTime.now();

  String get age {
    final diff = DateTime.now().difference(createdAt);
    return '${diff.inMilliseconds}ms ago';
  }
}

class Document with Printable, Timestamped {
  @override
  final String displayName;
  final String content;

  Document(this.displayName, this.content);
}

void demoBasicMixin() {
  print('\n--- 1. Basic mixin ---');
  final doc = Document('Report', 'Lorem ipsum');
  doc.printInfo();                // [Printable] Report
  print('created: ${doc.age}');   // e.g. 0ms ago
}

// ---------------------------------------------------------------------------
// 2. `on` CONSTRAINT — restricts which classes can use the mixin
// ---------------------------------------------------------------------------
// `mixin Foo on Bar` means:
//   • Only classes that extend (or implement) Bar can use Foo.
//   • Inside Foo you can call members defined on Bar, including `super.method()`.
//
// This lets a mixin depend on state/behaviour provided by its host class.

abstract class Animal {
  String get name;
  String breathe() => '$name breathes air';
}

// This mixin can only be applied to classes that extend Animal.
mixin Swimming on Animal {
  String swim() => '$name swims';  // `name` comes from Animal
}

mixin Flying on Animal {
  String fly() => '$name flies';
}

// Applying both — valid because Duck extends Animal.
class Duck extends Animal with Swimming, Flying {
  @override
  final String name = 'Duck';
}

// This would be a compile error:
// class Rock with Swimming {} // Error: Rock must extend Animal

void demoOnConstraint() {
  print('\n--- 2. `on` constraint ---');
  final duck = Duck();
  print(duck.breathe()); // Duck breathes air
  print(duck.swim());    // Duck swims
  print(duck.fly());     // Duck flies
}

// ---------------------------------------------------------------------------
// 3. MIXIN LINEARIZATION ORDER (C3 MRO)
// ---------------------------------------------------------------------------
// When multiple mixins define the same method, the one that comes LAST in
// the `with` clause wins — but each mixin's `super` call goes to the
// PREVIOUS layer.  The order is right-to-left: the rightmost mixin is the
// "innermost", closest to the actual class.
//
// Class: class C extends Base with M1, M2, M3
// MRO:   C → M3 → M2 → M1 → Base → Object
//
// This is called C3 Linearization and is the same algorithm used by Python.

mixin LogA on Object {
  String process(String input) => 'A(${super.toString()} $input)';
}

mixin LogB on Object {
  String process(String input) => 'B(${super.toString()} $input)';
}

// A concrete base that will be mixed into.
class Base {
  String process(String input) => 'Base($input)';
  @override
  String toString() => 'Base';
}

class Layered extends Base with LogA, LogB {
  // MRO: Layered → LogB → LogA → Base
  // Calling Layered().process('x'):
  //   Layered has no override → goes to LogB.process
  //   LogB calls super.process → goes to LogA.process
  //   LogA calls super.process → goes to Base.process
}

mixin Layer1 {
  String describe() => 'Layer1';
}

mixin Layer2 on Layer1 {
  @override
  String describe() => 'Layer2 > ${super.describe()}';
}

mixin Layer3 on Layer2 {
  @override
  String describe() => 'Layer3 > ${super.describe()}';
}

// Order matters: with Layer1, Layer2, Layer3 gives:
//   Layer3.describe → Layer2.describe → Layer1.describe
class Stacked with Layer1, Layer2, Layer3 {}

void demoLinearization() {
  print('\n--- 3. Mixin linearization ---');
  final s = Stacked();
  print(s.describe()); // Layer3 > Layer2 > Layer1

  // Demonstrate layered processing via super chains.
  // (LogA/LogB demo is complex due to super on Object; showing Stacked is cleaner.)
  print('(rightmost mixin wins, super chains back through earlier mixins)');
}

// ---------------------------------------------------------------------------
// 4. CALLING super IN MIXINS
// ---------------------------------------------------------------------------
// Mixins can call `super.method()` to invoke the version from the next layer
// in the linearization chain.  This is how aspect-oriented behaviour is woven
// in (logging, caching, validation before/after base logic).

abstract class Service {
  String fetch(String key);
}

mixin CachingMixin on Service {
  final _cache = <String, String>{};

  @override
  String fetch(String key) {
    if (_cache.containsKey(key)) {
      print('  [cache hit] $key');
      return _cache[key]!;
    }
    print('  [cache miss] $key');
    final result = super.fetch(key); // delegate to next layer
    _cache[key] = result;
    return result;
  }
}

mixin LoggingMixin on Service {
  @override
  String fetch(String key) {
    print('  [log] fetching $key');
    final result = super.fetch(key);
    print('  [log] got: $result');
    return result;
  }
}

class DatabaseService extends Service {
  @override
  String fetch(String key) => 'db:$key'; // simulate DB lookup
}

// MRO: CachedLoggingDB → LoggingMixin → CachingMixin → DatabaseService
class CachedLoggingDB extends DatabaseService with CachingMixin, LoggingMixin {}

void demoSuperInMixin() {
  print('\n--- 4. super in mixins ---');
  final svc = CachedLoggingDB();
  print('First fetch:');
  svc.fetch('user:1');  // miss, then log
  print('Second fetch (same key):');
  svc.fetch('user:1');  // cache hit
}

// ---------------------------------------------------------------------------
// 5. MIXINS CANNOT HAVE CONSTRUCTORS (only field declarations)
// ---------------------------------------------------------------------------
// Mixins cannot declare generative constructors — attempting to do so is a
// compile-time error.  This prevents the initialization-order ambiguity that
// would arise from multiple inheritance with constructor chaining.
//
// ALLOWED: field declarations with initializers.
// ALLOWED: `late` fields.
// NOT ALLOWED: constructor bodies or constructor parameters.
//
// Example of what's NOT allowed (commented out to allow compilation):
//
//   mixin BadMixin {
//     BadMixin(this.value); // Error: mixin cannot have generative constructor
//     final int value;
//   }
//
// Workaround: use abstract getters that the applying class must implement.

mixin Configurable {
  // Can't inject via constructor; declare what we need as abstract getters.
  int get maxRetries;
  Duration get timeout;

  String describe() => 'maxRetries=$maxRetries, timeout=$timeout';
}

class ApiClient with Configurable {
  @override
  final int maxRetries = 3;
  @override
  final Duration timeout = Duration(seconds: 30);
}

void demoNoConstructors() {
  print('\n--- 5. Mixins cannot have constructors ---');
  final client = ApiClient();
  print(client.describe()); // maxRetries=3, timeout=0:00:30.000000
}

// ---------------------------------------------------------------------------
// 6. PRACTICAL EXAMPLES
// ---------------------------------------------------------------------------

// --- Logging mixin ---
mixin Logging {
  String get logTag => runtimeType.toString();

  void log(String message) => print('[$logTag] $message');
  void logError(Object e, [StackTrace? st]) =>
      print('[$logTag] ERROR: $e${st != null ? "\n$st" : ""}');
}

// --- Serializable mixin (requires the class to implement toMap) ---
mixin Serializable {
  Map<String, dynamic> toMap();

  String serialize() {
    final map = toMap();
    return map.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }
}

// --- EquatableMixin-style: auto equals + hashCode from `props` ---
mixin Equatable {
  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final o = other as Equatable;
    if (props.length != o.props.length) return false;
    for (var i = 0; i < props.length; i++) {
      if (props[i] != o.props[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(props);

  @override
  String toString() => '${runtimeType}(${props.join(', ')})';
}

class User with Logging, Serializable, Equatable {
  final int id;
  final String name;
  User(this.id, this.name);

  @override
  List<Object?> get props => [id, name];

  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

void demoPracticalMixins() {
  print('\n--- 6. Practical mixins ---');

  final alice = User(1, 'Alice');
  final alice2 = User(1, 'Alice');
  final bob = User(2, 'Bob');

  alice.log('created');                        // [User] created
  print(alice.serialize());                    // id=1, name=Alice
  print('alice == alice2: ${alice == alice2}');// true
  print('alice == bob:    ${alice == bob}');   // false
  print(alice);                                // User(1, Alice)
}

// ---------------------------------------------------------------------------
// 7. MIXINS vs ABSTRACT CLASSES vs INTERFACES
// ---------------------------------------------------------------------------
// Abstract class: can be extended (one per class), can have constructors,
//                 provides both interface and partial implementation.
// Interface:      in Dart, every class implicitly defines an interface.
//                 `implements` requires you to re-implement all members.
// Mixin:          added with `with`, can provide implementation, stackable,
//                 no constructors, optional `on` constraint.
//
// Choose mixin when:
//   ✓ You want to add reusable behaviour to unrelated classes.
//   ✓ You need to compose multiple capabilities orthogonally.
//   ✗ NOT when you need constructor injection (use abstract class or DI).
//   ✗ NOT when you need a strong "is-a" relationship (use extends).

void demoComparison() {
  print('\n--- 7. Mixin vs abstract class vs interface ---');
  print('See inline comments — runtime demonstration skipped.');
  print('Key: mixins = stackable behaviour; '
      'abstract class = partial impl + constructor; '
      'implements = structural contract.');
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoBasicMixin();
  demoOnConstraint();
  demoLinearization();
  demoSuperInMixin();
  demoNoConstructors();
  demoPracticalMixins();
  demoComparison();
}
