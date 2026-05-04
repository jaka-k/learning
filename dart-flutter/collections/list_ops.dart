// =============================================================================
// DART LIST OPERATIONS — advanced usage guide
// =============================================================================
// Run with:  dart run list_ops.dart
// Dart SDK:  >= 2.19
// =============================================================================

import 'dart:collection'; // for ListBase

// ---------------------------------------------------------------------------
// 1. List constructors — growable vs fixed-length
// ---------------------------------------------------------------------------
void constructorsDemo() {
  print('\n--- List constructors ---');

  // List.filled: fixed-length by default, all elements set to the fill value.
  // Attempting to add/remove throws UnsupportedError at runtime.
  final fixed = List<int>.filled(5, 0); // [0,0,0,0,0]
  fixed[2] = 42; // index assignment is allowed
  print('filled (fixed): $fixed');
  // fixed.add(1); // ← UnsupportedError: Cannot add to a fixed-length list

  // Make growable by passing growable: true.
  final growable = List<int>.filled(3, 0, growable: true);
  growable.add(99);
  print('filled (growable): $growable');

  // List.generate: builds with an index-based factory.
  // growable: true (the default) — can add/remove after creation.
  final squares = List<int>.generate(5, (i) => i * i); // [0,1,4,9,16]
  print('generate: $squares');

  // List.generate with growable: false → fixed-length.
  final fixedGen = List<int>.generate(3, (i) => i, growable: false);
  print('generate fixed-length: $fixedGen');

  // List.unmodifiable: wraps any Iterable; NEITHER length NOR elements can change.
  // More restrictive than fixed-length: even index assignment is forbidden.
  final immutable = List<int>.unmodifiable([1, 2, 3]);
  print('unmodifiable: $immutable');
  // immutable[0] = 9; // ← UnsupportedError
}

// ---------------------------------------------------------------------------
// 2. sort with custom Comparator
// ---------------------------------------------------------------------------
void sortDemo() {
  print('\n--- sort ---');

  final words = ['banana', 'apple', 'cherry', 'date'];

  // sort() mutates in place, uses natural order by default (Comparable).
  words.sort();
  print('natural sort: $words'); // alphabetical

  // Custom Comparator: sort by string length, then lexicographically.
  words.sort((a, b) {
    final lengthCmp = a.length.compareTo(b.length);
    return lengthCmp != 0 ? lengthCmp : a.compareTo(b);
  });
  print('by length then alpha: $words');

  // Stable sort: Dart's sort is NOT guaranteed stable before Dart 2.0;
  // from Dart 2.0+ List.sort IS stable on the Dart VM.

  // Sort a list of maps by a field.
  final users = [
    {'name': 'Charlie', 'age': 30},
    {'name': 'Alice', 'age': 25},
    {'name': 'Bob', 'age': 25},
  ];
  users.sort((a, b) {
    final ageCmp = (a['age'] as int).compareTo(b['age'] as int);
    if (ageCmp != 0) return ageCmp;
    return (a['name'] as String).compareTo(b['name'] as String);
  });
  print('users by age then name: ${users.map((u) => u['name'])}');
}

// ---------------------------------------------------------------------------
// 3. sublist vs getRange
// ---------------------------------------------------------------------------
void slicingDemo() {
  print('\n--- sublist vs getRange ---');

  final nums = [0, 1, 2, 3, 4, 5, 6, 7];

  // sublist: returns a NEW List (copy), O(n).  start inclusive, end exclusive.
  final sub = nums.sublist(2, 5); // [2, 3, 4]
  sub[0] = 99; // does NOT affect original
  print('sublist (copy): $sub');
  print('original unchanged: $nums');

  // getRange: returns a lazy Iterable VIEW — no copy, O(1) to create.
  // Modifying the original while iterating is undefined behaviour.
  final range = nums.getRange(1, 4); // Iterable: [1, 2, 3]
  print('getRange (lazy iterable): ${range.toList()}');

  // IMPORTANT: getRange result is invalidated if the list changes before
  // you iterate it.  Use sublist if you need a stable snapshot.
}

// ---------------------------------------------------------------------------
// 4. fold to build structures from lists
// ---------------------------------------------------------------------------
void foldDemo() {
  print('\n--- fold ---');

  final prices = [10.0, 20.0, 5.0, 15.0];

  // Simple aggregate.
  final total = prices.fold<double>(0, (acc, p) => acc + p);
  print('total: $total');

  // Build a Map from a list using fold.
  final words = ['hello', 'world', 'dart'];
  final wordLengths = words.fold<Map<String, int>>(
    {},
    (map, word) => map..putIfAbsent(word, () => word.length),
  );
  print('word lengths: $wordLengths');
}

// ---------------------------------------------------------------------------
// 5. groupBy pattern via fold (no built-in)
// ---------------------------------------------------------------------------
// Dart's core libraries don't have a groupBy — use fold or package:collection.
Map<K, List<V>> groupBy<V, K>(Iterable<V> items, K Function(V) keyOf) {
  return items.fold<Map<K, List<V>>>(
    {},
    (map, item) {
      final key = keyOf(item);
      map.putIfAbsent(key, () => []).add(item);
      return map;
    },
  );
}

void groupByDemo() {
  print('\n--- groupBy ---');

  final words = ['ant', 'bear', 'cat', 'ape', 'bat', 'crow'];
  final byFirstLetter = groupBy(words, (w) => w[0]);
  byFirstLetter.forEach((k, v) => print('  $k: $v'));
}

