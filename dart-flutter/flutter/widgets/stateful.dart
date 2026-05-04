// =============================================================================
// STATEFUL WIDGETS
// =============================================================================
// NOTE: This file is NOT runnable standalone. It requires a Flutter project
// with the Flutter SDK configured. It is intended as a learning reference.
//
// StatefulWidget is for widgets that need to manage changing data over time —
// user interactions, timers, animations, and anything that requires a "rebuild
// on change." Flutter splits the widget into two classes: the widget (config)
// and the State (mutable data + lifecycle).
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';

// =============================================================================
// PART 1: Why Two Classes?
// =============================================================================

// Flutter separates StatefulWidget into two classes for a fundamental reason:
//
// WIDGETS ARE CHEAP AND DISPOSABLE.
// Flutter creates and discards widget objects constantly — every build() call
// in a parent creates new widget instances. Widget objects are like descriptions
// (blueprints), not the actual rendered objects.
//
// ELEMENTS AND STATE ARE EXPENSIVE AND PERSISTENT.
// The widget tree has a mirror tree of Elements. Each Element corresponds to
// a widget and persists across rebuilds. For StatefulWidgets, the Element holds
// onto the State object. When Flutter reconciles the tree and sees the same type
// at the same position, it REUSES the Element (and thus the State) and just
// updates its widget reference.
//
// So: State survives rebuilds. Widget doesn't. That's why they're two classes.

class CounterWidget extends StatefulWidget {
  // Fields here are the widget's *configuration* — what the parent passes in.
  // They're accessible inside State via `widget.initialCount`.
  final int initialCount;
  final String label;

  // const constructor is still valid on StatefulWidget (the widget part is
  // immutable even though the State part is mutable).
  const CounterWidget({
    super.key,
    this.initialCount = 0,
    this.label = 'Count',
  });

  // createState() is the factory that creates the State object.
  // Called exactly ONCE when this widget is first inserted into the tree.
  // Flutter will reuse the returned State object for the lifetime of the
  // element — even if the parent rebuilds and passes new configuration.
  //
  // The State type must be parameterized with this widget type:
  // State<CounterWidget>. This gives the State access to `widget` as type
  // CounterWidget (not just the base StatefulWidget class).
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

// The State class is conventionally named `_WidgetNameState` with a leading
// underscore (private to the library file). Users of CounterWidget don't need
// to know about or interact with its State class directly.
class _CounterWidgetState extends State<CounterWidget> {
  // Mutable state lives here as regular (non-final) instance fields.
  late int _count; // `late` because we initialize in initState, not the declaration

  // ==========================================================================
  // LIFECYCLE: initState
  // ==========================================================================
  // Called ONCE when the State is first created and inserted into the tree.
  // The widget is available via `widget` at this point.
  // The BuildContext is NOT fully set up yet — do NOT call
  // context.dependOnInheritedWidgetOfExactType (i.e., Theme.of, MediaQuery.of)
  // here. Those InheritedWidget lookups belong in didChangeDependencies or build.
  //
  // Use initState for:
  //   - Initializing state from widget properties
  //   - Creating controllers (TextEditingController, AnimationController, etc.)
  //   - Starting timers
  //   - Subscribing to streams or ChangeNotifiers
  //
  // ALWAYS call super.initState() first.
  @override
  void initState() {
    super.initState(); // Required — sets up the State machinery
    _count = widget.initialCount; // Access widget configuration here
  }

  // ==========================================================================
  // LIFECYCLE: didChangeDependencies
  // ==========================================================================
  // Called after initState AND whenever an InheritedWidget that this State
  // depends on changes. "Depends on" means build() (or any method called during
  // build) called `Theme.of(context)`, `MediaQuery.of(context)`, etc. on a
  // previous build — those calls register dependencies.
  //
  // Use didChangeDependencies for:
  //   - Initial setup that requires InheritedWidget data (safe to call Theme.of here)
  //   - Responding to InheritedWidget changes (e.g., locale changed, theme changed)
  //   - Starting a network request based on locale/theme data
  //
  // Called MORE often than initState (any InheritedWidget ancestor change triggers it).
  // Keep it efficient or guard with a flag.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies(); // Always call super first
    // Example: read a theme value and cache it if needed
    // final brightness = Theme.of(context).brightness;
    // This is safe here, unlike in initState.
  }

