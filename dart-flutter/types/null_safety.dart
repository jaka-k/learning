// null_safety.dart
// Advanced Dart null safety: operators, late, flow analysis, generics, required.
//
// Dart's null safety (sound null safety since Dart 2.12) is a compile-time
// guarantee: non-nullable types can NEVER hold null at runtime. The type system
// is "sound" — if the compiler accepts it, it truly cannot be null.

// ---------------------------------------------------------------------------
// 1. The type distinction: String vs String? vs dynamic
// ---------------------------------------------------------------------------
//
// String   — non-nullable: compiler proves it is never null.
// String?  — nullable:     union of String and Null.
// dynamic  — opt-out:      compiler performs no static null checks at all.
//            At runtime a dynamic value can be anything, including null.
//            Using dynamic is like writing untyped code — you lose all
//            compile-time safety, including null safety.

String nonNullable = 'hello'; // can never be null
String? nullable = null; // fine — this is exactly what ? means
// dynamic dyn = null;           // also fine, but NO static checks ever apply

// ---------------------------------------------------------------------------
// 2. Null-aware operators
// ---------------------------------------------------------------------------

String demonstrateNullAwareOps() {
  String? name = null;

  // ?. — null-safe member access
  // Evaluates to null if the receiver is null instead of throwing.
  int? length = name?.length; // length == null (no NPE)

  // The entire chain short-circuits on the first null:
  //   name?.toUpperCase()?.substring(0, 1)
  // Each ?. stops the chain and returns null if its receiver is null.

  // ?? — null-coalescing (if-null) operator
  // Returns the left side if it is non-null, otherwise the right side.
  String display = name ?? 'Anonymous'; // 'Anonymous'

  // Chaining ?? is right-associative:
  String? a, b;
  String c = 'fallback';
  String result = a ?? b ?? c; // walks the chain until non-null

  // ??= — null-coalescing assignment
  // Only assigns if the variable is currently null. Combines a null check
  // and an assignment into one expression.
  String? cache;
  cache ??= 'computed value'; // assigns because cache == null
  cache ??= 'second call'; // does NOT assign — cache is already non-null

  // ! — null assertion operator
  // Tells the compiler "I know this is non-null; trust me."
  // Throws Null check operator used on a null value at RUNTIME if wrong.
  // Use only when you have out-of-band knowledge the compiler cannot see.
  String? fromDatabase = 'exists';
  String definite = fromDatabase!; // OK at runtime here

  // Danger: the following compiles but crashes at runtime:
  // String? boom = null;
  // String bad = boom!; // throws: Null check operator used on a null value

  return '$display | $result | $cache | $definite | len=$length';
}

// ---------------------------------------------------------------------------
// 3. Flow analysis / type promotion
// ---------------------------------------------------------------------------
//
// The Dart compiler performs control-flow analysis. Inside a branch where a
// variable is proven non-null, the type is automatically "promoted" from T?
// to T — no cast needed.

void flowAnalysis() {
  String? maybeString = possiblyNull();

  // After a null check the type is promoted to String (non-nullable).
  if (maybeString != null) {
    // Inside here, maybeString is String (not String?).
    print(maybeString.length); // no ! needed
    print(maybeString.toUpperCase());
  }

  // Promotion also works with early returns (the "guard" pattern):
  if (maybeString == null) return; // if null, bail out early
  // From here to the end of the function, maybeString is String.
  print(maybeString.length); // no ! needed

  // LIMITATION: promotion does NOT apply to fields / getters because another
  // thread or getter call could change them between the check and the use.
  // Local variables (and parameters) are promotable; fields are not.
  // Workaround: copy the field to a local variable first.
  //   final local = someObject.nullableField;
  //   if (local != null) { /* local is promoted here */ }
}

String? possiblyNull() => DateTime.now().second.isEven ? 'value' : null;

// ---------------------------------------------------------------------------
// 4. The `late` keyword
// ---------------------------------------------------------------------------
//
// `late` defers the null-safety guarantee to runtime:
//   - The variable is non-nullable (type has no ?)
//   - But initialization is deferred — the compiler trusts you to assign
//     before first read.
//   - If you read it before assigning: LateInitializationError (runtime).

late String lateVar; // declared but not yet initialised

void demonstrateLate() {
  // lateVar here would throw LateInitializationError — DO NOT read yet.
  lateVar = 'initialized now';
  print(lateVar); // safe
}

