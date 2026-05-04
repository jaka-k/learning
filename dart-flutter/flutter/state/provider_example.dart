// =============================================================================
// PROVIDER PACKAGE — STATE MANAGEMENT
// =============================================================================
// NOTE: This file is NOT runnable standalone. It requires a Flutter project
// with the Provider package. Add to pubspec.yaml:
//   dependencies:
//     provider: ^6.1.0
//
// Provider is a wrapper around InheritedWidget that makes it significantly
// easier to work with. It handles the StatefulWidget+InheritedWidget boilerplate
// and provides optimized rebuild mechanisms like `select`.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// =============================================================================
// PART 1: ChangeNotifier — The Core Reactive Primitive
// =============================================================================

// ChangeNotifier is a simple observable class from the Flutter framework
// (no Provider dependency needed). It maintains a list of listeners and
// notifies them when data changes.
//
// Pattern: extend ChangeNotifier in your "model" or "view model" class.
// Call `notifyListeners()` whenever state changes that should trigger UI rebuilds.
//
// The class holds the data AND the mutation logic.
// This is the ViewModel in MVVM terminology.

class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  // Immutable update — return a new CartItem with changed quantity
  CartItem copyWith({int? quantity}) => CartItem(
    id: id,
    name: name,
    price: price,
    quantity: quantity ?? this.quantity,
  );
}

class CartModel extends ChangeNotifier {
  // Private mutable state
  final List<CartItem> _items = [];

  // Public read-only view of the state
  // Returns an unmodifiable list to prevent accidental external mutation
  List<CartItem> get items => List.unmodifiable(_items);

  // Computed properties — derived from state, no need to cache unless expensive
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(
    0.0,
    (sum, item) => sum + (item.price * item.quantity),
  );

  bool get isEmpty => _items.isEmpty;

  // Mutation methods — all call notifyListeners() to trigger UI updates
  void addItem(CartItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index >= 0) {
      // Item already in cart — increase quantity
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
    notifyListeners(); // This is the magic — tells all listeners to rebuild
    // Internally, ChangeNotifier calls every registered listener function.
    // Provider registers itself as a listener and triggers widget rebuilds.
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id); // Delegate to removeItem which also calls notifyListeners
      return; // Don't call notifyListeners twice
    }
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Example: ASYNC mutation
  // You can do async work before calling notifyListeners.
  // The UI stays in the old state until notifyListeners is called.
  Future<void> submitOrder() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    // After the await, clear the cart and notify
    _items.clear();
    notifyListeners(); // This is still safe — ChangeNotifier doesn't care about async
  }
}

// =============================================================================
// PART 2: A Second Model for MultiProvider Example
// =============================================================================

class UserModel extends ChangeNotifier {
  String _name = 'Guest';
  bool _isPremium = false;

  String get name => _name;
  bool get isPremium => _isPremium;

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void upgradeToPremium() {
    _isPremium = true;
    notifyListeners();
  }
}

// =============================================================================
// PART 3: ChangeNotifierProvider — Placing the Model in the Tree
// =============================================================================

// ChangeNotifierProvider does three things:
//   1. Creates the ChangeNotifier (via the `create` callback)
//   2. Puts it in an InheritedWidget so all descendants can access it
//   3. Automatically calls `dispose()` on the ChangeNotifier when the
//      provider is removed from the tree
//
// The `create` callback receives the BuildContext and should return the
// ChangeNotifier. It's called LAZILY (only when first accessed), unless
// `lazy: false` is specified.

class CartApp extends StatelessWidget {
  const CartApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Place providers HIGH in the tree — typically at or near the root.
    // Any descendant can now access CartModel and UserModel.
    return MultiProvider(
      // MultiProvider is syntactic sugar for nesting multiple providers.
      // It's equivalent to:
      //   ChangeNotifierProvider(
      //     create: (_) => CartModel(),
      //     child: ChangeNotifierProvider(
      //       create: (_) => UserModel(),
      //       child: ...,
      //     ),
      //   )
      providers: [
        ChangeNotifierProvider<CartModel>(
          create: (_) => CartModel(), // Create fresh model here
          // `_` is the context — rarely needed in `create`, so we use `_`
        ),
        ChangeNotifierProvider<UserModel>(
          create: (_) => UserModel(),
        ),
      ],
      child: MaterialApp(
        home: const CartScreen(),
      ),
    );
  }
}

// =============================================================================
// PART 4: context.watch, context.read, context.select
// =============================================================================

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch<T>() — REGISTERS A DEPENDENCY.
    // Every time CartModel calls notifyListeners(), this widget rebuilds.
    // Use in build() to display data that should stay in sync with the model.
    //
    // Under the hood: context.watch<T>() is equivalent to
    // context.dependOnInheritedWidgetOfExactType<InheritedProvider<T>>()!.value
    // It registers the widget as a listener on the ChangeNotifier.
    final cart = context.watch<CartModel>();

    // WARNING: Do NOT call context.watch conditionally:
    //   if (someCondition) context.watch<CartModel>(); // BAD
    //   final x = context.watch<CartModel>(); // GOOD — always at top of build
    // Conditional watch breaks Provider's subscription tracking.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          // CartBadge reads from cart — but we already have `cart` from watch above.
          // No need to watch again here.
          Badge(
            label: Text('${cart.itemCount}'),
            isLabelVisible: cart.itemCount > 0,
            child: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return CartItemTile(item: item);
              },
            ),
      bottomNavigationBar: const CartTotal(),
    );
  }
}

// CartTotal uses `select` for optimized rebuilds:
class CartTotal extends StatelessWidget {
  const CartTotal({super.key});

