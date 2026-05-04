// =============================================================================
// DART SPREADS, COLLECTION-IF, COLLECTION-FOR
// =============================================================================
// Run with:  dart run spreads.dart
// Dart SDK:  >= 2.3 (spread / collection control flow added in Dart 2.3)
// =============================================================================
//
// Flutter note: these features are especially valuable for building widget
// trees (children lists) because Flutter trees are expressed as Dart literals.
// All examples below are pure Dart so they run without Flutter, but the
// patterns map directly to Flutter widget trees.

// ---------------------------------------------------------------------------
// 1. Spread operator `...` (three dots)
// ---------------------------------------------------------------------------
// `...iterable` inserts ALL elements of the iterable at that position.
// This creates a NEW list — the spread copies all values, O(n total elements).
// It does NOT create a lazy view; evaluation is eager.
void spreadBasicsDemo() {
  print('\n--- spread operator ---');

  final first = [1, 2, 3];
  final second = [4, 5, 6];

  // Merge two lists:
  final merged = [...first, ...second]; // [1,2,3,4,5,6]
  print('merged: $merged');

  // Insert elements at arbitrary positions:
  final surrounded = [0, ...first, 7, 8]; // [0,1,2,3,7,8]
  print('surrounded: $surrounded');

  // The original lists are NOT mutated — a completely new list is returned.
  first[0] = 99;
  print('merged is unaffected: $merged'); // still [1,2,3,4,5,6]

  // Spread with a Set or any Iterable (not just List):
  final fromSet = [...{3, 1, 2}]; // order is insertion order (LinkedHashSet)
  print('spread from Set: $fromSet');

  // Spread with a Map literal (uses Map spread, see section 6):
  final base = {'a': 1, 'b': 2};
  final extended = {...base, 'c': 3};
  print('map spread: $extended');
}

// ---------------------------------------------------------------------------
// 2. Null-aware spread `...?`
// ---------------------------------------------------------------------------
// If the expression after `...?` is null, the spread is silently skipped.
// Without `...?`, spreading null throws a TypeError at runtime.
void nullAwareSpreadDemo() {
  print('\n--- null-aware spread ---');

  List<String>? optional; // null

  // Without null-aware: [...optional] would throw.
  final safe = ['always', ...?optional, 'here']; // ['always', 'here']
  print('null-aware spread (null): $safe');

  optional = ['extra1', 'extra2'];
  final withValues = ['always', ...?optional, 'here'];
  print('null-aware spread (non-null): $withValues');

  // Also works with maps:
  Map<String, int>? extraParams;
  final params = {'page': 1, ...?extraParams};
  print('null-aware map spread: $params'); // {page: 1}
}

// ---------------------------------------------------------------------------
// 3. Collection-if (with optional else)
// ---------------------------------------------------------------------------
// Conditionally include zero or more elements inside a collection literal.
// The expression must be a single bool; no &&/|| inside the if without parens.
void collectionIfDemo() {
  print('\n--- collection-if ---');

  bool isAdmin = true;
  bool isPremium = false;
  bool isDarkMode = true;

  final menu = [
    'Home',
    'Profile',
    if (isPremium) 'Premium Content',       // omitted when false
    if (isAdmin) 'Admin Panel' else 'Upgrade', // else branch
    'Settings',
  ];
  print('menu: $menu');

  // Collection-if with multiple items: use a spread inside the if.
  final features = [
    'basic',
    if (isPremium) ...['analytics', 'exports', 'api_access'], // spread in if
    if (isDarkMode) 'dark_theme',
  ];
  print('features: $features');

  // Nesting collection-if:
  final colors = [
    'red',
    if (isDarkMode) ...[
      'dark_blue',
      if (isAdmin) 'dark_purple', // nested if
    ],
  ];
  print('colors: $colors');
}

// ---------------------------------------------------------------------------
// 4. Collection-for
// ---------------------------------------------------------------------------
// Inline loop inside a collection literal.  The body of the for is a SINGLE
// expression; use spread to include multiple items per iteration.
void collectionForDemo() {
  print('\n--- collection-for ---');

  final items = ['apple', 'banana', 'cherry'];

  // Simple transform (similar to .map but inline):
  final upper = [for (final item in items) item.toUpperCase()];
  print('collection-for toUpperCase: $upper');

  // Generate a range:
  final squares = [for (var i = 1; i <= 5; i++) i * i]; // [1,4,9,16,25]
  print('squares via collection-for: $squares');

  // Nested loops: build a 2D grid as flat list.
  final grid = [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++) '($row,$col)',
  ];
  print('grid (first 5): ${grid.take(5).toList()}');

  // Collection-for with condition (combine with if):
  final evenSquares = [
    for (var i = 1; i <= 10; i++)
      if (i.isEven) i * i, // emit only squares of even numbers
  ];
  print('even squares: $evenSquares');
}

// ---------------------------------------------------------------------------
// 5. Combining spreads with collection-if and collection-for
// ---------------------------------------------------------------------------
void combinedDemo() {
  print('\n--- combined spreads + if + for ---');

  final tags = ['dart', 'flutter', 'async'];
  bool includeDeprecated = false;
  final extraTags = ['mobile', 'web'];

  // Building a dynamic list that mixes all features:
  final allTags = [
    ...tags,                                          // spread
    if (includeDeprecated) 'deprecated',              // if
    ...?extraTags,                                    // null-aware spread
    for (final t in tags) '#${t.toUpperCase()}',      // for
    if (tags.length > 2) ...['many', 'tags'],         // spread inside if
  ];
  print('allTags: $allTags');

  // Map with combined features:
  final queryParams = {
    'page': '1',
    'limit': '20',
    if (includeDeprecated) 'include_deprecated': 'true',
    for (final tag in tags.take(2)) 'tag_${tags.indexOf(tag)}': tag,
  };
  print('queryParams: $queryParams');
}

