// extension_types.dart
// Dart 3.3+ extension types: zero-cost wrappers, typed IDs, units of measure,
// implements, and runtime erasure.
//
// Run with: dart run extension_types.dart

// ---------------------------------------------------------------------------
// 1. What are extension types?
// ---------------------------------------------------------------------------
//
// An extension type is a compile-time wrapper around another type.
// It creates a NEW STATIC TYPE with a distinct API surface, but at runtime
// it is COMPLETELY ERASED — no wrapper object is ever allocated.
// This is "zero-cost abstraction" in the most literal sense.
//
// Contrast with regular classes:
//   class Meters { final double value; Meters(this.value); }
//   // Every `Meters` object is a heap-allocated object with a header +
//   // a double field — 2× memory, extra GC pressure.
//
// With an extension type:
//   extension type Meters(double value) { }
//   // At runtime, a `Meters` IS a `double`. No wrapper object exists.

// ---------------------------------------------------------------------------
// 2. Basic syntax
// ---------------------------------------------------------------------------

extension type Meters(double value) {
  // The parameter `value` is the "representation field" — the sole field.
  // It is final by default; you cannot add additional instance fields.

  // You CAN add methods and getters:
  Meters operator +(Meters other) => Meters(value + other.value);
  Meters operator *(double factor) => Meters(value * factor);

  bool get isPositive => value > 0;

  @override
  String toString() => '${value}m';
}

extension type Kilograms(double value) {
  Kilograms operator +(Kilograms other) => Kilograms(value + other.value);

  @override
  String toString() => '${value}kg';
}

// The extension type system prevents mixing incompatible units at compile time:
// Meters m = Meters(1.0);
// Kilograms kg = m;  // compile error — distinct types despite same runtime rep

// ---------------------------------------------------------------------------
// 3. Extension types vs extension methods
// ---------------------------------------------------------------------------
//
// Extension METHODS (declared with `extension` keyword, not `extension type`):
//   - Add methods to an EXISTING type.
//   - Do NOT create a new type — the static type is unchanged.
//   - Cannot be used as a type annotation.
//   extension StringExt on String { bool get isPalindrome => ... }
//   String s = 'racecar';
//   s.isPalindrome; // OK, but s is still a `String` everywhere.
//
// Extension TYPES:
//   - Create a NEW static type.
//   - Can be used as type annotations, generics, function signatures.
//   - The compiler enforces the type boundary.
//   - At runtime, erased back to the representation type.

extension StringHelpers on String {
  // Extension METHOD — adds a method to String but does NOT create a new type.
  bool get isPalindrome {
    final cleaned = toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned == cleaned.split('').reversed.join();
  }
}

// Extension TYPE — a new type that wraps String:
extension type Email(String value) {
  // Constructor-level validation via a factory:
  Email.validate(String raw)
      : this(raw.contains('@') ? raw : (throw ArgumentError('Invalid email')));

  String get domain => value.split('@').last;
  String get localPart => value.split('@').first;

  @override
  String toString() => value;
}

// ---------------------------------------------------------------------------
// 4. `implements` in extension types — opting into the representation type
// ---------------------------------------------------------------------------
//
// By default, an extension type does NOT expose the representation type's
// members — it "hides" the underlying type. You must re-expose what you want.
//
// Adding `implements T` means:
//   1. The extension type IS a subtype of T statically.
//   2. All of T's members are visible directly on the extension type.
//   3. You can pass the extension type wherever T is expected.
//
// Use this when you WANT the underlying API plus your additions.
// Avoid it when the whole point is to RESTRICT the underlying API.

extension type SafeList<T>(List<T> _list) implements List<T> {
  // By implementing List<T>, all List methods are accessible.
  // This extension type adds nothing new — it just re-exports the list.
  // More useful: you can OVERRIDE specific methods to add invariants.

  // Example: override `add` to enforce a max size:
  // (extension types cannot override inherited methods from `implements` —
  //  but they CAN shadow them with new declarations)
  void addChecked(T item, {int maxSize = 100}) {
    if (_list.length >= maxSize) throw StateError('List is full');
    _list.add(item);
  }
}

// Extension type that implements its representation type's base:
extension type Celsius(double _degrees) implements double {
  // Because we `implements double`, Celsius IS a double statically.
  // All double arithmetic is available.
  double toFahrenheit() => _degrees * 9 / 5 + 32;

  @override
  String toString() => '${_degrees}°C';
}

// ---------------------------------------------------------------------------
// 5. Typed IDs — the killer use-case
// ---------------------------------------------------------------------------
//
// Problem: functions with multiple `int` parameters are error-prone:
//   void transfer(int fromAccount, int toAccount, int amount) { ... }
//   transfer(amount, toAccount, fromAccount); // oops — swapped arguments
//
// With extension types, every ID is its own static type:

extension type UserId(int value) {
  @override
  String toString() => 'user:$value';
}