  @override
  Widget build(BuildContext context) {
    // context.select<T, R>() — REBUILDS ONLY WHEN THE SELECTED VALUE CHANGES.
    // The callback receives the model and returns a value to "watch."
    // This widget only rebuilds when `totalPrice` changes, even if other
    // parts of CartModel change (like item names, quantities of specific items).
    //
    // Prefer select over watch when you only care about a specific derived value.
    final total = context.select<CartModel, double>((cart) => cart.totalPrice);
    // Type annotation <CartModel, double>:
    //   CartModel = the type to select from
    //   double = the type of the selected value

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Total: \$${total.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text('\$${item.price.toStringAsFixed(2)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              // context.read<T>() — NO dependency registration. One-time access.
              // Use this in CALLBACKS (onPressed, onTap, etc.) where you want to
              // CALL METHODS on the model, not display data from it.
              //
              // NEVER use context.read<T>() in build() to display data — the
              // widget won't rebuild when the model changes.
              // ALWAYS use context.read<T>() in callbacks to avoid unnecessary rebuilds.
              context.read<CartModel>().updateQuantity(item.id, item.quantity - 1);
            },
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<CartModel>().updateQuantity(item.id, item.quantity + 1);
              // `read` here because we're in a callback, not in build.
              // We want to call the method, not observe changes.
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<CartModel>().removeItem(item.id),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PART 5: Consumer Widget — Alternative to context.watch
// =============================================================================

// Consumer<T> is functionally equivalent to calling context.watch<T>() in build.
// It's useful when:
//   1. You need a BuildContext that is a descendant of the provider
//      (similar to Builder, but also provides the model)
//   2. You want to scope the rebuild to a SUBTREE, leaving outer widgets stable
//      (performance optimization — only the Consumer rebuilds, not the parent)
//   3. Your provider is created in the same build() and the context can't see it yet

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    // The outer widget has other expensive widgets. We use Consumer to
    // scope the rebuild to JUST the summary text, not the whole card.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Order Summary',     // Static — never rebuilds
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),               // Static — never rebuilds
            Consumer<CartModel>(
              // Only this Consumer subtree rebuilds when CartModel changes.
              // The static widgets above are untouched.
              builder: (context, cart, child) {
                // `context` — a new BuildContext scoped to the Consumer
                // `cart`    — the CartModel (already watched, dependency registered)
                // `child`   — the pre-built child passed to Consumer (see below)
                return Column(
                  children: [
                    Text('Items: ${cart.itemCount}'),
                    Text('Total: \$${cart.totalPrice.toStringAsFixed(2)}'),
                    if (!cart.isEmpty)
                      TextButton(
                        onPressed: cart.clearCart,
                        // Note: `cart.clearCart` — we can reference the method
                        // directly because `cart` is already resolved from Consumer
                        child: const Text('Clear Cart'),
                      ),
                  ],
                );
              },
              // Optional: A `child` that is built ONCE and never rebuilt.
              // Passed to the builder as the third parameter.
              // Use for expensive static children within a Consumer.
              child: const Icon(Icons.shopping_bag, size: 48),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PART 6: ProxyProvider — Providers that Depend on Other Providers
// =============================================================================

// ProxyProvider creates a provider whose value depends on another provider.
// It rebuilds its value whenever the dependency changes.
//
// Use case: a CartService that needs a UserModel to know which user's cart to load.

class CartService {
  final UserModel user; // Depends on UserModel

  CartService({required this.user});

  String get greeting => 'Hello, ${user.name}! Your cart is ready.';
  bool get hasDiscount => user.isPremium;
}

// To wire this up with ProxyProvider:
class ProxyProviderExample extends StatelessWidget {
  const ProxyProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel()),

        // ProxyProvider<T, R>:
        //   T = the dependency provider type (UserModel)
        //   R = the type this provider produces (CartService)
        //
        // `update` is called whenever UserModel notifies changes.
        // `previous` is the previous CartService instance (or null first time).
        //   You can reuse it if the update is cheap and the service is stateful.
        ProxyProvider<UserModel, CartService>(
          update: (context, userModel, previousService) {
            // Create a new CartService with the updated UserModel
            return CartService(user: userModel);
            // Note: `previousService` is null on first build.
            // If CartService were expensive to create, you might reuse it:
            // return previousService ?? CartService(user: userModel);
          },
        ),
      ],
      child: const SizedBox(), // Your actual child widget
    );
  }
}

// =============================================================================
// PART 7: Summary — When to Use What
// =============================================================================
//
// context.watch<T>()        → Display data in build(). Registers dependency.
//                             Widget rebuilds on every notifyListeners() call.
//
// context.read<T>()         → Call methods in callbacks (onPressed, etc.).
//                             No dependency. No rebuild triggered.
//                             WRONG to use in build() for displaying data.
//
// context.select<T,R>()     → Display derived data where you want optimized rebuilds.
//                             Only rebuilds when the selected value changes (via ==).
//                             Best for expensive widgets that depend on one field.
//
// Consumer<T>               → Same as watch but scopes rebuild to the Consumer subtree.
//                             Use when you want to avoid rebuilding the parent.
//                             Also useful when BuildContext hierarchy requires it.
//
// ChangeNotifierProvider    → Single model at a specific tree position.
// MultiProvider             → Multiple models — syntactic sugar for nesting.
// ProxyProvider             → Model that depends on another provided value.
//
// GOLDEN RULE: The smaller the rebuilding scope, the better the performance.
// watch at a leaf node > watch at a screen widget > watch at app root.
