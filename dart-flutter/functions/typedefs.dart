/// typedefs.dart
///
/// Typedefs and type aliases in Dart — semantic naming and advanced patterns.
/// Run with: dart run typedefs.dart

// ---------------------------------------------------------------------------
// OVERVIEW
// ---------------------------------------------------------------------------
// In modern Dart, `typedef` and "type alias" are the same feature.
// A typedef gives a name to a type expression.  It can alias:
//   • Function types (the original use case)
//   • Any generic type (Dart 2.13+)
//   • Record types, nullable types, etc.
//
// The aliased type and the original type are completely interchangeable at
// runtime — they are structurally typed, not nominally typed.

// ---------------------------------------------------------------------------
// 1. TYPEDEF FOR FUNCTION TYPES
// ---------------------------------------------------------------------------
// Classic use: give a function signature a human-readable name.

// A predicate that tests a value of type T.
typedef Predicate<T> = bool Function(T value);

// A simple action callback (no parameters, no return value).
typedef VoidCallback = void Function();

// A transformer: maps a value of type A to type B.
typedef Transformer<A, B> = B Function(A input);

// A binary operator on two values of the same type.
typedef BinaryOp<T> = T Function(T a, T b);

void demoFunctionTypedef() {
  print('\n--- 1. Function typedefs ---');

  // Using Predicate<int> — reads much better than `bool Function(int)`.
  Predicate<int> isEven = (n) => n % 2 == 0;
  Predicate<String> isLong = (s) => s.length > 5;

  print(isEven(4));    // true
  print(isLong('hi')); // false
  print(isLong('hello world')); // true

  // Transformer<String, int>: string → int.
  Transformer<String, int> wordCount = (s) => s.split(' ').length;
  print(wordCount('one two three')); // 3

  // BinaryOp<int>: addition, maximum, etc.
  BinaryOp<int> add = (a, b) => a + b;
  BinaryOp<int> max = (a, b) => a > b ? a : b;
  print('add(3,4)=${add(3,4)}, max(3,4)=${max(3,4)}');

  // The typedef is structural: a bare `(int) => bool` lambda IS a Predicate<int>.
  final List<int> nums = [1, 2, 3, 4, 5, 6];
  print(nums.where(isEven).toList()); // [2, 4, 6]
}

// ---------------------------------------------------------------------------
// 2. GENERIC TYPEDEFS (Dart 2.13+)
// ---------------------------------------------------------------------------
// Before 2.13 you could only use generics in function typedefs.
// Now you can alias ANY generic type.

// Alias for a nullable map — common in JSON deserialization.
typedef JsonMap = Map<String, dynamic>;

// Alias for a list of nullable strings.
typedef MaybeStrings = List<String?>;

// Alias for a Future that returns a list.
typedef AsyncList<T> = Future<List<T>>;

// A Result-style pair: (success value, error message).
typedef Result<T> = (T? value, String? error);

// Alias for a deeply nested generic — improves readability dramatically.
typedef GroupedMap<K, V> = Map<K, List<V>>;

void demoGenericTypedef() {
  print('\n--- 2. Generic typedefs (2.13+) ---');

  // JsonMap — widely used when decoding JSON.
  JsonMap user = {'name': 'Alice', 'age': 30, 'active': true};
  print('name: ${user['name']}, age: ${user['age']}');

  // Result<int> — lightweight error handling without exceptions.
  Result<int> divide(int a, int b) {
    if (b == 0) return (null, 'division by zero');
    return (a ~/ b, null);
  }

  final ok = divide(10, 2);
  final err = divide(5, 0);
  print('10/2: value=${ok.$1}, error=${ok.$2}'); // value=5, error=null
  print('5/0:  value=${err.$1}, error=${err.$2}'); // value=null, error=division...

  // GroupedMap — group items by key.
  GroupedMap<String, int> grouped = {'evens': [2, 4, 6], 'odds': [1, 3, 5]};
  print('grouped: $grouped');
}

// ---------------------------------------------------------------------------
// 3. TYPEDEF vs INLINE FUNCTION TYPE ANNOTATION
// ---------------------------------------------------------------------------
// Both are valid; the choice is about readability and reusability.
//
// INLINE:  void processAll(List<int> items, bool Function(int) filter)
// TYPEDEF: void processAll(List<int> items, Predicate<int> filter)
//
// Guidelines:
//  • Use a typedef when the same function shape appears in multiple places.
//  • Use a typedef when the *name* conveys intent beyond just the signature.
//  • Use inline for one-off, simple callbacks close to their use.

// Example: inline annotation works fine for a one-off sort comparator.
void sortWith(List<int> list, int Function(int, int) compare) {
  list.sort(compare);
}

// But for a recurring callback shape across a public API, typedef is better.
typedef Comparator<T> = int Function(T a, T b);

void sortWithTyped<T>(List<T> list, Comparator<T> compare) {
  list.sort(compare);
}

void demoInlineVsTypedef() {
  print('\n--- 3. Inline vs typedef ---');

  final nums = [3, 1, 4, 1, 5, 9, 2, 6];
  sortWith(nums, (a, b) => a - b);
  print('sorted: $nums'); // [1, 1, 2, 3, 4, 5, 6, 9]

  final words = ['banana', 'apple', 'cherry'];
  sortWithTyped<String>(words, (a, b) => a.compareTo(b));
  print('sorted words: $words'); // [apple, banana, cherry]
}

