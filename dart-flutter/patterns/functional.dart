// functional.dart
// Functional patterns in Dart: copyWith, function composition, currying,
// Option/Either monads (sealed classes), memoization, trampolining.

// ---------------------------------------------------------------------------
// 1. Immutability: the copyWith pattern
// ---------------------------------------------------------------------------
//
// Dart classes are mutable by default. The `copyWith` pattern allows
// "updating" an immutable object by returning a new instance with select
// fields changed — the rest are copied from the original.
//
// This is the canonical approach used by Flutter's ThemeData, TextStyle, etc.
// Libraries like `freezed` generate this automatically.

class UserSettings {
  final String theme;
  final bool notifications;
  final int fontSize;

  const UserSettings({
    this.theme = 'light',
    this.notifications = true,
    this.fontSize = 14,
  });

  // `copyWith` uses nullable parameters where null means "keep original value".
  // This is a limitation: you can't explicitly set a field to null.
  // The freezed library works around this with sentinel objects.
  UserSettings copyWith({
    String? theme,
    bool? notifications,
    int? fontSize,
  }) =>
      UserSettings(
        theme: theme ?? this.theme,
        notifications: notifications ?? this.notifications,
        fontSize: fontSize ?? this.fontSize,
      );

  @override
  String toString() =>
      'UserSettings(theme=$theme, notifs=$notifications, size=$fontSize)';
}

// ---------------------------------------------------------------------------
// 2. Function composition
// ---------------------------------------------------------------------------
//
// Dart has no built-in `|>` pipeline operator or `compose` function.
// Implement them manually:

// compose(f, g)(x) == f(g(x)) — right-to-left composition
T Function(A) compose<A, B, T>(T Function(B) f, B Function(A) g) =>
    (A x) => f(g(x));

// pipe(f, g)(x) == g(f(x)) — left-to-right (pipeline style)
T Function(A) pipe<A, B, T>(B Function(A) f, T Function(B) g) =>
    (A x) => g(f(x));

// For more stages: compose three functions.
T Function(A) compose3<A, B, C, T>(
  T Function(C) f,
  C Function(B) g,
  B Function(A) h,
) =>
    (A x) => f(g(h(x)));

// Variadic compose via a list (loses type safety but handy for demo):
dynamic Function(dynamic) composeAll(List<Function> fns) =>
    fns.reversed.reduce((acc, fn) => (x) => acc(fn(x)));

// ---------------------------------------------------------------------------
// 3. Partial application and currying
// ---------------------------------------------------------------------------
//
// Currying: transform f(a, b) into f(a)(b).
// Partial application: fix some arguments, return a function for the rest.

// Manual curried function:
int Function(int) adder(int a) => (int b) => a + b;
int Function(int) multiplier(int factor) => (int x) => x * factor;

// Generic curry for 2-argument functions:
B Function(A2) Function(A1) curry2<A1, A2, B>(B Function(A1, A2) f) =>
    (A1 a) => (A2 b) => f(a, b);

// Partial application (fix the first argument of a 2-arg function):
T Function(B) partial<A, B, T>(T Function(A, B) f, A a) => (B b) => f(a, b);

// Partial application for 3-arg functions (fix the first two arguments):
// partial3(f, a, b) returns a 1-arg function where first two args are fixed.
T Function(C) partial3<A, B, C, T>(T Function(A, B, C) f, A a, B b) =>
    (C c) => f(a, b, c);

// Example: a general range-validator, partially applied per field:
// inRange(min, max, value) — fix min and max to get a single-arg predicate.
bool inRange(int min, int max, int value) => value >= min && value <= max;

// partial3 fixes both min and max, leaving only `value` to be supplied:
final isValidAge = partial3(inRange, 0, 130);
final isValidPort = partial3(inRange, 1, 65535);

// ---------------------------------------------------------------------------
// 4. Option / Maybe monad — sealed class implementation
// ---------------------------------------------------------------------------
//
// Option<T> represents a value that may or may not exist.
// It eliminates null and forces callers to handle the absent case explicitly.
//
// sealed class ensures exhaustive pattern matching — the compiler enforces
// that both Some and None are handled everywhere you switch on an Option.

sealed class Option<T> {
  const Option();

  // Factory constructors for ergonomics:
  const factory Option.some(T value) = Some<T>;
  const factory Option.none() = None<T>;

  static Option<T> fromNullable<T>(T? value) =>
      value == null ? None<T>() : Some<T>(value);

  // Functor: apply a function if present.
  Option<R> map<R>(R Function(T) f) => switch (this) {
        Some(:var value) => Some(f(value)),
        None() => None<R>(),
      };

