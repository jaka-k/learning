// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project. Covers implicit animations in depth.

// ============================================================
// WHAT ARE IMPLICIT ANIMATIONS?
// ============================================================
//
// Implicit animations are the easiest animation mechanism in Flutter.
// You describe the DESIRED END STATE and Flutter automatically:
//   1. Detects that a property changed.
//   2. Creates an AnimationController internally (you never see it).
//   3. Interpolates from the old value to the new value over `duration`.
//
// The word "implicit" means the animation is implied by changing a property
// value — you do not manage the controller, tween, or tick loop yourself.
//
// All implicit animation widgets follow a naming pattern: Animated<Widget>.
// Their key properties are always:
//   duration  — how long the animation takes
//   curve     — the easing curve (default is Curves.linear)
//   onEnd     — callback when the animation finishes
//
// When to use implicit:
//   • Simple single-property transitions (show/hide, resize, move).
//   • No sequencing needed.
//   • No looping needed.
//   • No precise control over playback (play/pause/reverse).
//
// When NOT to use implicit:
//   • Looping animations (use explicit AnimationController.repeat()).
//   • Staggered sequences (use AnimationController + Interval).
//   • Animations driven by gestures (use explicit controller + value).
//   • You need to react to animation status (completed, dismissed).

import 'package:flutter/material.dart';

// ============================================================
// ANIMATEDCONTAINER — the most versatile implicit animation
// ============================================================
//
// AnimatedContainer animates ANY combination of these properties:
//   • width, height
//   • padding, margin
//   • decoration (color, borderRadius, boxShadow, gradient, border)
//   • alignment
//   • constraints
//   • transform
//
// It cannot animate widgets that are structurally different (e.g., swapping
// a Row for a Column). For widget-level changes, use AnimatedSwitcher.

class AnimatedContainerDemo extends StatefulWidget {
  const AnimatedContainerDemo({super.key});
  @override
  State<AnimatedContainerDemo> createState() => _AnimatedContainerDemoState();
}

class _AnimatedContainerDemoState extends State<AnimatedContainerDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        // `duration` is required — how long the animation plays.
        duration: const Duration(milliseconds: 400),
        // `curve` controls acceleration/deceleration.
        curve: Curves.easeInOut,

        // These properties animate smoothly between their old and new values.
        width: _expanded ? 300 : 150,
        height: _expanded ? 200 : 80,
        decoration: BoxDecoration(
          color: _expanded ? Colors.blue : Colors.orange,
          borderRadius: BorderRadius.circular(_expanded ? 24 : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_expanded ? 0.3 : 0.1),
              blurRadius: _expanded ? 16 : 4,
              offset: Offset(0, _expanded ? 8 : 2),
            ),
          ],
        ),
        alignment: _expanded ? Alignment.center : Alignment.topLeft,
        padding: EdgeInsets.all(_expanded ? 24 : 8),
        child: const Text('Tap me', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ============================================================
// ANIMATEDOPACITY, ANIMATEDPADDING, ANIMATEDPOSITIONED, ANIMATEDALIGN
// ============================================================
//
// Single-property variants. Useful when you only need to animate one thing
// and want to be explicit about it.

class SinglePropertyExamples extends StatefulWidget {
  const SinglePropertyExamples({super.key});
  @override
  State<SinglePropertyExamples> createState() => _SinglePropertyExamplesState();
}

class _SinglePropertyExamplesState extends State<SinglePropertyExamples> {
  bool _visible = true;
  double _topPadding = 0;
  Alignment _alignment = Alignment.topLeft;
  bool _left = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AnimatedOpacity — fade in/out.
        // GOTCHA: AnimatedOpacity still takes up layout space even at opacity 0.
        // To remove from layout, combine with AnimatedSwitcher or Visibility.
        AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: const Text('I fade!'),
        ),

        // AnimatedPadding — animates EdgeInsets.
        AnimatedPadding(
          padding: EdgeInsets.only(top: _topPadding),
          duration: const Duration(milliseconds: 500),
          curve: Curves.bounceOut,
          child: const Text('I bounce down'),
        ),

        // AnimatedAlign — animates alignment within a fixed-size container.
        SizedBox(
          width: double.infinity,
          height: 60,
          child: AnimatedAlign(
            alignment: _alignment,
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            child: const FlutterLogo(size: 40),
          ),
        ),

        // AnimatedPositioned — MUST be a direct child of a Stack.
        SizedBox(
          height: 100,
          child: Stack(
            children: [
              AnimatedPositioned(
                left: _left ? 200 : 0,
                top: 0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: Container(width: 50, height: 50, color: Colors.green),
              ),
            ],
          ),
        ),

        ElevatedButton(
          onPressed: () => setState(() {
            _visible = !_visible;
            _topPadding = _topPadding == 0 ? 30 : 0;
            _alignment = _alignment == Alignment.topLeft
                ? Alignment.bottomRight
                : Alignment.topLeft;
            _left = !_left;
          }),
          child: const Text('Toggle all'),
        ),
      ],
    );
  }
}

