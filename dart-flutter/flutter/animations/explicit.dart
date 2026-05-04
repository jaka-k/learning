// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project. Covers explicit animations in depth.

// ============================================================
// WHAT ARE EXPLICIT ANIMATIONS?
// ============================================================
//
// In explicit animations YOU control the AnimationController:
//   • When to start / stop / reverse / repeat.
//   • Exact playback position (seek to any frame).
//   • Multiple tweens on a single controller (staggering).
//   • React to animation status (completed, dismissed, forward, reverse).
//
// The word "explicit" means you explicitly create, drive, and dispose the
// AnimationController — the framework does not do it for you.
//
// Use explicit when you need:
//   • Looping animations (spinning loader, pulsing button).
//   • Staggered / sequenced entry animations.
//   • Gesture-driven animations (drag to reveal).
//   • Animations that react to status changes.
//   • Precise control over playback (pause, seek).

import 'package:flutter/material.dart';

// ============================================================
// ANIMATIONCONTROLLER
// ============================================================
//
// AnimationController is a double that goes from 0.0 to 1.0 (by default)
// over a specified `duration`. It drives the animation clock.
//
// Key properties:
//   value      — current position (0.0–1.0 by default)
//   status     — AnimationStatus: forward, reverse, completed, dismissed
//   duration   — how long forward() takes
//   reverseDuration — how long reverse() takes (defaults to duration)
//   lowerBound — minimum value (default 0.0)
//   upperBound — maximum value (default 1.0)
//
// Key methods:
//   forward([from])  — play forward from current (or `from`) position
//   reverse([from])  — play backward
//   repeat([reverse: true]) — loop, optionally reversing each cycle
//   reset()          — set value to lowerBound without notifying
//   stop()           — stop playback
//   animateTo(target) — animate to an arbitrary value
//   fling()           — physics-based spring animation
//   dispose()         — ALWAYS dispose in State.dispose()!
//
// vsync: the TickerProvider. It pauses the ticker when the widget is
// off-screen (tab hidden, app in background), saving CPU/GPU.
// Use SingleTickerProviderStateMixin for one controller,
// TickerProviderStateMixin for multiple controllers in the same State.

// ============================================================
// SINGLETICKERPROVIDERSTATEMIXIN vs TICKERPROVIDERSTATEMIXIN
// ============================================================
//
// SingleTickerProviderStateMixin:
//   • The State itself IS the Ticker provider.
//   • Only one controller may call vsync: this.
//   • Slightly more efficient (no list overhead).
//
// TickerProviderStateMixin:
//   • Also makes the State a Ticker provider.
//   • Supports any number of controllers calling vsync: this.
//   • Required when you have 2+ controllers in the same State class.
//
// Common mistake: using SingleTicker but creating two controllers →
// throws "AnimationController.vsync was called more than once" in debug.

// ============================================================
// TWEEN AND ANIMATING VALUES
// ============================================================
//
// Tween<T>(begin, end).animate(controller) returns an Animation<T>
// whose value interpolates between begin and end as controller goes 0→1.
//
// The Animation<T> is READ-ONLY. You read .value in your build method.
//
// Common tweens: Tween<double>, ColorTween, SizeTween, RectTween,
// IntTween, StepTween (rounds to int), ConstantTween.

// ============================================================
// CURVEDANIMATION — non-linear easing
// ============================================================
//
// CurvedAnimation wraps a controller and applies a Curve.
// The resulting animation goes from 0→1 but with non-linear timing.
//
// Chain:
//   controller → CurvedAnimation(curve: Curves.easeOut) → Tween.animate()
//
// Important: CurvedAnimation is itself an Animation<double>, so you can
// pass it directly to Tween.animate().

// ============================================================
// ANIMATEDBUILDER — the efficient way to use explicit animations
// ============================================================
//
// Problem: If you add a listener to the controller and call setState(),
// the ENTIRE widget tree under your State rebuilds every frame (60–120 fps).
//
// Solution: AnimatedBuilder takes the animation and a builder function.
// Only the subtree returned by builder() rebuilds each frame.
// Pass the static part of the tree as `child` to avoid rebuilding it.
//
// Structure:
//   AnimatedBuilder(
//     animation: controller,     // or any Listenable
//     child: MyExpensiveWidget(), // built once
//     builder: (context, child) {
//       // called ~60 fps; only this subtree rebuilds
//       return Transform.rotate(
//         angle: controller.value * 2 * pi,
//         child: child, // reused each frame
//       );
//     },
//   )
//
// AnimatedWidget is an alternative: subclass it and call super(listenable:)
// to avoid the separate StatefulWidget boilerplate. AnimatedBuilder is more
// convenient for one-off cases; AnimatedWidget for reusable animated widgets.

// ============================================================
// ADDLISTENER — when you need the value without rebuilding
// ============================================================
//
// Sometimes you want to READ the animated value but NOT trigger a build.
// Example: update a variable, write to a stream, or call a platform channel.
//
// Use addListener for side effects, addStatusListener for status changes.
// Remember to call removeListener in dispose().

// ============================================================
// PRACTICAL EXAMPLE 1 — Rotating & Scaling Button
// ============================================================

class RotatingScalingButton extends StatefulWidget {
  const RotatingScalingButton({super.key});
  @override
  State<RotatingScalingButton> createState() =>
      _RotatingScalingButtonState();
}