  // Monad (flatMap / bind): chain operations that may also return Option.
  Option<R> flatMap<R>(Option<R> Function(T) f) => switch (this) {
        Some(:var value) => f(value),
        None() => None<R>(),
      };

  // Fold: extract the value by handling both cases.
  R fold<R>({required R Function(T) some, required R orElse}) => switch (this) {
        Some(:var value) => some(value),
        None() => orElse,
      };

  T getOrElse(T defaultValue) => switch (this) {
        Some(:var value) => value,
        None() => defaultValue,
      };

  bool get isSome => this is Some<T>;
  bool get isNone => this is None<T>;
}

final class Some<T> extends Option<T> {
  final T value;
  const Some(this.value);

  @override
  String toString() => 'Some($value)';
}

final class None<T> extends Option<T> {
  const None();

  @override
  String toString() => 'None';
}

// Usage example — parsing and transforming:
Option<int> parseInt(String s) {
  final n = int.tryParse(s);
  return Option.fromNullable(n);
}

Option<double> safeDivide(int numerator, int denominator) =>
    denominator == 0 ? const None() : Some(numerator / denominator);

// ---------------------------------------------------------------------------
// 5. Either monad — typed error handling without exceptions
// ---------------------------------------------------------------------------
//
// Either<L, R> represents a value that is either a Left (error/failure)
// or a Right (success). By convention: Left = error, Right = value.
//
// Unlike exceptions, the type system forces callers to acknowledge errors.

sealed class Either<L, R> {
  const Either();

  const factory Either.left(L value) = Left<L, R>;
  const factory Either.right(R value) = Right<L, R>;

  Either<L, R2> map<R2>(R2 Function(R) f) => switch (this) {
        Right(:var value) => Right(f(value)),
        Left(:var value) => Left(value),
      };

  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R) f) => switch (this) {
        Right(:var value) => f(value),
        Left(:var value) => Left(value),
      };

  Either<L2, R> mapLeft<L2>(L2 Function(L) f) => switch (this) {
        Left(:var value) => Left(f(value)),
        Right(:var value) => Right(value),
      };

  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => switch (this) {
        Left(:var value) => onLeft(value),
        Right(:var value) => onRight(value),
      };

  bool get isRight => this is Right<L, R>;
  bool get isLeft => this is Left<L, R>;
}

final class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  String toString() => 'Left($value)';
}

final class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  String toString() => 'Right($value)';
}

// Domain example: parsing and validation pipeline.
sealed class AppError {
  const AppError();
}

class ParseError extends AppError {
  final String input;
  const ParseError(this.input);

  @override
  String toString() => 'ParseError("$input")';
}

class ValidationError extends AppError {
  final String message;
  const ValidationError(this.message);

  @override
  String toString() => 'ValidationError($message)';
}

Either<AppError, int> parseAge(String s) {
  final n = int.tryParse(s);
  if (n == null) return Left(ParseError(s));
  return Right(n);
}

Either<AppError, int> validateAge(int age) {
  if (age < 0 || age > 150) return Left(ValidationError('age $age out of range'));
  return Right(age);
}

// Chain without nesting:
Either<AppError, int> processAge(String raw) =>
    parseAge(raw).flatMap(validateAge);

// ---------------------------------------------------------------------------
// 6. Memoization
// ---------------------------------------------------------------------------
//
// Cache the result of a pure function (same input → always same output).
// Useful for expensive computations called repeatedly with the same args.

// Generic memoize for single-argument functions:
R Function(A) memoize<A, R>(R Function(A) fn) {
  final cache = <A, R>{};
  return (A arg) => cache.putIfAbsent(arg, () => fn(arg));
}

// For multi-argument functions, use a record as the key (Dart 3.0+):
R Function(A, B) memoize2<A, B, R>(R Function(A, B) fn) {
  final cache = <(A, B), R>{};
  return (A a, B b) => cache.putIfAbsent((a, b), () => fn(a, b));
}

// Example: expensive Fibonacci (exponential without memoization):
late final int Function(int) fibonacci;
void _initFib() {
  // Self-referential memoized recursion:
  fibonacci = memoize((int n) => n <= 1 ? n : fibonacci(n - 1) + fibonacci(n - 2));
}

// ---------------------------------------------------------------------------
// 7. Trampolining — stack-safe recursion
// ---------------------------------------------------------------------------
//
// Deep recursion in Dart overflows the call stack.
// Trampolining converts recursion into iteration:
//   Instead of calling the next step, return a thunk (closure).
//   The trampoline loop calls thunks until a final value is produced.

// Thunk represents either a final value or "call me to continue":
sealed class Bounce<T> {
  const Bounce();
}

class Done<T> extends Bounce<T> {
  final T value;
  const Done(this.value);
}

class Thunk<T> extends Bounce<T> {
  final Bounce<T> Function() next;
  const Thunk(this.next);
}

