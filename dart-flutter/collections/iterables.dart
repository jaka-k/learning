// =============================================================================
// DART ITERABLES — laziness, generators, custom iterators
// =============================================================================
// Run with:  dart run iterables.dart
// Dart SDK:  >= 2.19
// =============================================================================

// ---------------------------------------------------------------------------
// 1. Iterable is LAZY — no computation until a terminal operation
// ---------------------------------------------------------------------------
// An Iterable does NOT hold computed values.  Each operator (map, where, etc.)
// returns a NEW Iterable that wraps the previous one in a pipeline.
// Computation only happens when you PULL values via:
//   • for-in loop
//   • toList() / toSet()
//   • first / last / single
//   • any() / every() / contains()
//   • fold() / reduce()
//   • elementAt()
//
// This is fundamentally different from List: a List has already computed all
// its elements in memory.
void lazyDemo() {
  print('\n--- laziness demonstration ---');

  int callCount = 0;

  final lazy = Iterable.generate(5, (i) {
    callCount++;
    return i * i; // [0, 1, 4, 9, 16]
  });

  print('callCount after creating Iterable: $callCount'); // 0 — nothing ran yet

  // The pipeline is still lazy even after chaining operators.
  final pipeline = lazy
      .where((n) => n > 1)  // adds a filter step to the pipeline
      .map((n) => n * 2);   // adds a transform step

  print('callCount after building pipeline: $callCount'); // still 0

  // Terminal op: now computation happens.
  final result = pipeline.toList();
  print('callCount after toList(): $callCount'); // 5 (all elements evaluated)
  print('result: $result'); // [4, 8, 18, 32]
}

// ---------------------------------------------------------------------------
// 2. sync* generator functions — yield / yield*
// ---------------------------------------------------------------------------
// sync* creates a lazy Iterable.  The body runs only when the consumer calls
// moveNext() (implicitly via for-in or explicitly via .iterator).
// Execution PAUSES at each yield and RESUMES when the next value is needed.
//
// This gives you iterator protocol semantics with normal control flow.
Iterable<int> range(int start, int end, [int step = 1]) sync* {
  for (int i = start; i < end; i += step) {
    yield i; // pause here, hand control back to the consumer
  }
}

// yield*: delegate to another Iterable/generator, yielding all its values.
Iterable<int> combined(int a, int b) sync* {
  yield* range(0, a);    // yields 0..a-1
  yield* range(10, 10 + b); // yields 10..10+b-1
}

void syncStarDemo() {
  print('\n--- sync* generator ---');

  print('range(2, 10, 2): ${range(2, 10, 2).toList()}'); // [2,4,6,8]
  print('combined(3, 3): ${combined(3, 3).toList()}'); // [0,1,2,10,11,12]
}

// ---------------------------------------------------------------------------
// 3. Infinite lazy sequences
// ---------------------------------------------------------------------------
// sync* can produce infinite sequences because values are only computed on
// demand.  NEVER call toList() on an infinite iterable!
Iterable<int> naturals() sync* {
  int n = 0;
  while (true) {
    yield n++; // infinite stream of 0, 1, 2, ...
  }
}

Iterable<int> fibonacci() sync* {
  int a = 0, b = 1;
  while (true) {
    yield a;
    final next = a + b;
    a = b;
    b = next;
  }
}

void infiniteDemo() {
  print('\n--- infinite lazy sequences ---');

  // take(n) creates a lazy wrapper that stops after n elements.
  // The underlying infinite generator is NOT called beyond n times.
  final first10 = naturals().take(10).toList();
  print('first 10 naturals: $first10');

  // Chaining: take only even fibonacci numbers < 100.
  final evenFibs = fibonacci()
      .where((n) => n.isEven)
      .takeWhile((n) => n < 100)
      .toList();
  print('even fibs < 100: $evenFibs');
}

// ---------------------------------------------------------------------------
// 4. Iterable.generate — index-based lazy Iterable
// ---------------------------------------------------------------------------
// Similar to List.generate but LAZY.  The factory is only called when the
// element is actually consumed.
void generateDemo() {
  print('\n--- Iterable.generate ---');

  // Lazy: the factory (n*n) is NOT called until iteration.
  final squares = Iterable<int>.generate(1000000, (n) => n * n);

  // first runs the factory exactly ONCE.
  print('squares.first: ${squares.first}'); // 0 — factory called once

  // take(5) evaluates exactly 5 times.
  print('first 5 squares: ${squares.take(5).toList()}');
}

// ---------------------------------------------------------------------------
// 5. The pipeline stays lazy until a terminal operation
// ---------------------------------------------------------------------------
void lazyPipelineDemo() {
  print('\n--- lazy pipeline ---');

  final counter = <String>[];

  final result = Iterable.generate(10, (i) => i)
      .map((i) {
        counter.add('map:$i');
        return i * 3;
      })
      .where((n) {
        counter.add('where:$n');
        return n > 10;
      })
      .take(2); // stops after 2 matching elements

  print('counter before terminal op: ${counter.length}'); // 0

  // Trigger evaluation:
  final list = result.toList();
  print('list: $list'); // [12, 15]

  // Counter shows that:
  // - Only elements up to and including the 2 matches were evaluated.
  // - Where-filter saw some values that failed (n <= 10) and stopped at 2 passes.
  print('operations logged: $counter');
  // NOT all 10 elements were processed — laziness + take short-circuits.
}