// ---------------------------------------------------------------------------
// 4. SEMANTIC NAMES FOR CALLBACKS
// ---------------------------------------------------------------------------
// The real power of typedef is communication.  A bare `void Function()`
// says nothing; `AnimationCallback` tells the reader the intended use.

typedef AnimationCallback = void Function(double t);
typedef ErrorHandler = void Function(Object error, StackTrace stack);
typedef ItemBuilder<T, W> = W Function(int index, T item);

// Simulate a simple animation runner.
void runAnimation(double duration, AnimationCallback onTick) {
  for (var t = 0.0; t <= duration; t += duration / 3) {
    onTick(t / duration); // normalized t in [0, 1]
  }
}

void demoSemanticNames() {
  print('\n--- 4. Semantic names for callbacks ---');

  runAnimation(1.0, (t) => print('tick t=${t.toStringAsFixed(2)}'));

  // ErrorHandler — the typedef signals "this is error-handling code".
  ErrorHandler logger = (e, st) => print('ERROR: $e');
  try {
    throw Exception('oops');
  } catch (e, st) {
    logger(e, st); // ERROR: Exception: oops
  }
}

// ---------------------------------------------------------------------------
// 5. TYPEDEF FOR COMPLEX GENERIC TYPES — THE Parser EXAMPLE
// ---------------------------------------------------------------------------
// One of the most elegant uses: giving a name to a *parameterized* function
// type so you can build composable, type-safe APIs.

typedef Parser<T> = T Function(String source);
typedef Encoder<T> = String Function(T value);

// A codec bundles both directions.
class Codec<T> {
  final Parser<T> decode;
  final Encoder<T> encode;
  const Codec({required this.decode, required this.encode});
}

// Ready-made codecs.
final intCodec = Codec<int>(
  decode: int.parse,
  encode: (n) => n.toString(),
);

final boolCodec = Codec<bool>(
  decode: (s) => s == 'true',
  encode: (b) => b ? 'true' : 'false',
);

// A generic deserializer that uses a Parser.
T parseOrDefault<T>(String? raw, Parser<T> parse, T fallback) {
  if (raw == null) return fallback;
  try {
    return parse(raw);
  } catch (_) {
    return fallback;
  }
}

void demoParserTypedef() {
  print('\n--- 5. Parser<T> typedef ---');

  print(intCodec.decode('42'));       // 42
  print(intCodec.encode(42));         // "42"
  print(boolCodec.decode('true'));    // true

  // Using parseOrDefault with different parsers.
  print(parseOrDefault('10', int.parse, 0));    // 10
  print(parseOrDefault('bad', int.parse, 0));   // 0  (fallback)
  print(parseOrDefault(null, int.parse, -1));   // -1 (fallback)
}

// ---------------------------------------------------------------------------
// 6. USING TYPEDEFS WITH HIGHER-ORDER FUNCTIONS
// ---------------------------------------------------------------------------
// Typedefs compose naturally with HOFs.  Naming the function type makes
// the signature of HOFs much easier to read.

typedef Reducer<T> = T Function(T accumulator, T element);
typedef Mapper<A, B> = B Function(A element);

// A typed pipeline that maps then reduces.
B? mapReduce<A, B>(
  Iterable<A> items,
  Mapper<A, B> mapper,
  Reducer<B> reducer,
) {
  final mapped = items.map(mapper);
  if (mapped.isEmpty) return null;
  return mapped.reduce(reducer);
}

// A function that takes a Predicate and returns a new Predicate (negation).
Predicate<T> negate<T>(Predicate<T> p) => (v) => !p(v);

// Compose two Predicates with logical AND.
Predicate<T> and<T>(Predicate<T> a, Predicate<T> b) => (v) => a(v) && b(v);

void demoTypedefsWithHOF() {
  print('\n--- 6. Typedefs with higher-order functions ---');

  // mapReduce: map strings to lengths, then sum.
  final words = ['hi', 'hello', 'world'];
  final totalChars = mapReduce<String, int>(
    words,
    (s) => s.length,    // Mapper<String, int>
    (acc, n) => acc + n, // Reducer<int>
  );
  print('total chars: $totalChars'); // 12

  // negate and and combinators.
  Predicate<int> isEven = (n) => n % 2 == 0;
  Predicate<int> isOdd = negate(isEven);
  Predicate<int> isOddAndBig = and(isOdd, (n) => n > 5);

  final nums = [1, 2, 6, 7, 3, 9];
  print('odd:          ${nums.where(isOdd).toList()}');        // [1, 7, 3, 9]
  print('odd and > 5:  ${nums.where(isOddAndBig).toList()}');  // [7, 9]
}

// ---------------------------------------------------------------------------
// MAIN
// ---------------------------------------------------------------------------
void main() {
  demoFunctionTypedef();
  demoGenericTypedef();
  demoInlineVsTypedef();
  demoSemanticNames();
  demoParserTypedef();
  demoTypedefsWithHOF();
}