// ============================================================
// ANIMATEDSWITCHER — animate between two different WIDGETS
// ============================================================
//
// AnimatedSwitcher watches its `child` property. When the child widget
// changes (by key), it animates the old child out and the new child in.
//
// KEY POINT: Flutter identifies widget identity by type + key. If you swap
// two Text widgets without different keys, Flutter sees the "same" widget
// and won't animate. Always give different children different keys when
// you want AnimatedSwitcher to detect the change.

class AnimatedSwitcherDemo extends StatefulWidget {
  const AnimatedSwitcherDemo({super.key});
  @override
  State<AnimatedSwitcherDemo> createState() => _AnimatedSwitcherDemoState();
}

class _AnimatedSwitcherDemoState extends State<AnimatedSwitcherDemo> {
  int _count = 0;
  bool _showIcon = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          // transitionBuilder lets you customize the animation.
          // Default is FadeTransition. Here we use a scale+fade combo.
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          // layoutBuilder: controls how old and new widgets are laid out
          // during the transition. Default stacks them; you can customize.
          child: _showIcon
              ? const Icon(Icons.star, key: ValueKey('icon'), size: 60)
              : Text(
                  'Count: $_count',
                  // IMPORTANT: different key for each value so AnimatedSwitcher
                  // detects the change even when the widget type is the same.
                  key: ValueKey(_count),
                  style: const TextStyle(fontSize: 24),
                ),
        ),
        ElevatedButton(
          onPressed: () => setState(() {
            _showIcon = !_showIcon;
            _count++;
          }),
          child: const Text('Switch'),
        ),
      ],
    );
  }
}

// ============================================================
// ANIMATEDCROSSFADE — cross-fade between exactly two widget states
// ============================================================
//
// AnimatedCrossFade always keeps BOTH children in the tree (unlike
// AnimatedSwitcher which removes the old child after the animation).
// The non-active child is sized to zero but still built.
//
// Use when you want to cross-fade between two specific widgets,
// and both widgets are cheap to keep alive.

class AnimatedCrossFadeDemo extends StatefulWidget {
  const AnimatedCrossFadeDemo({super.key});
  @override
  State<AnimatedCrossFadeDemo> createState() => _AnimatedCrossFadeDemoState();
}

class _AnimatedCrossFadeDemoState extends State<AnimatedCrossFadeDemo> {
  bool _showFirst = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          firstChild: const FlutterLogo(size: 100),
          secondChild: const Icon(Icons.favorite, size: 100, color: Colors.red),
          // crossFadeState drives which child is shown.
          crossFadeState: _showFirst
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 500),
          // sizeCurve: curve for the height interpolation between the two
          // children's heights.
          sizeCurve: Curves.easeInOut,
        ),
        ElevatedButton(
          onPressed: () => setState(() => _showFirst = !_showFirst),
          child: const Text('Cross-fade'),
        ),
      ],
    );
  }
}

// ============================================================
// ANIMATEDSIZE — animate size changes of child widget
// ============================================================
//
// AnimatedSize watches when its child's size changes and smoothly
// interpolates between old and new sizes. Perfect for expand/collapse.
//
// GOTCHA: The child must be able to change size; it must not be in tight
// constraints. Wrap in an Align or Center if needed.

class AnimatedSizeDemo extends StatefulWidget {
  const AnimatedSizeDemo({super.key});
  @override
  State<AnimatedSizeDemo> createState() => _AnimatedSizeDemoState();
}

class _AnimatedSizeDemoState extends State<AnimatedSizeDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: Container(
            // When _expanded changes, AnimatedSize smoothly interpolates height.
            height: _expanded ? 200 : 60,
            width: 250,
            color: Colors.teal,
            child: const Center(child: Text('Tap to expand')),
          ),
        ),
        ElevatedButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: const Text('Toggle size'),
        ),
      ],
    );
  }
}