// ---------------------------------------------------------------------------
// 6. whereType<T>() — type-filtered iteration
// ---------------------------------------------------------------------------
void whereTypeDemo() {
  print('\n--- whereType ---');

  // Typical use: a heterogeneous list (e.g., from JSON parsing or widget lists).
  final mixed = <Object>[1, 'hello', 2.0, true, 'world', 42, null, 3];

  // whereType lazily filters to only elements of the given type.
  // Returns Iterable<T>, not Iterable<Object>.
  final strings = mixed.whereType<String>().toList(); // ['hello', 'world']
  final ints = mixed.whereType<int>().toList();       // [1, 42, 3]

  print('strings: $strings');
  print('ints: $ints');
  // null is NOT of type int, so it's excluded.
}

// ---------------------------------------------------------------------------
// 7. zip pattern (no built-in — implement)
// ---------------------------------------------------------------------------
// package:collection provides zip, but it's easy to write manually.
Iterable<(A, B)> zip<A, B>(Iterable<A> a, Iterable<B> b) sync* {
  final iterA = a.iterator;
  final iterB = b.iterator;
  while (iterA.moveNext() && iterB.moveNext()) {
    yield (iterA.current, iterB.current);
  }
  // Stops at the shorter of the two (standard zip semantics).
}

void zipDemo() {
  print('\n--- zip ---');

  final names = ['Alice', 'Bob', 'Charlie'];
  final scores = [95, 80, 70, 60]; // longer list — extra element dropped

  for (final (name, score) in zip(names, scores)) {
    print('  $name: $score');
  }
}

// ---------------------------------------------------------------------------
// 8. List.of vs toList — copy semantics
// ---------------------------------------------------------------------------
void copyDemo() {
  print('\n--- List.of vs toList ---');

  final original = [1, 2, 3];

  // toList(): Iterable extension; creates a new growable List by default.
  final copy1 = original.toList(); // growable: true (default)
  final copy2 = original.toList(growable: false); // fixed-length copy

  // List.of(): similar to toList() but explicitly typed.
  // Useful when the source is Iterable<Object> and you want List<int>.
  final copy3 = List<int>.of(original); // growable copy with type clarity

  copy1.add(99); // works (growable)
  // copy2.add(99); // UnsupportedError

  print('copy1: $copy1, copy2: $copy2, copy3: $copy3');
  print('original unaffected: $original');

  // Shallow copy gotcha: elements are shared references, not deep copies.
  final nested = [[1, 2], [3, 4]];
  final shallowCopy = List.of(nested);
  shallowCopy[0].add(99); // MODIFIES the same inner list!
  print('shallow copy pitfall — original nested[0]: ${nested[0]}'); // [1, 2, 99]
}

// ---------------------------------------------------------------------------
// 9. spread operator with lists
// ---------------------------------------------------------------------------
void spreadDemo() {
  print('\n--- spread ---');

  final a = [1, 2, 3];
  final b = [4, 5, 6];
  final combined = [...a, ...b]; // new list, O(n) copy
  print('spread merge: $combined');

  // Null-aware spread: ...? skips null iterables entirely.
  List<int>? maybeList;
  final safe = [0, ...?maybeList, 7]; // maybeList is null → skipped
  print('null-aware spread: $safe'); // [0, 7]
}

// ---------------------------------------------------------------------------
// 10. retainWhere / removeWhere
// ---------------------------------------------------------------------------
void mutationDemo() {
  print('\n--- retainWhere / removeWhere ---');

  final nums = [1, 2, 3, 4, 5, 6, 7, 8];

  nums.removeWhere((n) => n.isEven); // mutates in place
  print('after removeWhere(even): $nums'); // [1,3,5,7]

  nums.retainWhere((n) => n > 3); // keep only elements matching predicate
  print('after retainWhere(>3): $nums'); // [5,7]
}

// ---------------------------------------------------------------------------
// 11. ListBase — custom List implementation
// ---------------------------------------------------------------------------
// Extending ListBase (from dart:collection) lets you build a List-like class
// by only implementing: get length, operator[], operator[]=, set length.
// All other List methods (add, where, map, etc.) are derived automatically.
class RingBuffer<T> extends ListBase<T> {
  final List<T?> _data;
  int _start = 0;
  int _count = 0;

  RingBuffer(int capacity) : _data = List<T?>.filled(capacity, null);

  int get capacity => _data.length;

  @override
  int get length => _count;

  @override
  set length(int newLength) {
    // For demo purposes, only shrinking is supported.
    if (newLength < _count) _count = newLength;
  }

  @override
  T operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return _data[(_start + index) % capacity] as T;
  }

  @override
  void operator []=(int index, T value) {
    RangeError.checkValidIndex(index, this);
    _data[(_start + index) % capacity] = value;
  }

  // Override add to implement ring semantics.
  @override
  void add(T element) {
    if (_count < capacity) {
      _data[(_start + _count) % capacity] = element;
      _count++;
    } else {
      // Buffer full: overwrite oldest entry.
      _data[_start] = element;
      _start = (_start + 1) % capacity;
    }
  }
}

void listBaseDemo() {
  print('\n--- ListBase (RingBuffer) ---');

  final ring = RingBuffer<int>(4);
  ring.addAll([1, 2, 3, 4]); // fills the buffer
  ring.add(5);               // overwrites 1
  ring.add(6);               // overwrites 2
  print('ring contents: $ring'); // [3, 4, 5, 6]

  // All List operations work because ListBase derives them:
  print('ring.where(>4): ${ring.where((n) => n > 4).toList()}'); // [5, 6]
  print('ring.map(*2): ${ring.map((n) => n * 2).toList()}'); // [6,8,10,12]
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() {
  constructorsDemo();
  sortDemo();
  slicingDemo();
  foldDemo();
  groupByDemo();
  whereTypeDemo();
  zipDemo();
  copyDemo();
  spreadDemo();
  mutationDemo();
  listBaseDemo();
}
