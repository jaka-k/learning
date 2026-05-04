// =============================================================================
// DART MAPS AND SETS — advanced usage guide
// =============================================================================
// Run with:  dart run map_set.dart
// Dart SDK:  >= 2.19
// =============================================================================

import 'dart:collection'; // LinkedHashMap, HashMap, SplayTreeMap, etc.

// ---------------------------------------------------------------------------
// 1. Map construction helpers
// ---------------------------------------------------------------------------
void mapConstructionDemo() {
  print('\n--- Map construction ---');

  // Map literal (LinkedHashMap under the hood — preserves insertion order).
  final literal = {'a': 1, 'b': 2, 'c': 3};
  print('literal: $literal');

  // Map.fromEntries: build from an Iterable<MapEntry<K,V>>.
  // Useful when transforming another collection.
  final swapped = Map.fromEntries(
    literal.entries.map((e) => MapEntry(e.value, e.key)),
  );
  print('fromEntries (swapped k/v): $swapped'); // {1: a, 2: b, 3: c}

  // Map.fromIterables: zips two parallel iterables into key-value pairs.
  // If lengths differ, throws a StateError.
  final keys = ['x', 'y', 'z'];
  final values = [10, 20, 30];
  final zipped = Map.fromIterables(keys, values);
  print('fromIterables: $zipped');

  // Map.of: shallow copy of an existing map.
  final copy = Map.of(literal);
  copy['d'] = 4; // does not affect original
  print('copy (Map.of): $copy');
}

// ---------------------------------------------------------------------------
// 2. map.update / map.putIfAbsent
// ---------------------------------------------------------------------------
void updateDemo() {
  print('\n--- update / putIfAbsent ---');

  final scores = <String, int>{'Alice': 10, 'Bob': 5};

  // update: modifies existing value; throws if key is absent unless you
  // provide ifAbsent.
  scores.update('Alice', (v) => v + 5); // 10 → 15
  scores.update('Charlie', (v) => v + 5, ifAbsent: () => 1); // insert with 1
  print('after update: $scores');

  // putIfAbsent: insert a default value only if the key is missing; returns
  // the existing or newly inserted value.  Does NOT update existing values.
  final existing = scores.putIfAbsent('Alice', () => 999); // Alice exists → 15
  final inserted = scores.putIfAbsent('Dave', () => 7);   // Dave absent → 7
  print('putIfAbsent existing=$existing, inserted=$inserted');
  print('scores: $scores');

  // Common pattern: frequency counter
  final words = ['apple', 'banana', 'apple', 'cherry', 'banana', 'apple'];
  final freq = <String, int>{};
  for (final w in words) {
    freq.update(w, (n) => n + 1, ifAbsent: () => 1);
  }
  print('frequency: $freq');
}

// ---------------------------------------------------------------------------
// 3. map.entries iteration
// ---------------------------------------------------------------------------
void entriesDemo() {
  print('\n--- map.entries ---');

  final config = {'host': 'localhost', 'port': '5432', 'db': 'prod'};

  // entries returns Iterable<MapEntry<K,V>> — lazy, no copy.
  for (final MapEntry(:key, :value) in config.entries) {
    print('  $key = $value');
  }

  // Transform to a new map: filter entries where value length > 4.
  final long = Map.fromEntries(
    config.entries.where((e) => e.value.length > 4),
  );
  print('entries with value.length > 4: $long');
}

// ---------------------------------------------------------------------------
// 4. Nested maps
// ---------------------------------------------------------------------------
void nestedMapsDemo() {
  print('\n--- nested maps ---');

  // JSON-like nested structure.
  final data = <String, dynamic>{
    'user': {
      'name': 'Alice',
      'scores': [95, 88, 72],
    },
    'meta': {'version': 2},
  };

  // Deep access — must cast at each level (no path operator in Dart).
  final name = (data['user'] as Map<String, dynamic>)['name'];
  print('deep access: $name');

  // Safe deep access pattern with null-aware operators.
  final version = (data['meta'] as Map?)?.['version'];
  print('meta version: $version');

  // Mutating nested: putIfAbsent for deep upsert.
  (data['user'] as Map<String, dynamic>)
      .putIfAbsent('email', () => 'alice@example.com');
  print('after nested putIfAbsent: ${data['user']}');
}

// ---------------------------------------------------------------------------
// 5. LinkedHashMap — insertion-order preserved (default Map literal)
// ---------------------------------------------------------------------------
void linkedHashMapDemo() {
  print('\n--- LinkedHashMap ---');

  // Explicit creation (same as map literal):
  final lhm = LinkedHashMap<String, int>();
  lhm['c'] = 3;
  lhm['a'] = 1;
  lhm['b'] = 2;
  // Iteration always yields: c, a, b  (insertion order).
  print('LinkedHashMap (insertion order): $lhm');
}

