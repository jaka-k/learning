/// sealed.dart
///
/// Sealed classes, exhaustive pattern matching, and Result/Option types.
/// Requires Dart 3.0+.  Run with: dart run sealed.dart

// ---------------------------------------------------------------------------
// OVERVIEW: sealed CLASSES
// ---------------------------------------------------------------------------
// `sealed class` (Dart 3.0+) declares a *closed* class hierarchy:
//   • All direct subclasses must be declared in the SAME library (file).
//   • Outside the library, you can use the types but cannot add new subtypes.
//   • The compiler knows the complete set of subtypes, enabling exhaustive
//     switch expressions without a default clause.
//
// sealed vs abstract:
//   abstract — open hierarchy; anyone can subclass; switch needs default.
//   sealed   — closed hierarchy; switch can be exhaustive; no default needed.
//
// Note: sealed classes cannot be instantiated directly (like abstract classes).
// The subtypes can be: classes, other sealed classes, records, enums, mixins.

// ---------------------------------------------------------------------------
// 1. BASIC sealed CLASS — Shape hierarchy
// ---------------------------------------------------------------------------

sealed class Shape {
  const Shape();

  // A method on the sealed base is available on all subtypes.
  bool get hasVolume => false;
}

// All subtypes MUST be in this same file.
final class Circle extends Shape {
  final double radius;
  const Circle(this.radius);
}

final class Rectangle extends Shape {
  final double width, height;
  const Rectangle(this.width, this.height);
}

final class Triangle extends Shape {
  final double base, height;
  const Triangle(this.base, this.height);
}

// Helper: compute area via exhaustive switch (no default needed!).
// If we add a new subtype (e.g. Hexagon) and forget to handle it here,
// the compiler raises a warning — that's the whole point of sealed.
double area(Shape shape) => switch (shape) {
      Circle(:final radius)          => 3.14159 * radius * radius,
      Rectangle(:final width, :final height) => width * height,
      Triangle(:final base, :final height)   => 0.5 * base * height,
    };

String describe(Shape shape) => switch (shape) {
      Circle(radius: var r)      => 'Circle with radius $r',
      Rectangle(width: var w, height: var h) => 'Rectangle ${w}×$h',
      Triangle(base: var b, height: var h)   => 'Triangle base=$b h=$h',
    };

void demoBasicSealed() {
  print('\n--- 1. Basic sealed class ---');

  final shapes = [
    const Circle(5),
    const Rectangle(3, 4),
    const Triangle(6, 8),
  ];

  for (final s in shapes) {
    print('${describe(s)}  area=${area(s).toStringAsFixed(2)}');
  }
}

// ---------------------------------------------------------------------------
// 2. RESULT TYPE — sealed class for error handling without exceptions
// ---------------------------------------------------------------------------
// A common functional pattern: instead of throwing, return a Result<T> that
// is either a success (Ok<T>) or a failure (Err).
// The sealed hierarchy guarantees exhaustive handling at call sites.

sealed class Result<T> {
  const Result();

  // Convenience constructors — these are factory constructors on the sealed
  // base that return the appropriate subtype.
  factory Result.ok(T value) = Ok<T>;
  factory Result.err(String message, [Object? cause]) = Err<T>;

  // Monadic map: transform the value if Ok, propagate Err unchanged.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok(:final value)  => Ok(transform(value)),
        Err(:final message, :final cause) => Err(message, cause),
      };

  // Unwrap or provide a default.
  T getOrElse(T fallback) => switch (this) {
        Ok(:final value) => value,
        Err()            => fallback,
      };

  bool get isOk  => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
  @override String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  final String message;
  final Object? cause;
  const Err(this.message, [this.cause]);
  @override String toString() => 'Err($message)';
}

// Example function using Result instead of throwing.
Result<int> divide(int a, int b) {
  if (b == 0) return Result.err('division by zero');
  return Result.ok(a ~/ b);
}

Result<double> sqrt(double x) {
  if (x < 0) return Result.err('cannot take sqrt of negative');
  return Result.ok(x < 0 ? 0 : _sqrt(x));
}

// Simulate a sqrt calculation.
double _sqrt(double x) {
  double guess = x / 2;
  for (var i = 0; i < 20; i++) guess = (guess + x / guess) / 2;
  return guess;
}