  // ==========================================================================
  // LIFECYCLE: build
  // ==========================================================================
  // Called every time setState() is called, or when the parent rebuilds and
  // passes new widget configuration, or when an InheritedWidget dependency changes.
  //
  // build() must be a PURE FUNCTION of state + widget + context:
  //   - No side effects
  //   - No async operations
  //   - Deterministic: same inputs → same output
  //   - Fast: called potentially 60+ times/second during animations
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${widget.label}: $_count'), // Access widget config via `widget.`
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _increment,
        ),
      ],
    );
  }

  // ==========================================================================
  // setState
  // ==========================================================================
  // setState() does TWO things:
  //   1. Runs the provided callback (where you mutate your state fields)
  //   2. Schedules a rebuild of this widget (marks the element dirty)
  //
  // Flutter batches dirty elements and rebuilds them in the next frame.
  // Calling setState multiple times in the same frame is fine — Flutter only
  // rebuilds once per frame per element.
  void _increment() {
    setState(() {
      // MUTATION happens inside the callback.
      // This is the ONLY place you should mutate state fields.
      _count++;
      // The callback is synchronous — no async work here.
      // Don't do: setState(() { await someAsyncCall(); }) — won't work as expected.
      // Don't do: setState(() { doSomethingExpensive(); }) — this is synchronous,
      //           it will block the UI thread.
    });
    // After setState returns, `_count` is updated and the rebuild is scheduled.
    // The rebuild hasn't happened yet — it will happen in the next frame.
  }

  // ==========================================================================
  // LIFECYCLE: didUpdateWidget
  // ==========================================================================
  // Called when the parent rebuilds and provides a NEW widget instance with
  // potentially different configuration, BUT Flutter determined it's the same
  // widget (same runtimeType and key). This is how you respond to parent
  // passing new props (similar to componentDidUpdate in React).
  //
  // `oldWidget` is the previous widget. `widget` is the new one.
  // This is NOT called during the first build (use initState for that).
  @override
  void didUpdateWidget(CounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget); // Always call super first
    // Example: if parent passes a new initialCount, reset our counter
    if (oldWidget.initialCount != widget.initialCount) {
      // Safe to call setState here — didUpdateWidget is part of the build cycle
      setState(() {
        _count = widget.initialCount;
      });
    }
    // Example: if a controller-type prop changed, swap out the old controller
    // if (oldWidget.controller != widget.controller) {
    //   _myController.dispose();
    //   _myController = widget.controller;  // or derive from it
    // }
  }

  // ==========================================================================
  // LIFECYCLE: deactivate
  // ==========================================================================
  // Called when this State is REMOVED from the tree (but might be reinserted).
  // This happens when:
  //   - The widget moves from one part of the tree to another (using GlobalKey)
  //   - The widget is temporarily removed (rare)
  //
  // In practice, deactivate is rarely overridden. It's the "halfway" lifecycle
  // step before dispose. If the widget is reinserted, initState is NOT called
  // again — didChangeDependencies is called instead.
  @override
  void deactivate() {
    super.deactivate(); // Always call super
    // Rarely need to override this
  }

  // ==========================================================================
  // LIFECYCLE: dispose
  // ==========================================================================
  // Called when this State is permanently removed from the tree and will
  // never rebuild again. This is where you MUST clean up resources.
  //
  // CRITICAL: Always dispose:
  //   - AnimationController         → controller.dispose()
  //   - TextEditingController       → controller.dispose()
  //   - ScrollController            → controller.dispose()
  //   - FocusNode                   → focusNode.dispose()
  //   - StreamSubscription          → subscription.cancel()
  //   - Timer                       → timer.cancel()
  //   - ChangeNotifier listeners    → notifier.removeListener(callback)
  //
  // Failure to dispose causes memory leaks and "setState called after dispose"
  // errors (which crash in debug mode and silently misbehave in release).
  @override
  void dispose() {
    // Clean up resources here
    // _controller.dispose();
    // _subscription.cancel();
    super.dispose(); // Always call super LAST in dispose()
  }
}