// The trampoline runner — iterative, not recursive:
T trampoline<T>(Bounce<T> initial) {
  var current = initial;
  while (current is Thunk<T>) {
    current = (current as Thunk<T>).next();
  }
  return (current as Done<T>).value;
}

// Stack-safe factorial using trampolining:
Bounce<BigInt> _factStep(int n, BigInt acc) =>
    n <= 1 ? Done(acc) : Thunk(() => _factStep(n - 1, acc * BigInt.from(n)));

BigInt factorial(int n) => trampoline(_factStep(n, BigInt.one));

// Stack-safe even/odd check (mutual recursion):
Bounce<bool> _isEven(int n) =>
    n == 0 ? const Done(true) : Thunk(() => _isOdd(n - 1));

Bounce<bool> _isOdd(int n) =>
    n == 0 ? const Done(false) : Thunk(() => _isEven(n - 1));

bool stackSafeIsEven(int n) => trampoline(_isEven(n));

// ---------------------------------------------------------------------------
// 8. Point-free style
// ---------------------------------------------------------------------------
//
// Point-free: define functions by composing other functions without mentioning
// the arguments. In Dart this works but is verbose due to static typing.

bool isPositive(int n) => n > 0;
int negate(int n) => -n;
String stringify(int n) => 'value: $n';

// Compose into a pipeline without ever naming the argument:
final negateAndStringify = pipe<int, int, String>(negate, stringify);
final positiveAndStringify = pipe<int, String, String>(
  (n) => n.isEven ? n.toString() : (throw ArgumentError('odd')),
  (s) => 'even: $s',
);

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== copyWith ===');
  const defaults = UserSettings();
  final darkMode = defaults.copyWith(theme: 'dark');
  final bigFont = darkMode.copyWith(fontSize: 20, notifications: false);
  print(defaults);
  print(darkMode);
  print(bigFont);

  print('\n=== Function composition ===');
  final double2andStringify =
      compose3<int, int, int, String>(stringify, negate, (n) => n * 2);
  print(double2andStringify(5)); // value: -10

  final pipeline = pipe<String, int, String>(
    (s) => int.parse(s),
    (n) => 'parsed: $n',
  );
  print(pipeline('42'));

  print('\n=== Currying + partial application ===');
  final add5 = adder(5);
  final triple = multiplier(3);
  print([1, 2, 3, 4].map(add5).toList()); // [6, 7, 8, 9]
  print([1, 2, 3, 4].map(triple).toList()); // [3, 6, 9, 12]

  final curriedAdd = curry2<int, int, int>((a, b) => a + b);
  print(curriedAdd(3)(4)); // 7

  print('age 25 valid: ${isValidAge(25)}');
  print('age 200 valid: ${isValidAge(200)}');
  print('port 8080 valid: ${isValidPort(8080)}');
  print('port 99999 valid: ${isValidPort(99999)}');

  print('\n=== Option monad ===');
  final result = parseInt('42')
      .flatMap((n) => safeDivide(100, n))
      .map((d) => d.toStringAsFixed(2));
  print(result); // Some(2.38)

  final failed = parseInt('abc')
      .flatMap((n) => safeDivide(100, n))
      .map((d) => d.toStringAsFixed(2));
  print(failed); // None

  final divByZero = parseInt('0')
      .flatMap((n) => safeDivide(100, n));
  print(divByZero); // None

  print('default: ${failed.getOrElse('0.00')}');

  print('\n=== Either monad ===');
  for (final raw in ['25', '200', 'abc', '-1']) {
    final r = processAge(raw);
    print('processAge("$raw") = $r');
    print('  => ${r.fold((e) => "ERROR: $e", (v) => "OK: $v")}');
  }

  print('\n=== Memoization ===');
  _initFib();
  final sw = Stopwatch()..start();
  print('fib(40) = ${fibonacci(40)}'); // fast because memoized
  sw.stop();
  print('took ${sw.elapsedMicroseconds}µs');

  final memoizedStrLen = memoize2<String, int, int>(
    (s, radix) => int.parse(s, radix: radix),
  );
  print(memoizedStrLen('ff', 16)); // 255
  print(memoizedStrLen('1010', 2)); // 10

  print('\n=== Trampolining ===');
  print('10! = ${factorial(10)}');
  print('20! = ${factorial(20)}');
  // Safe on deep recursion that would normally overflow:
  print('isEven(10000) = ${stackSafeIsEven(10000)}');
  print('isEven(9999) = ${stackSafeIsEven(9999)}');

  print('\n=== Point-free ===');
  print(negateAndStringify(7)); // value: -7
  for (final n in [2, 4, 6]) {
    print(positiveAndStringify(n));
  }
}