void demoResultType() {
  print('\n--- 2. Result type ---');

  final r1 = divide(10, 2);
  final r2 = divide(10, 0);

  // Exhaustive switch — compiler confirms all cases are covered.
  for (final result in [r1, r2]) {
    final msg = switch (result) {
      Ok(:final value) => 'success: $value',
      Err(:final message) => 'failure: $message',
    };
    print(msg);
  }

  // Chaining with map.
  final chained = divide(100, 4).map((n) => n * 2);
  print('chained: $chained'); // Ok(50)

  // getOrElse.
  print(divide(7, 0).getOrElse(-1)); // -1
}

// ---------------------------------------------------------------------------
// 3. OPTION / MAYBE TYPE — alternative to nullable types
// ---------------------------------------------------------------------------
// Some codebases prefer an explicit Option<T> over T? for domain clarity.
// sealed makes the switch exhaustive.

sealed class Option<T> {
  const Option();

  // Named factory constructors return the appropriate subtype.
  factory Option.some(T value) = Some<T>;
  // Note: we cannot use `const factory Option.none() = None<T>` here because
  // generic redirecting const factories are not supported in Dart.
  // Instead we use a regular factory that returns a typed None<T>.
  factory Option.none() => None<T>();

  bool get isSome => this is Some<T>;
  bool get isNone => this is None<T>;

  T? get value => switch (this) {
        Some(:final value) => value,
        None()             => null,
      };

  Option<R> map<R>(R Function(T) f) => switch (this) {
        Some(:final value) => Some(f(value)),
        None()             => None<R>(),
      };

  Option<R> flatMap<R>(Option<R> Function(T) f) => switch (this) {
        Some(:final value) => f(value),
        None()             => None<R>(),
      };
}

final class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);
  @override String toString() => 'Some($value)';
}

final class None<T> extends Option<T> {
  const None();
  @override String toString() => 'None';
}

Option<String> findUser(int id) {
  final db = {1: 'Alice', 2: 'Bob'};
  final name = db[id];
  return name != null ? Some(name) : None<String>();
}

void demoOptionType() {
  print('\n--- 3. Option type ---');

  final user1 = findUser(1);
  final user3 = findUser(99);

  for (final opt in [user1, user3]) {
    print(switch (opt) {
      Some(:final value) => 'found: $value',
      None()             => 'not found',
    });
  }

  // Chaining.
  final upper = findUser(2).map((s) => s.toUpperCase());
  print('upper: $upper'); // Some(BOB)

  final flatMapped = findUser(1).flatMap(
    (name) => name.length > 3 ? Some(name.length) : None<int>(),
  );
  print('flatMapped: $flatMapped'); // Some(5) — "Alice" has 5 chars
}

// ---------------------------------------------------------------------------
// 4. SEALED + RECORDS COMBINATION
// ---------------------------------------------------------------------------
// Record subtypes give sealed classes compact, immutable value semantics
// without needing a separate class body.
//
// A record class is declared: class Foo(int x, String y) extends Sealed {}
// (Records are structural; sealed classes are nominal — combining them
//  gives both exhaustiveness and lightweight syntax.)

sealed class Event {
  const Event();
}

// Each event type uses a record-style final class for brevity.
final class UserLoggedIn extends Event {
  final String userId;
  final DateTime at;
  const UserLoggedIn(this.userId, this.at);
}

final class UserLoggedOut extends Event {
  final String userId;
  const UserLoggedOut(this.userId);
}

final class MessageSent extends Event {
  final String from, to, body;
  const MessageSent({required this.from, required this.to, required this.body});
}

final class ErrorOccurred extends Event {
  final String code;
  final String message;
  const ErrorOccurred(this.code, this.message);
}

String handleEvent(Event event) => switch (event) {
      UserLoggedIn(:final userId, :final at) =>
        'LOGIN $userId at $at',
      UserLoggedOut(:final userId) =>
        'LOGOUT $userId',
      MessageSent(:final from, :final to, :final body) =>
        'MSG $from→$to: "$body"',
      ErrorOccurred(:final code, :final message) =>
        'ERROR [$code] $message',
    };

void demoSealedRecords() {
  print('\n--- 4. Sealed + records ---');

  final events = <Event>[
    UserLoggedIn('alice', DateTime(2024, 1, 1, 9, 0)),
    MessageSent(from: 'alice', to: 'bob', body: 'hello'),
    ErrorOccurred('NET_001', 'timeout'),
    UserLoggedOut('alice'),
  ];

  for (final e in events) {
    print(handleEvent(e));
  }
}