// ---------------------------------------------------------------------------
// 6. elementAt vs [] — Iterables have NO random access
// ---------------------------------------------------------------------------
// List has O(1) random access via [].
// Iterable.elementAt(i) is O(i) — it must traverse i elements from the start.
// Never use elementAt in a loop — use toList() first for repeated access.
void elementAtDemo() {
  print('\n--- elementAt vs [] ---');

  final list = [10, 20, 30, 40, 50];
  final iter = list.map((n) => n * 2); // lazy Iterable

  print('list[3]: ${list[3]}'); // O(1)
  print('iter.elementAt(3): ${iter.elementAt(3)}'); // O(n) — iterates 4 times

  // Anti-pattern:
  // for (int i = 0; i < iter.length; i++) iter.elementAt(i); // O(n²)!

  // Correct: materialise first.
  final materialized = iter.toList();
  for (int i = 0; i < materialized.length; i++) {
    materialized[i]; // O(1) per access
  }
  print('correct: materialise first for random access');
}

// ---------------------------------------------------------------------------
// 7. take / skip
// ---------------------------------------------------------------------------
void takeSkipDemo() {
  print('\n--- take / skip ---');

  final nums = Iterable.generate(10, (i) => i); // 0..9

  // take: lazy, limits to first n elements.
  print('take(3): ${nums.take(3).toList()}'); // [0,1,2]

  // skip: lazy, skips first n elements.
  print('skip(7): ${nums.skip(7).toList()}'); // [7,8,9]

  // takeWhile / skipWhile: predicate-based.
  print('takeWhile(<5): ${nums.takeWhile((n) => n < 5).toList()}'); // [0..4]
  print('skipWhile(<5): ${nums.skipWhile((n) => n < 5).toList()}'); // [5..9]

  // Pagination pattern: page 2 with pageSize 3.
  int page = 2, pageSize = 3;
  final paginated = nums.skip((page - 1) * pageSize).take(pageSize).toList();
  print('page $page (size $pageSize): $paginated'); // [3,4,5]
}

// ---------------------------------------------------------------------------
// 8. Custom Iterable — extend Iterable<E> + implement Iterator<E>
// ---------------------------------------------------------------------------
// By extending Iterable and implementing get iterator, ALL Iterable methods
// (map, where, fold, toList, etc.) become available for free.

// A circular/ring Iterable that wraps around.
class CircularIterable<E> extends Iterable<E> {
  final List<E> _items;
  final int _count; // how many elements to emit total

  CircularIterable(this._items, this._count);

  @override
  Iterator<E> get iterator => CircularIterator<E>(_items, _count);
}

class CircularIterator<E> implements Iterator<E> {
  final List<E> _items;
  final int _count;
  int _emitted = 0;
  int _index = -1; // before the first element

  CircularIterator(this._items, this._count);

  @override
  E get current {
    if (_index < 0) throw StateError('moveNext() not called yet');
    return _items[_index % _items.length];
  }

  @override
  bool moveNext() {
    if (_emitted >= _count) return false; // done
    _index++;
    _emitted++;
    return true;
  }
}

void customIterableDemo() {
  print('\n--- custom Iterable (circular) ---');

  final circ = CircularIterable(['a', 'b', 'c'], 7);

  // All Iterable operations work:
  print('toList: ${circ.toList()}'); // [a,b,c,a,b,c,a]
  print('take(4): ${circ.take(4).toList()}'); // [a,b,c,a]
  print('where(!=b): ${circ.where((s) => s != 'b').toList()}'); // [a,c,a,c,a]
  print('fold: ${circ.fold('', (acc, s) => acc + s)}'); // abcabca
}

// ---------------------------------------------------------------------------
// 9. Iterator protocol directly — moveNext / current
// ---------------------------------------------------------------------------
void iteratorProtocolDemo() {
  print('\n--- Iterator protocol ---');

  // Calling .iterator gives a fresh Iterator; use moveNext/current directly.
  final iter = [1, 2, 3].iterator;

  // Iterator starts BEFORE the first element.
  // You must call moveNext() before accessing current.
  while (iter.moveNext()) {
    print('  current: ${iter.current}');
  }
  // After moveNext() returns false, calling current is undefined / throws.

  // Manual peeking pattern: check first element without consuming it.
  List<int> peekFirst(Iterable<int> it) {
    final iter = it.iterator;
    if (!iter.moveNext()) return []; // empty
    final first = iter.current;
    print('  peeked at first: $first');
    final rest = <int>[];
    while (iter.moveNext()) rest.add(iter.current);
    return [first, ...rest]; // reconstruct
  }

  print('peeked list: ${peekFirst([10, 20, 30])}');
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() {
  lazyDemo();
  syncStarDemo();
  infiniteDemo();
  generateDemo();
  lazyPipelineDemo();
  elementAtDemo();
  takeSkipDemo();
  customIterableDemo();
  iteratorProtocolDemo();
}