// ============================================================
// TWEENANIMATIONBUILDER — custom implicit animation for any value
// ============================================================
//
// TweenAnimationBuilder is the generic implicit animation. Use it when
// none of the Animated* widgets covers your property.
//
// How it works:
//   1. You provide a `tween` with a `begin` and `end` value.
//   2. When `end` changes, TweenAnimationBuilder animates from the
//      CURRENT animated value (not necessarily `begin`) to the new `end`.
//   3. The `builder` is called every frame with the interpolated value.
//
// Tween types:
//   Tween<double>      — generic numeric interpolation
//   ColorTween         — Color.lerp-based interpolation
//   SizeTween          — Size interpolation
//   RectTween          — Rect interpolation
//   BorderRadiusTween  — BorderRadius interpolation
//   AlignmentTween     — Alignment interpolation
//   Custom: extend Tween<T> and override lerp()

class TweenAnimationBuilderDemo extends StatefulWidget {
  const TweenAnimationBuilderDemo({super.key});
  @override
  State<TweenAnimationBuilderDemo> createState() =>
      _TweenAnimationBuilderDemoState();
}

class _TweenAnimationBuilderDemoState extends State<TweenAnimationBuilderDemo> {
  double _targetRotation = 0.0;
  Color _targetColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animating a double (rotation)
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _targetRotation),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value,
              // `child` is the optional pre-built subtree passed to builder.
              // It is NOT rebuilt on each animation frame — only Transform is.
              // Pass static children via `child:` for efficiency.
              child: child,
            );
          },
          child: const FlutterLogo(size: 80), // built once, not per-frame
        ),

        // Animating a Color
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: Colors.blue, end: _targetColor),
          duration: const Duration(milliseconds: 400),
          builder: (context, color, _) {
            return Container(
              width: 100,
              height: 50,
              color: color,
            );
          },
        ),

        ElevatedButton(
          onPressed: () => setState(() {
            _targetRotation += math_pi;
            _targetColor = _targetColor == Colors.blue ? Colors.red : Colors.blue;
          }),
          child: const Text('Animate'),
        ),
      ],
    );
  }
}

// pi is not available without dart:math, so inline it here.
const double math_pi = 3.141592653589793;

// ============================================================
// CURVES — common easing curves
// ============================================================
//
// Curves.linear          — constant speed (no easing)
// Curves.easeIn          — slow start, fast end
// Curves.easeOut         — fast start, slow end (most natural for UI)
// Curves.easeInOut       — slow start and end (smooth)
// Curves.elasticOut      — overshoots then settles (springy)
// Curves.elasticIn       — builds up momentum (less common in UI)
// Curves.bounceOut       — bounces at the end (playful)
// Curves.bounceIn        — bounces at the start
// Curves.fastOutSlowIn   — Material Design standard curve
// Curves.decelerate      — slows to a stop
//
// Custom curve: extend Curve and override transform(double t).
// Interval(begin, end, curve: innerCurve) — plays a curve in a sub-range of
//   0.0–1.0. Used for staggered animations (see explicit.dart).

class CustomCurveExample extends Curve {
  @override
  double transform(double t) {
    // `t` goes from 0.0 to 1.0 over the animation's duration.
    // Return the interpolated progress (also 0.0 to 1.0 for normal curves,
    // though you can overshoot for spring-like effects).
    //
    // This example: a simple stepped curve that snaps at 0.5.
    return t < 0.5 ? 0.0 : 1.0;
  }
}

// ============================================================
// PRACTICAL EXAMPLE — Expandable Card
// ============================================================
//
// Combines AnimatedContainer (height + color), AnimatedOpacity (detail text),
// and AnimatedRotation (chevron icon) into a polished expandable card.

class ExpandableCard extends StatefulWidget {
  final String title;
  final String detail;
  const ExpandableCard({super.key, required this.title, required this.detail});

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_open ? 0.15 : 0.05),
              blurRadius: _open ? 16 : 4,
              offset: Offset(0, _open ? 6 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  // AnimatedRotation rotates its child by turns (1.0 = full rotation).
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0.0, // 0.5 turns = 180°
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
              // AnimatedSize smoothly expands the height to reveal detail text.
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        // AnimatedOpacity fades in the text after the container expands.
                        child: AnimatedOpacity(
                          opacity: _open ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 250),
                          child: Text(widget.detail),
                        ),
                      )
                    : const SizedBox.shrink(), // zero-height placeholder when closed
              ),
            ],
          ),
        ),
      ),
    );
  }
}