// ---------------------------------------------------------------------------
// 5. GUARD CLAUSES (when) AND WILDCARD PATTERNS (_)
// ---------------------------------------------------------------------------
// Switch expressions support:
//   `when <condition>` — a guard that must be true for the arm to match.
//   `_`               — wildcard, matches anything (for the default case).
//
// Guard clauses let you add extra conditions on top of pattern matching
// without nesting or breaking exhaustiveness.

String classifyNumber(num n) => switch (n) {
      int i when i < 0   => 'negative int: $i',
      int i when i == 0  => 'zero',
      int i when i > 100 => 'large int: $i',
      int i              => 'small positive int: $i',
      double d when d.isNaN      => 'NaN',
      double d when d.isInfinite => 'infinity',
      double d when d < 0        => 'negative double',
      double d                   => 'double: $d',
    };

// Wildcard _ in object patterns: ignore fields you don't need.
String summariseShape(Shape s) => switch (s) {
      Circle(radius: double r) when r > 10 => 'large circle',
      Circle() => 'small circle',
      Rectangle(width: var w, height: var h) when w == h => 'square ${w}x$h',
      Rectangle() => 'rectangle',
      Triangle() => 'triangle',  // wildcard-like: ignore fields entirely
    };

void demoGuardsAndWildcards() {
  print('\n--- 5. Guard clauses (when) and wildcards ---');

  for (final n in [-5, 0, 50, 200, 3.14, double.nan, double.infinity]) {
    print(classifyNumber(n));
  }

  print('');
  for (final s in [
    const Circle(15),
    const Circle(3),
    const Rectangle(4, 4),
    const Rectangle(3, 5),
    const Triangle(2, 6),
  ]) {
    print(summariseShape(s));
  }
}

// ---------------------------------------------------------------------------
// 6. NESTED SEALED HIERARCHIES
// ---------------------------------------------------------------------------
// Sealed classes can contain other sealed classes, forming a tree.
// The switch must be exhaustive at each level.

sealed class AppState {}

sealed class AuthState extends AppState {}
final class Unauthenticated extends AuthState {}
final class Authenticated extends AuthState {
  final String userId;
  Authenticated(this.userId);
}
final class AuthLoading extends AuthState {}

sealed class ContentState extends AppState {}
final class Loading extends ContentState {}
final class Loaded extends ContentState {
  final List<String> items;
  Loaded(this.items);
}
final class ContentError extends ContentState {
  final String message;
  ContentError(this.message);
}

// Two-level exhaustive switch.
String renderState(AppState state) => switch (state) {
      // AuthState branch
      Unauthenticated() => 'Please log in',
      AuthLoading()     => 'Authenticating...',
      Authenticated(:final userId) => 'Hello, $userId',
      // ContentState branch
      Loading()         => 'Loading content...',
      Loaded(:final items) => 'Loaded ${items.length} items',
      ContentError(:final message) => 'Error: $message',
    };

void demoNestedSealed() {
  print('\n--- 6. Nested sealed hierarchies ---');

  final states = <AppState>[
    Unauthenticated(),
    AuthLoading(),
    Authenticated('alice'),
    Loading(),
    Loaded(['post1', 'post2', 'post3']),
    ContentError('network timeout'),
  ];

  for (final s in states) {
    print(renderState(s));
  }
}

// ---------------------------------------------------------------------------
// 7. sealed vs abstract — exhaustiveness in practice
// ---------------------------------------------------------------------------
// With abstract: switch needs default (compiler can't know all subtypes).
// With sealed:   switch can be exhaustive (compiler knows all subtypes).

abstract class AbstractColor {
  const AbstractColor();
}

sealed class SealedColor {
  const SealedColor();
}

class SealedRed   extends SealedColor { const SealedRed(); }
class SealedGreen extends SealedColor { const SealedGreen(); }
class SealedBlue  extends SealedColor { const SealedBlue(); }

// With sealed, this switch is exhaustive — no default needed.
String nameOf(SealedColor c) => switch (c) {
      SealedRed()   => 'red',
      SealedGreen() => 'green',
      SealedBlue()  => 'blue',
    };

void demoExhaustiveness() {
  print('\n--- 7. Exhaustiveness: sealed vs abstract ---');

  for (final c in [const SealedRed(), const SealedGreen(), const SealedBlue()]) {
    print(nameOf(c));
  }

  print('Compiler enforces exhaustiveness for sealed — '
        'add a new subtype and the switch becomes a compile error.');
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoBasicSealed();
  demoResultType();
  demoOptionType();
  demoSealedRecords();
  demoGuardsAndWildcards();
  demoNestedSealed();
  demoExhaustiveness();
}