// ---------------------------------------------------------------------------
// 6. Spread in Map literals
// ---------------------------------------------------------------------------
// Map spread merges key-value pairs.  Duplicate keys: LAST write wins
// (later spreads/entries override earlier ones — useful for defaults/overrides).
void mapSpreadDemo() {
  print('\n--- map spread ---');

  final defaults = {'color': 'blue', 'size': 'medium', 'weight': 'normal'};
  final overrides = {'size': 'large', 'variant': 'outlined'};

  // Merge: overrides take precedence because they appear last.
  final merged = {...defaults, ...overrides};
  print('merged (overrides win): $merged');

  // Explicit override of specific key:
  final withCustomColor = {...defaults, 'color': 'red'};
  print('custom color: $withCustomColor');

  // Building HTTP query params map:
  bool authenticated = true;
  final Map<String, String>? paginationDefaults = {'page': '1', 'limit': '10'};

  final httpParams = <String, String>{
    'api_version': '2',
    ...?paginationDefaults,
    if (authenticated) 'auth': 'bearer',
  };
  print('HTTP params: $httpParams');
}

// ---------------------------------------------------------------------------
// 7. Performance note
// ---------------------------------------------------------------------------
// Spreads are EAGER — they create a new collection and copy all elements.
// This is O(n) in total element count — NOT lazy like Iterable chains.
//
// For large or frequently rebuilt collections, consider:
//   • Caching the built list and only rebuilding when inputs change.
//   • Using Iterable operators (which ARE lazy) and only calling toList()
//     once at the end.
//   • In Flutter: const constructors where possible to avoid rebuilds.
void performanceNote() {
  print('\n--- performance note ---');

  // This creates a new list every call (O(n)):
  List<int> buildList(List<int> a, List<int> b) => [...a, ...b];

  // Lazy alternative — no copy until terminal op:
  Iterable<int> lazyMerge(Iterable<int> a, Iterable<int> b) =>
      a.followedBy(b); // Iterable.followedBy is lazy

  final a = List.generate(100000, (i) => i);
  final b = List.generate(100000, (i) => i);

  // Eager: allocates 200,000 element list immediately.
  final eager = buildList(a, b);

  // Lazy: no allocation until you iterate.
  final lazy = lazyMerge(a, b);

  print('eager length: ${eager.length}');  // forces the copy but already done
  print('lazy first 3: ${lazy.take(3).toList()}'); // only 3 elements evaluated
}

// ---------------------------------------------------------------------------
// 8. Practical pattern: building dynamic widget trees (Flutter simulation)
// ---------------------------------------------------------------------------
// In Flutter, Column/Row/ListView take children: List<Widget>.
// Spreads + collection-if/for replace verbose conditional add() calls.

// Simulated widget classes (pure Dart stand-ins):
class Widget {
  final String type;
  final String? label;
  const Widget(this.type, [this.label]);
  @override
  String toString() => label != null ? '$type("$label")' : type;
}

List<Widget> buildChildren({
  required String title,
  required bool showSubtitle,
  required List<String> items,
  bool isLoggedIn = false,
}) {
  return [
    Widget('Text', title),                             // always present
    if (showSubtitle) Widget('Text', 'Subtitle'),       // conditional
    Widget('Divider'),
    for (final item in items) Widget('ListTile', item), // loop
    Widget('Divider'),
    if (isLoggedIn) ...[                                // multi-widget block
      Widget('ProfileAvatar'),
      Widget('LogoutButton'),
    ] else
      Widget('LoginButton'),
  ];
}

void widgetTreeDemo() {
  print('\n--- dynamic widget tree (Flutter pattern) ---');

  final children = buildChildren(
    title: 'My App',
    showSubtitle: true,
    items: ['Item A', 'Item B', 'Item C'],
    isLoggedIn: true,
  );

  for (final w in children) print('  $w');
}

// ---------------------------------------------------------------------------
// 9. Building query params map pattern
// ---------------------------------------------------------------------------
Map<String, String> buildQueryParams({
  int page = 1,
  int limit = 20,
  String? search,
  List<String>? tags,
  bool activeOnly = false,
  Map<String, String>? extraFilters,
}) {
  return {
    'page': '$page',
    'limit': '$limit',
    if (search != null) 'search': search,
    if (activeOnly) 'status': 'active',
    if (tags != null)
      for (var i = 0; i < tags.length; i++) 'tags[$i]': tags[i],
    ...?extraFilters,
  };
}

void queryParamsDemo() {
  print('\n--- query params builder ---');

  final params = buildQueryParams(
    page: 2,
    search: 'dart',
    tags: ['async', 'streams'],
    activeOnly: true,
    extraFilters: {'sort': 'relevance'},
  );

  params.forEach((k, v) => print('  $k=$v'));
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------
void main() {
  spreadBasicsDemo();
  nullAwareSpreadDemo();
  collectionIfDemo();
  collectionForDemo();
  combinedDemo();
  mapSpreadDemo();
  performanceNote();
  widgetTreeDemo();
  queryParamsDemo();
}
