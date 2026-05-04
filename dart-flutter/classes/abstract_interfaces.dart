/// abstract_interfaces.dart
///
/// Abstract classes, interfaces, and Dart 3 class modifiers.
/// Run with: dart run abstract_interfaces.dart

// ---------------------------------------------------------------------------
// OVERVIEW: EXTENDS vs IMPLEMENTS vs WITH
// ---------------------------------------------------------------------------
//
//  extends  — single inheritance; inherits implementation; `super` available.
//  implements — structural conformance; ALL members must be re-implemented;
//               no `super`; a class can implement multiple types.
//  with     — mixin composition; inherits implementation from mixins;
//               stackable; mixins cannot have constructors.
//
// Key rule: A Dart class implicitly defines an *interface* consisting of all
// its public members.  Any other class can `implements` it without extending.

// ---------------------------------------------------------------------------
// 1. ABSTRACT CLASS AS INTERFACE (pre-Dart 3 / still valid)
// ---------------------------------------------------------------------------
// Before Dart 3, the convention was to use an abstract class as an interface.
// An abstract class can have:
//   • Abstract methods (declared, no body)
//   • Concrete methods (with body — default implementations)
//   • Abstract getters / setters
//   • Constructors (unlike mixins)

abstract class Serializable {
  // Abstract method — subclass MUST implement.
  Map<String, dynamic> toJson();

  // Abstract getter.
  String get typeName;

  // Concrete method with default implementation that subclasses can override.
  String serialize() => toJson().entries
      .map((e) => '${e.key}: ${e.value}')
      .join(', ');
}

abstract class Identifiable {
  int get id;
  bool sameAs(Identifiable other) => id == other.id;
}

// A class can implement multiple abstract interfaces.
class Product implements Serializable, Identifiable {
  @override final int id;
  final String name;
  final double price;

  Product(this.id, this.name, this.price);

  // Must re-implement ALL members of both interfaces.
  @override Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'price': price};

  @override String get typeName => 'Product';
}

void demoAbstractAsInterface() {
  print('\n--- 1. Abstract class as interface ---');

  final p = Product(1, 'Widget', 9.99);
  print(p.typeName);    // Product
  print(p.serialize()); // id: 1, name: Widget, price: 9.99
  print(p.sameAs(Product(1, 'Other', 0))); // true
}

// ---------------------------------------------------------------------------
// 2. IMPLICIT INTERFACE
// ---------------------------------------------------------------------------
// Every class (including concrete ones) defines an implicit interface.
// You can `implements` ANY class, not just abstract ones.
// When you do, you must re-implement ALL public members — no inheritance.

class EmailSender {
  final String host;
  EmailSender(this.host);

  void send(String to, String body) {
    print('[$host] → $to: $body');
  }
}

// MockEmailSender implements EmailSender's interface but has its own body.
// No relationship to EmailSender at runtime — just structural conformance.
class MockEmailSender implements EmailSender {
  final sent = <String>[];

  // `host` and `send` must both be implemented — there is no inherited body.
  @override String get host => 'mock';

  @override
  void send(String to, String body) {
    sent.add('$to:$body');
    print('[MOCK] captured: $to');
  }
}

void demoImplicitInterface() {
  print('\n--- 2. Implicit interface ---');

  EmailSender sender = MockEmailSender();
  sender.send('a@b.com', 'Hello');

  final mock = sender as MockEmailSender;
  print('captured: ${mock.sent}');
}

// ---------------------------------------------------------------------------
// 3. ABSTRACT METHODS AND ABSTRACT GETTERS
// ---------------------------------------------------------------------------
abstract class Animal {
  // Abstract getter — no body.
  String get sound;
  String get name;

  // Abstract method.
  void move();

  // Concrete method using abstract members.
  void describe() => print('$name says "$sound" and can move.');
}

class Dog extends Animal {
  @override String get sound => 'woof';
  @override String get name => 'Dog';
  @override void move() => print('Dog runs');
}

class Bird extends Animal {
  @override String get sound => 'tweet';
  @override String get name => 'Bird';
  @override void move() => print('Bird flies');
}

void demoAbstractMembers() {
  print('\n--- 3. Abstract methods & getters ---');

  final animals = <Animal>[Dog(), Bird()];
  for (final a in animals) {
    a.describe();
    a.move();
  }
}

// ---------------------------------------------------------------------------
// 4. DART 3 CLASS MODIFIERS
// ---------------------------------------------------------------------------
// Dart 3.0 introduced explicit class modifiers that encode the *intended*
// usage of a class, enforced by the compiler.
//
// ┌──────────────────┬──────────┬───────────┬──────────┐
// │ Modifier         │ extend   │ implement │ mix-in   │
// ├──────────────────┼──────────┼───────────┼──────────┤
// │ (none)           │ yes      │ yes       │ no *     │
// │ abstract         │ yes      │ yes       │ no       │
// │ interface class  │ no **    │ yes       │ no       │
// │ base class       │ yes      │ no        │ no       │
// │ final class      │ no       │ no        │ no       │
// │ sealed class     │ no       │ no        │ no       │
// │ mixin class      │ yes      │ yes       │ yes      │
// └──────────────────┴──────────┴───────────┴──────────┘
// * A plain class cannot be used as a mixin unless declared `mixin class`.
// ** interface class: CAN be extended inside the same library only.

// --- interface class ---
// Can be implemented (used as a pure interface) but NOT extended outside
// the defining library.  Prevents callers from inheriting implementation
// details they shouldn't depend on.