// =============================================================================
// PART 2: The `mounted` Check
// =============================================================================

// `mounted` is a bool property on State that is:
//   - true: after initState() and before dispose()
//   - false: after dispose() (or before initState in edge cases)
//
// The problem this solves: async operations started in initState (or callbacks)
// may complete AFTER the widget has been disposed. Calling setState after
// dispose throws an error (in debug mode) or silently fails (in release).

class DataFetcherWidget extends StatefulWidget {
  final String url;
  const DataFetcherWidget({super.key, required this.url});

  @override
  State<DataFetcherWidget> createState() => _DataFetcherWidgetState();
}

class _DataFetcherWidgetState extends State<DataFetcherWidget> {
  String? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Simulate an async operation (HTTP call, database query, etc.)
    try {
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      final result = 'Data from ${widget.url}';

      // IMPORTANT: Check `mounted` before calling setState after any await.
      // The user might have navigated away while the fetch was in progress,
      // causing this widget to be disposed. Without the check:
      //   - Debug mode: throws "setState() called after dispose()"
      //   - Release mode: silently does nothing but may still cause issues
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {  // Same check for error handling
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const CircularProgressIndicator();
    if (_error != null) return Text('Error: $_error');
    return Text(_data ?? 'No data');
  }
}

// =============================================================================
// PART 3: GlobalKey — Accessing State from Outside
// =============================================================================

// A GlobalKey is a key that uniquely identifies an element across the entire
// widget tree. It can be used to access the State of a StatefulWidget from
// outside that widget's subtree.
//
// Use cases:
//   - Calling methods on a State from a parent or sibling
//   - Accessing a Form's state to validate and save (FormState)
//   - Accessing a ScaffoldState to show a SnackBar
//   - Animating or scrolling from outside
//
// CAUTION: GlobalKeys are expensive. Flutter maintains a global registry of
// all GlobalKeys. Use them only when necessary. For most state-sharing needs,
// use state management (Provider, Riverpod, BLoC) or callbacks instead.

class ExpandablePanel extends StatefulWidget {
  final Widget header;
  final Widget body;

  const ExpandablePanel({
    super.key,
    required this.header,
    required this.body,
  });

  @override
  State<ExpandablePanel> createState() => ExpandablePanelState();
  // Note: NOT private (_ExpandablePanelState) because we want GlobalKey to
  // be able to access it. If the State class is private, GlobalKey access
  // can't see its public methods.
}

class ExpandablePanelState extends State<ExpandablePanel> {
  bool _isExpanded = false;

  // Public method that can be called via GlobalKey
  void expand() => setState(() => _isExpanded = true);
  void collapse() => setState(() => _isExpanded = false);
  void toggle() => setState(() => _isExpanded = !_isExpanded);
  bool get isExpanded => _isExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: toggle,
          child: widget.header,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.body,
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

// Using GlobalKey to control ExpandablePanel from outside:
class PanelController extends StatelessWidget {
  // Create the GlobalKey with the State type as the type parameter.
  // This gives you typed access to the State's public methods.
  final _panelKey = GlobalKey<ExpandablePanelState>();

  PanelController({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpandablePanel(
          key: _panelKey, // Attach the GlobalKey
          header: const Text('Click to expand'),
          body: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Hidden content'),
          ),
        ),
        // Control the panel from outside via the GlobalKey
        ElevatedButton(
          onPressed: () => _panelKey.currentState?.expand(),
          // `currentState` returns null if the widget isn't in the tree
          child: const Text('Expand from outside'),
        ),
        ElevatedButton(
          onPressed: () => _panelKey.currentState?.collapse(),
          child: const Text('Collapse from outside'),
        ),
      ],
    );
  }
}

// =============================================================================
// PART 4: Practical Example — Countdown Timer Widget
// =============================================================================

class CountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.onComplete,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer; // Nullable because we only create it after initState

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _startTimer();
  }

  void _startTimer() {
    // Timer.periodic fires the callback every [duration] until cancelled.
    // We store the Timer reference so we can cancel it in dispose().
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 0) {
        timer.cancel(); // Stop the timer
        // Check mounted before setState — timer fires on a different
        // schedule and might fire after dispose if we're not careful.
        if (mounted) {
          widget.onComplete?.call(); // `?.call()` safely calls nullable callbacks
        }
        return;
      }
      if (mounted) {
        setState(() => _remaining--);
      }
    });
  }

  void reset() {
    _timer?.cancel(); // Cancel existing timer before creating a new one
    setState(() {
      _remaining = widget.seconds;
    });
    _startTimer(); // Start fresh
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent passes a new `seconds` value, restart the timer
    if (oldWidget.seconds != widget.seconds) {
      _timer?.cancel();
      setState(() {
        _remaining = widget.seconds;
      });
      _startTimer();
    }
  }

  @override
  void dispose() {
    // CRITICAL: Cancel the timer. If we don't, it will keep firing even
    // after this widget is gone, calling setState on a disposed State object.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _remaining <= 10;
    return Text(
      '${_remaining}s',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isUrgent ? Colors.red : Colors.black,
      ),
    );
  }
}

// =============================================================================
// PART 5: Practical Example — Text Input with Validation
// =============================================================================

class EmailInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;  // ValueChanged<T> = void Function(T)

  const EmailInput({super.key, this.initialValue, this.onChanged});

  @override
  State<EmailInput> createState() => _EmailInputState();
}

class _EmailInputState extends State<EmailInput> {
  // TextEditingController: manages the text content and selection of a TextField.
  // MUST be disposed to free the underlying native text input resources.
  late final TextEditingController _controller;

  // FocusNode: manages keyboard focus. Lets you programmatically focus/unfocus
  // the field and listen for focus changes. MUST be disposed.
  late final FocusNode _focusNode;

  String? _errorText;
  bool _hasInteracted = false; // Don't show errors before user touches the field

  @override
  void initState() {
    super.initState();
    // Initialize controller with any pre-existing value
    _controller = TextEditingController(text: widget.initialValue);

    _focusNode = FocusNode();
    // Listen for focus changes to trigger validation when user leaves the field
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // When the user leaves the field (loses focus), mark as interacted
    // and validate. Before they interact, we don't want to show errors.
    if (!_focusNode.hasFocus && !_hasInteracted) {
      setState(() => _hasInteracted = true);
    }
    if (!_focusNode.hasFocus) {
      _validate(_controller.text);
    }
  }

  void _validate(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = 'Email is required';
      } else if (!RegExp(r'^[\w\-.]+@[\w\-]+\.\w+$').hasMatch(value)) {
        _errorText = 'Enter a valid email address';
      } else {
        _errorText = null; // Clear error
      }
    });
  }

  void _onChanged(String value) {
    // Validate on every keystroke (but only show error if user has interacted)
    if (_hasInteracted) {
      _validate(value);
    }
    // Bubble up the change to the parent
    widget.onChanged?.call(value);
  }

  @override
  void dispose() {
    // Remove the listener BEFORE disposing FocusNode to avoid calling
    // _onFocusChange on a disposed State.
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();     // Releases focus management resources
    _controller.dispose();    // Releases text editing resources (native layer)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'user@example.com',
        prefixIcon: const Icon(Icons.email_outlined),
        errorText: _hasInteracted ? _errorText : null,
        // Only show error after user has interacted (UX best practice)
      ),
    );
  }
}

// =============================================================================
// LIFECYCLE SUMMARY
// =============================================================================
//
// createState() ──► initState() ──► didChangeDependencies() ──► build()
//                                                                    │
//              ┌─────────────────────────────────────────────────────┘
//              ▼
//         [Parent rebuilds] ──► didUpdateWidget() ──► build()
//              │
//              │ [InheritedWidget changes]
//              └──────────────────────────► didChangeDependencies() ──► build()
//
//         [setState() called] ──► build()
//
//         [Widget removed] ──► deactivate() ──► dispose()
//
// Key points:
//   • initState: once, setup only, no InheritedWidget access
//   • didChangeDependencies: first build + InheritedWidget changes, safe for Theme.of etc.
//   • build: many times, pure function, no side effects
//   • didUpdateWidget: when parent passes new config, compare oldWidget vs widget
//   • dispose: once, ALWAYS clean up controllers/timers/streams/subscriptions
//   • mounted: check before setState in async callbacks