// ---------------------------------------------------------------------------
// 6. HashMap — unordered, O(1) average lookup (fastest for large maps)
// ---------------------------------------------------------------------------
void hashMapDemo() {
  print('\n--- HashMap ---');

  // HashMap uses hash codes directly; no ordering guarantee.
  // Prefer this when you don't care about iteration order and the map is large.
  final hm = HashMap<String, int>();
  hm['c'] = 3;
  hm['a'] = 1;
  hm['b'] = 2;
  // Iteration order is unspecified — may differ between runs.
  print('HashMap (unordered): ${hm.keys.toList()}');

  // Custom equality / hash: override == for key objects, OR pass
  // equals and hashCode functions to the constructor.
  final caseInsensitive = HashMap<String, int>(
    equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
    hashCode: (k) => k.toLowerCase().hashCode,
  );
  caseInsensitive['Hello'] = 1;
  print('case-insensitive lookup "hello": ${caseInsensitive['hello']}'); // 1
}

// ---------------------------------------------------------------------------
// 7. SplayTreeMap — sorted by key, O(log n) operations
// ---------------------------------------------------------------------------
void splayTreeMapDemo() {
  print('\n--- SplayTreeMap ---');

  // Default: sorts by natural comparison (Comparable).
  final stm = SplayTreeMap<String, int>();
  stm['banana'] = 2;
  stm['apple'] = 5;
  stm['cherry'] = 1;
  // Iteration is always in sorted key order.
  print('SplayTreeMap (sorted keys): $stm');

  // Custom comparator: reverse alphabetical.
  final reversed = SplayTreeMap<String, int>((a, b) => b.compareTo(a));
  reversed.addAll({'banana': 2, 'apple': 5, 'cherry': 1});
  print('SplayTreeMap (reversed): ${reversed.keys.toList()}');

  // SplayTreeMap also supports efficient range operations.
  // firstKey / lastKey / keys before / keys from:
  print('firstKey: ${stm.firstKey()}, lastKey: ${stm.lastKey()}');
}

// ---------------------------------------------------------------------------
// 8. Set operations
// ---------------------------------------------------------------------------
void setDemo() {
  print('\n--- Set operations ---');

  final a = {1, 2, 3, 4, 5};
  final b = {3, 4, 5, 6, 7};

  // union: elements in a OR b (no duplicates).
  print('union: ${a.union(b)}');

  // intersection: elements in a AND b.
  print('intersection: ${a.intersection(b)}');

  // difference: elements in a but NOT in b.
  print('difference a−b: ${a.difference(b)}');
  print('difference b−a: ${b.difference(a)}');

  // retainAll: mutates the set to keep only elements also in the argument.
  final c = {1, 2, 3, 4, 5};
  c.retainAll([2, 4, 6]); // in-place intersection (ignores 6 — not in c)
  print('retainAll([2,4,6]): $c'); // {2, 4}

  // removeAll: mutates, removes all elements present in the argument.
  a.removeAll([1, 3, 5]);
  print('removeAll([1,3,5]): $a'); // {2, 4}

  // contains / containsAll:
  print('b.containsAll([3,4]): ${b.containsAll([3, 4])}');
}

// ---------------------------------------------------------------------------
// 9. LinkedHashSet — insertion-order preserved Set
// ---------------------------------------------------------------------------
void linkedHashSetDemo() {
  print('\n--- LinkedHashSet ---');

  // Default Set literal creates a LinkedHashSet.
  final lhs = LinkedHashSet<String>();
  lhs.addAll(['cherry', 'apple', 'banana']);
  print('LinkedHashSet (insertion order): $lhs'); // cherry, apple, banana
}

// ---------------------------------------------------------------------------
// 10. SplayTreeSet — always-sorted Set
// ---------------------------------------------------------------------------
void splayTreeSetDemo() {
  print('\n--- SplayTreeSet ---');

  final sts = SplayTreeSet<int>();
  sts.addAll([5, 2, 8, 1, 9, 3]);
  print('SplayTreeSet (sorted): $sts'); // {1,2,3,5,8,9}

  // Custom comparator: case-insensitive string set.
  final caseSet = SplayTreeSet<String>((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  caseSet.addAll(['Banana', 'apple', 'Cherry']);
  print('SplayTreeSet case-insensitive: $caseSet');
}

// ---------------------------------------------------------------------------
// 11. Conversions between Map / List / Set
// ---------------------------------------------------------------------------
void conversionDemo() {
  print('\n--- conversions ---');

  final list = [1, 2, 3, 2, 1];

  // List → Set (deduplication, order depends on Set impl — LinkedHashSet here).
  final set = list.toSet(); // {1, 2, 3}
  print('list.toSet(): $set');

  // Set → List
  final backToList = set.toList(); // [1, 2, 3]
  print('set.toList(): $backToList');

  // List → Map (index as key)
  final indexedMap = {for (var i = 0; i < list.length; i++) i: list[i]};
  print('list → indexed map: $indexedMap');

  // Map → List of values
  final config = {'a': 1, 'b': 2, 'c': 3};
  final valueList = config.values.toList(); // [1, 2, 3]
  print('map.values.toList(): $valueList');

  // Map → Set of keys
  final keySet = config.keys.toSet();
  print('map.keys.toSet(): $keySet');
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() {
  mapConstructionDemo();
  updateDemo();
  entriesDemo();
  nestedMapsDemo();
  linkedHashMapDemo();
  hashMapDemo();
  splayTreeMapDemo();
  setDemo();
  linkedHashSetDemo();
  splayTreeSetDemo();
  conversionDemo();
}