class _RotatingScalingButtonState extends State<RotatingScalingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animations are derived from the same controller.
  late final Animation<double> _rotationAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // CurvedAnimation applies easing to the raw 0→1 controller value.
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      // reverseCurve: applied when the controller runs in reverse.
      // If omitted, the forward curve is used reversed.
      reverseCurve: Curves.easeIn,
    );

    // Tween.animate() produces an Animation<double> driven by `curved`.
    _rotationAnim = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(curved);
    _scaleAnim    = Tween<double>(begin: 1.0, end: 1.5).animate(curved);

    // addStatusListener — react when the animation fully completes.
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Auto-reverse after completion.
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // ALWAYS dispose; prevents timer leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller, // listens to both _rotationAnim and _scaleAnim
                               // (they all share the same controller)
      // child is built ONCE, not on every animation frame.
      child: ElevatedButton(
        onPressed: () {
          if (_controller.status == AnimationStatus.dismissed) {
            _controller.forward();
          }
        },
        child: const Text('Spin me'),
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotationAnim.value,
            child: child, // the pre-built ElevatedButton
          ),
        );
      },
    );
  }
}

// ============================================================
// CHAINING — AnimationController.drive() and Tween.chain()
// ============================================================
//
// drive() is the reverse of animate():
//   tween.animate(controller)  ==  controller.drive(tween)
//
// chain() applies a CurveTween ON TOP of a Tween. This lets you attach
// a curve without a separate CurvedAnimation variable.
//
// Both produce an Animation<T> from the controller.

void chainingExample(AnimationController controller) {
  // Traditional style:
  final curvedController = CurvedAnimation(
    parent: controller,
    curve: Curves.easeOut,
  );
  final animA = Tween<double>(begin: 0, end: 100).animate(curvedController);

  // Chain style (same result, no intermediate variable):
  final animB = controller.drive(
    Tween<double>(begin: 0, end: 100).chain(
      CurveTween(curve: Curves.easeOut),
    ),
  );

  // animA.value == animB.value at every frame.
  _ = animA; _ = animB; // suppress unused warnings
}

// ============================================================
// STAGGERED ANIMATIONS — multiple tweens with Interval curve
// ============================================================
//
// A staggered animation plays multiple sub-animations sequentially (or with
// overlap) on a single AnimationController.
//
// Interval(begin, end, curve: innerCurve):
//   • begin and end are fractions of the controller's 0.0–1.0 range.
//   • The inner tween only animates during that interval.
//   • Before `begin` the value is at tween.begin.
//   • After `end` the value is at tween.end.
//
// This pattern is preferred over multiple controllers because:
//   • Single controller to start/stop/dispose.
//   • Easy to adjust relative timing without changing durations.

class StaggeredListEntry extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggeredListEntry({super.key, required this.index, required this.child});

  @override
  State<StaggeredListEntry> createState() => _StaggeredListEntryState();
}

class _StaggeredListEntryState extends State<StaggeredListEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Each item starts its animation at a slightly different offset,
    // creating a cascading stagger effect.
    // index 0 starts at 0.0, index 1 at 0.1, etc. (capped at some max).
    final staggerStart = (widget.index * 0.1).clamp(0.0, 0.5);
    final staggerEnd   = (staggerStart + 0.5).clamp(0.0, 1.0);

    // Fade: plays during [staggerStart .. staggerEnd]
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(staggerStart, staggerEnd, curve: Curves.easeOut),
      ),
    );

    // Slide: plays during the same window but with a different inner curve.
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(staggerStart, staggerEnd, curve: Curves.easeOutCubic),
      ),
    );

    // Start the animation automatically when the widget is built.
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child, // built once
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            // SlideTransition uses fractional offsets (not pixels).
            // Offset(0, 0.3) means slide down by 30% of the widget's height.
            position: _slideAnim,
            child: child,
          ),
        );
      },
    );
  }
}

// ============================================================
// FadeTransition / SlideTransition / ScaleTransition / RotationTransition
// ============================================================
//
// These are pre-built AnimatedWidget subclasses that efficiently animate a
// single visual property using an Animation<double> (or Animation<Offset>).
//
// They are more efficient than AnimatedBuilder + Transform because
// FadeTransition / SlideTransition / ScaleTransition operate at the
// RENDER LAYER level — they don't call build() at all; they update the
// render object directly. Use these when possible.
//
// FadeTransition(opacity: animation, child: ...)
// SlideTransition(position: Tween<Offset>.animate(c), child: ...)
// ScaleTransition(scale: animation, child: ...)
// RotationTransition(turns: animation, child: ...)  — `turns` not radians!
// SizeTransition(sizeFactor: animation, child: ...)  — clips vertically/horizontally

// ============================================================
// PRACTICAL EXAMPLE 2 — Staggered List
// ============================================================

class StaggeredListDemo extends StatelessWidget {
  const StaggeredListDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const items = ['Apples', 'Bananas', 'Cherries', 'Dates', 'Elderberries'];
    return ListView(
      children: [
        for (int i = 0; i < items.length; i++)
          StaggeredListEntry(
            index: i,
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(items[i]),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// MULTIPLE CONTROLLERS — TickerProviderStateMixin
// ============================================================

class MultiControllerExample extends StatefulWidget {
  const MultiControllerExample({super.key});
  @override
  State<MultiControllerExample> createState() =>
      _MultiControllerExampleState();
}

// Use TickerProviderStateMixin (NOT SingleTicker) when you have 2+ controllers.
class _MultiControllerExampleState extends State<MultiControllerExample>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _colorController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this, // `this` is the TickerProvider
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // continuously pulse

    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // continuously cycle colors
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnim = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    final colorAnim = ColorTween(begin: Colors.blue, end: Colors.purple)
        .animate(_colorController);

    // AnimatedBuilder can listen to multiple animations by wrapping them
    // in a Listenable.merge().
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _colorController]),
      builder: (context, _) {
        return Transform.scale(
          scale: scaleAnim.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorAnim.value,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