interface class DataSource {
  // Declares an interface without allowing inheritance of implementation.
  List<Map<String, dynamic>> fetchAll() => []; // default impl
  Map<String, dynamic>? fetchById(int id) => null;
}

class SqlDataSource implements DataSource {
  @override
  List<Map<String, dynamic>> fetchAll() => [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ];

  @override
  Map<String, dynamic>? fetchById(int id) =>
      fetchAll().where((r) => r['id'] == id).firstOrNull;
}

// --- base class ---
// Can be extended (subclassed) but NOT implemented.
// Forces users to call `super` for any overrides, preserving invariants.

base class Entity {
  final int id;
  final DateTime createdAt;

  Entity(this.id) : createdAt = DateTime.now();

  // Because `base` prevents `implements`, subclasses MUST call super
  // constructor, ensuring `id` and `createdAt` are always initialised.
  @override
  String toString() => '${runtimeType}(id=$id)';
}

// Cannot `implements Entity` — base class.
// class FakeEntity implements Entity { ... } // compile error

final class Order extends Entity {
  final String product;
  Order(super.id, this.product);

  @override String toString() => 'Order(id=$id, product=$product)';
}

// --- final class ---
// Cannot be extended OR implemented outside the library.
// Locks down the class completely — useful for value objects and DTOs.

final class Money {
  final int cents;
  final String currency;

  const Money(this.cents, this.currency);
  const Money.zero(this.currency) : cents = 0;

  Money operator +(Money other) {
    assert(currency == other.currency, 'currency mismatch');
    return Money(cents + other.cents, currency);
  }

  @override String toString() =>
      '${(cents / 100).toStringAsFixed(2)} $currency';
}

// --- mixin class ---
// Can be used both as a standalone class (instantiated/extended) AND as a
// mixin (with).  Must satisfy both constraints: no `on` clause, no
// generative constructors with parameters.

mixin class JsonSerializable {
  Map<String, dynamic> toJson() => {};

  String toJsonString() {
    final map = toJson();
    return '{${map.entries.map((e) => '"${e.key}":"${e.value}"').join(',')}}';
  }
}

// Used as a mixin.
class Config with JsonSerializable {
  final String env;
  Config(this.env);

  @override Map<String, dynamic> toJson() => {'env': env};
}

// Used as a base class.
class BaseModel extends JsonSerializable {
  final int id;
  BaseModel(this.id);

  @override Map<String, dynamic> toJson() => {'id': id};
}

void demoDart3Modifiers() {
  print('\n--- 4. Dart 3 class modifiers ---');

  // interface class
  final DataSource ds = SqlDataSource();
  print('fetchAll: ${ds.fetchAll()}');
  print('fetchById(1): ${ds.fetchById(1)}');

  // base class / final class
  final order = Order(42, 'Widget');
  print(order); // Order(id=42, product=Widget)

  final price = Money(999, 'USD');
  final tax   = Money(80, 'USD');
  print('total: ${price + tax}'); // 10.79 USD

  // mixin class
  final config = Config('production');
  print(config.toJsonString()); // {"env":"production"}

  final model = BaseModel(1);
  print(model.toJsonString()); // {"id":"1"}
}

// ---------------------------------------------------------------------------
// 5. IMPLEMENTING MULTIPLE INTERFACES
// ---------------------------------------------------------------------------
// A class can implement any number of types (abstract classes, interface
// classes, or any plain class via its implicit interface).

abstract class Flyable {
  void fly();
  String get maxAltitude;
}

abstract class Swimmable {
  void swim();
}

abstract class Walkable {
  void walk();
}

class Penguin implements Swimmable, Walkable {
  @override void swim() => print('Penguin swims');
  @override void walk() => print('Penguin waddles');
}

class Seagull implements Flyable, Swimmable, Walkable {
  @override void fly()  => print('Seagull soars');
  @override void swim() => print('Seagull paddles');
  @override void walk() => print('Seagull struts');
  @override String get maxAltitude => '3000m';
}

void demoMultipleInterfaces() {
  print('\n--- 5. Implementing multiple interfaces ---');

  final penguin = Penguin();
  penguin.swim();
  penguin.walk();

  // Can assign to any of the interfaces it implements.
  Swimmable swimmer = Seagull();
  swimmer.swim(); // Seagull paddles

  Flyable flyer = Seagull();
  print('max alt: ${flyer.maxAltitude}');
}

// ---------------------------------------------------------------------------
// 6. extends vs implements vs with — SIDE BY SIDE
// ---------------------------------------------------------------------------

class Logger {
  void log(String msg) => print('[LOG] $msg');
}

mixin Timestamps {
  DateTime get now => DateTime.now();
}

abstract class BaseService {
  String get serviceName;
  void start();
}

// Extends Logger → inherits `log` implementation; super available.
// Implements BaseService → must implement all members.
// With Timestamps → inherits `now`; no super chain needed.
class UserService extends Logger implements BaseService with Timestamps {
  @override String get serviceName => 'UserService';
  @override void start() {
    log('$serviceName started at $now');
  }
}

void demoThreeWays() {
  print('\n--- 6. extends vs implements vs with ---');

  final svc = UserService();
  svc.start();
  svc.log('custom message');

  // Type checks.
  print(svc is Logger);      // true — extends
  print(svc is BaseService); // true — implements
  // `is Timestamps` is true too but Timestamps is a mixin, no issue.
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoAbstractAsInterface();
  demoImplicitInterface();
  demoAbstractMembers();
  demoDart3Modifiers();
  demoMultipleInterfaces();
  demoThreeWays();
}