// Typical use-case: class fields initialised in setUp() / initState() rather
// than the constructor, common in Flutter widget tests.
class DatabaseService {
  late final connection = _openConnection(); // lazy: runs on first access
  // `late final` is the lazy-singleton pattern:
  //   - computed once on first access
  //   - cached forever after (final = assigned only once)
  //   - referencing `this` is fine (unlike initializer lists)

  String _openConnection() {
    print('  [DB] Opening connection (once)');
    return 'conn://localhost:5432';
  }
}

// ---------------------------------------------------------------------------
// 5. `late final` as a lazy singleton pattern
// ---------------------------------------------------------------------------
//
// A top-level or static `late final` is the canonical Dart lazy singleton:
//   - Not computed until first access (lazy)
//   - Computed only once (final)
//   - Zero boilerplate compared to factory constructors + _instance fields

class AppConfig {
  // This is evaluated the first time AppConfig.instance is accessed.
  static final AppConfig instance = AppConfig._(); // eager (fine for small objs)

  // For truly lazy (only if used):
  static late final AppConfig lazyInstance = AppConfig._();

  const AppConfig._();

  final String env = 'production';
}

// ---------------------------------------------------------------------------
// 6. Nullable generics
// ---------------------------------------------------------------------------
//
// The ? modifier composes with generic type parameters.
// List<String?> means a list that CAN contain null elements.
// List<String>? means the list reference itself can be null, but elements cannot.

void nullableGenerics() {
  // List whose elements can be null.
  List<String?> sparse = ['a', null, 'c', null, 'e'];
  // Need to handle null when iterating:
  for (final s in sparse) {
    print(s?.toUpperCase() ?? '(missing)');
  }

  // The list itself may be null (but if non-null, its elements cannot be):
  List<String>? maybeList;
  int count = maybeList?.length ?? 0; // safe access via ?.

  // Nullable type parameter in a generic class:
  Box<String?> boxedNull = Box(null); // valid — String? includes null
  Box<String> boxedStr = Box('hello'); // valid — String excludes null
  print('$count | ${boxedNull.value} | ${boxedStr.value}');
}

class Box<T> {
  final T value;
  const Box(this.value);
}

// ---------------------------------------------------------------------------
// 7. `required` named parameters
// ---------------------------------------------------------------------------
//
// Named parameters are optional by default. `required` makes the compiler
// enforce that callers always supply a value — no default fallback.
// This is how Flutter widgets enforce mandatory props.

class UserProfile {
  final String name;
  final int age;
  final String? bio; // optional — callers may omit

  // `required` named params: callers MUST supply name and age.
  const UserProfile({
    required this.name,
    required this.age,
    this.bio, // nullable + no `required` = truly optional
  });
}

// Compare with a `required` param that is also non-nullable:
//   required String name  — must be provided AND must not be null
// vs a nullable required param (rare but valid):
//   required String? name — must be provided BUT may be null explicitly

// ---------------------------------------------------------------------------
// 8. String? vs dynamic — the critical difference
// ---------------------------------------------------------------------------
//
// Both can represent null, but:
//   String? — nullable type. The compiler knows the value is either a String
//              or null. It enforces all String-specific rules at compile time.
//   dynamic  — untyped. The compiler imposes NO constraints whatsoever.
//              Null safety does NOT apply — you can call any method on a
//              dynamic value and the compiler won't complain. Errors show up
//              only at runtime as NoSuchMethodError.

void stringVsDynamic() {
  String? s = null;
  // s.length;          // compile error — could be null
  s?.length; // OK — null-safe access

  dynamic d = null;
  // d.length;          // compiles fine! But throws NoSuchMethodError at runtime
  //                    // because null has no `length` getter.

  // Prefer String? over dynamic: you keep static type safety AND allow null.
  // Use dynamic only when you genuinely don't know the type (e.g., JSON decode).
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main() {
  print('=== Null-aware operators ===');
  print(demonstrateNullAwareOps());

  print('\n=== Flow analysis ===');
  flowAnalysis();

  print('\n=== late keyword ===');
  demonstrateLate();

  print('\n=== lazy late final (DB service) ===');
  final db = DatabaseService();
  print(db.connection); // triggers initializer
  print(db.connection); // returns cached value — NOT recomputed

  print('\n=== Nullable generics ===');
  nullableGenerics();

  print('\n=== required named params ===');
  final user = UserProfile(name: 'Alice', age: 30, bio: 'Dart developer');
  print('${user.name}, ${user.age}, ${user.bio}');

  print('\n=== String? vs dynamic ===');
  stringVsDynamic();
  print('(See comments — dynamic errors only appear at runtime)');
}