extension type AccountId(int value) {
  @override
  String toString() => 'account:$value';
}

extension type Amount(int cents) {
  double get dollars => cents / 100;

  @override
  String toString() => '\$${dollars.toStringAsFixed(2)}';
}

// Now the function signature is self-documenting AND compiler-enforced:
void transfer(AccountId from, AccountId to, Amount amount) {
  print('Transfer $amount from $from to $to');
}

void typedIdDemo() {
  final alice = UserId(1001);
  final savings = AccountId(2001);
  final checking = AccountId(2002);
  final amount = Amount(5000); // \$50.00

  transfer(savings, checking, amount);

  // Compile error (uncomment to verify):
  // transfer(alice, checking, amount);  // UserId is not AccountId
  // transfer(savings, checking, alice); // UserId is not Amount
  // transfer(savings, 2002, amount);    // int is not AccountId

  print('User: $alice | Savings: $savings | Amount: $amount');
}

// ---------------------------------------------------------------------------
// 6. Validated wrappers
// ---------------------------------------------------------------------------
//
// Extension types can enforce invariants at construction time
// using named factory constructors with validation logic.

extension type PositiveInt(int _value) {
  // Named factory that validates:
  factory PositiveInt.checked(int n) {
    if (n <= 0) throw ArgumentError.value(n, 'n', 'must be positive');
    return PositiveInt(n);
  }

  PositiveInt operator +(PositiveInt other) =>
      PositiveInt(_value + other._value);

  int get value => _value;

  @override
  String toString() => 'PositiveInt($_value)';
}

extension type NonEmptyString(String _value) {
  factory NonEmptyString.checked(String s) {
    if (s.trim().isEmpty) throw ArgumentError('String must not be empty');
    return NonEmptyString(s);
  }

  String get trimmed => _value.trim();
  int get length => _value.length;

  @override
  String toString() => _value;
}

// ---------------------------------------------------------------------------
// 7. Runtime erasure demonstration
// ---------------------------------------------------------------------------
//
// At runtime, an extension type IS its representation type.
// `runtimeType` and `is` checks reveal the underlying type, not the extension type.

void erasureDemo() {
  final m = Meters(42.0);
  final d = 42.0;

  // Both have the same runtime type:
  print('Meters runtimeType: ${m.runtimeType}'); // double
  print('double runtimeType: ${d.runtimeType}'); // double

  // `is` checks see through the extension type:
  print('m is double: ${m is double}'); // true — erased to double
  // `m is Meters` is not a valid check — Meters doesn't exist at runtime.
  // (This is a compile error in Dart 3.3: extension types cannot be used
  //  in `is` expressions.)

  // Performance implication: no allocation ever happens for an extension type.
  // Creating 1,000,000 Meters values costs the same as creating 1,000,000 doubles.
}

// ---------------------------------------------------------------------------
// 8. Restrictions on extension types
// ---------------------------------------------------------------------------
//
// 1. Only ONE instance field — the representation field.
//    You cannot add: `extension type Foo(int x) { int y = 0; }` — compile error.
//
// 2. No mixin application directly (`with` is not supported).
//
// 3. Cannot be used in `is` type tests at runtime (they're erased).
//
// 4. Cannot extend other types (only `implements`).
//
// 5. Constructors other than the primary must use redirecting or factory forms.

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== Basic extension types ===');
  final distance = Meters(10.0);
  final doubled = distance * 2;
  final total = distance + doubled;
  print('distance=$distance doubled=$doubled total=$total');
  print('isPositive: ${total.isPositive}');

  print('\n=== Extension method vs extension type ===');
  const word = 'racecar';
  print('"$word" isPalindrome: ${word.isPalindrome}'); // extension method

  final email = Email.validate('alice@example.com');
  print('Email: $email domain=${email.domain} local=${email.localPart}');

  print('\n=== implements (Celsius) ===');
  const temp = Celsius(100.0);
  print('$temp = ${temp.toFahrenheit()}°F');
  // Because Celsius implements double, we can do arithmetic:
  final warmer = Celsius(temp + 20.0); // temp + 20.0 uses double's operator+
  print('Warmer: $warmer = ${warmer.toFahrenheit()}°F');

  print('\n=== Typed IDs ===');
  typedIdDemo();

  print('\n=== Validated wrappers ===');
  final pos = PositiveInt.checked(42);
  final pos2 = PositiveInt.checked(8);
  print('${pos} + ${pos2} = ${pos + pos2}');

  final str = NonEmptyString.checked('  hello  ');
  print('trimmed: "${str.trimmed}" length: ${str.length}');

  try {
    PositiveInt.checked(-1);
  } catch (e) {
    print('Caught: $e');
  }

  print('\n=== Runtime erasure ===');
  erasureDemo();

  print('\n=== SafeList ===');
  final list = SafeList<int>([1, 2, 3]);
  list.addChecked(4); // custom method
  list.add(5); // native List method via `implements`
  print('list=$list length=${list.length}');
}
