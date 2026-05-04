// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project. Covers Flutter's constraint system in depth.

// ============================================================
// THE GOLDEN RULE OF FLUTTER LAYOUT
// ============================================================
//
//   "Constraints go DOWN, sizes go UP, parent sets POSITION."
//
// Every widget follows this protocol:
//   1. Parent passes a BoxConstraints to child via layout().
//   2. Child measures itself within those constraints and returns its size.
//   3. Parent decides where to place the child (its offset/position).
//
// Consequences:
//   • A widget can NEVER choose a size outside the constraints given to it.
//     Trying to do so causes a layout assertion in debug mode.
//   • A widget cannot know its own position — only its parent knows that.
//   • A widget cannot know the screen size directly (use MediaQuery instead).
//
// This protocol is applied recursively. Understanding it explains almost every
// mysterious layout behavior in Flutter.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // for MultiChildLayoutDelegate

// ============================================================
// BOXCONSTRAINTS
// ============================================================
//
// BoxConstraints is the concrete constraint type used by RenderBox (which
// underlies almost all Flutter widgets).
//
// Fields:
//   minWidth  — the smallest width the child is allowed to be
//   maxWidth  — the largest width the child is allowed to be
//   minHeight — the smallest height the child is allowed to be
//   maxHeight — the largest height the child is allowed to be
//
// A valid widget must choose:
//   minWidth  <= chosenWidth  <= maxWidth
//   minHeight <= chosenHeight <= maxHeight

void boxConstraintsConcepts() {
  // TIGHT constraints — minWidth == maxWidth (and/or minHeight == maxHeight).
  // The child has no choice: it must be exactly that size.
  // Example: Scaffold gives its body tight width (full screen width) but
  //          loose height.
  const tight = BoxConstraints.tight(Size(300, 200));
  // tight.minWidth == tight.maxWidth == 300
  // tight.minHeight == tight.maxHeight == 200
  assert(tight.isTight);

  // LOOSE constraints — minWidth == 0, minHeight == 0.
  // The child may be any size up to the max.
  // Example: Column gives its children loose constraints.
  const loose = BoxConstraints.loose(Size(300, 200));
  // loose.minWidth == 0, loose.maxWidth == 300
  // loose.minHeight == 0, loose.maxHeight == 200
  assert(!loose.isTight);

  // UNBOUNDED constraints — maxWidth == double.infinity and/or
  //                          maxHeight == double.infinity.
  // This happens when:
  //   • A ListView gives its children unbounded height so they can be
  //     as tall as they want (the list clips/scrolls).
  //   • A Row gives its children unbounded width (it lays them out and
  //     then clips or wraps).
  //   • You put a Column inside a Column without Expanded.
  const unboundedHeight = BoxConstraints(
    minWidth: 0,
    maxWidth: 400,
    minHeight: 0,
    maxHeight: double.infinity, // ← unbounded height
  );
  assert(unboundedHeight.hasBoundedHeight == false);

  // COMMON ERROR: placing a widget that tries to fill its parent
  // (e.g., a Container with no explicit size) inside an unbounded constraint.
  //
  // Container with no size in an unbounded dimension will shrink-wrap its
  // child, which may be fine. But if the child ALSO has no size... the
  // widget just collapses to zero, which is often a bug.
  //
  // The canonical crash: putting a Column inside a ListView without
  // giving the Column a bounded height.
  //
  //   ListView(
  //     children: [
  //       Column(   // ← Column is given unbounded height by ListView.
  //                 //   Column then gives unbounded height to its children.
  //                 //   If a child tries to fill its height → RenderFlex error.
  //         children: [
  //           Expanded(child: Text('boom')), // ← Expanded in unbounded space!
  //         ],
  //       ),
  //     ],
  //   )
  //
  // Fix: wrap Column in a SizedBox with explicit height, or use a
  // SliverList with SliverChildBuilderDelegate instead.
}

// ============================================================
// LAYOUTBUILDER — get parent constraints at build time
// ============================================================
//
// LayoutBuilder gives your builder function the BoxConstraints that the
// parent is providing. Use it for adaptive layouts: show different widgets
// depending on the available width.
//
// IMPORTANT: LayoutBuilder is called during layout, NOT just during build.
// This means it is more accurate than MediaQuery for nested widgets where
// the available space differs from the screen size.

class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // constraints.maxWidth is the width offered by the parent.
        if (constraints.maxWidth > 600) {
          return const _WideLayout();
        } else {
          return const _NarrowLayout();
        }
      },
    );
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout();
  @override
  Widget build(BuildContext context) => const Row(
        children: [
          Expanded(child: Placeholder()),
          Expanded(child: Placeholder()),
        ],
      );
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();
  @override
  Widget build(BuildContext context) =>
      const Column(children: [Placeholder(), Placeholder()]);
}

// ============================================================
// INTRINSICWIDTH / INTRINSICHEIGHT
// ============================================================
//
// These widgets measure their child twice: once to find its "intrinsic"
// (natural) size in the constrained dimension, and again to lay it out.
//
// Use case: make a Column of buttons all the same width as the widest one.
//
//   IntrinsicWidth(
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         ElevatedButton(onPressed: () {}, child: Text('Short')),
//         ElevatedButton(onPressed: () {}, child: Text('Much longer label')),
//       ],
//     ),
//   )
//
// PERFORMANCE WARNING: IntrinsicWidth/Height perform an O(n²) layout pass.
// Every descendant that participates in the intrinsic measurement is laid
// out twice. Avoid them in large or frequently-rebuilt subtrees.
// Consider explicit SizedBox / ConstrainedBox as alternatives.

Widget intrinsicExample() {
  return IntrinsicWidth(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // stretch to intrinsic width
      children: [
        ElevatedButton(onPressed: () {}, child: const Text('Short')),
        ElevatedButton(onPressed: () {}, child: const Text('Much longer label')),
      ],
    ),
  );
}

// ============================================================
// SIZING WIDGETS
// ============================================================

Widget sizingExamples() {
  return Column(
    children: [
      // SizedBox — sets a tight constraint (exact size).
      // Also useful as invisible spacing: SizedBox(height: 16)
      const SizedBox(width: 100, height: 50, child: Placeholder()),

      // SizedBox.expand — sets tight constraint to match parent exactly.
      // Equivalent to setting width/height to double.infinity inside
      // a bounded parent.
      const SizedBox.expand(child: Placeholder()),

      // ConstrainedBox — adds constraints ON TOP of what the parent provides.
      // The effective constraint is the intersection of parent and additional.
      // Use when you want a minimum or maximum size but still allow flexibility.
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 100,
          maxWidth: 300,
          minHeight: 40,
        ),
        child: const Text('I am at least 100px wide and 40px tall'),
      ),

      // FractionallySizedBox — sizes child as a fraction of the parent's size.
      // widthFactor: 0.5 → child is 50% of parent width.
      // Can also be used without a child to create fractional-sized space.
      FractionallySizedBox(
        widthFactor: 0.5,
        heightFactor: 0.25,
        child: Container(color: Colors.blue),
      ),

      // UnconstrainedBox — removes constraints before passing them to child.
      // The child can be its natural (intrinsic) size, even larger than parent.
      // If the child exceeds the UnconstrainedBox's own size, it clips by default
      // (add clipBehavior: Clip.none to overflow visibly — will show a warning).
      //
      // Use cases:
      //   • Rendering a fixed-size widget inside a constrained parent without
      //     stretching it.
      //   • Debugging layout issues (see what size a widget wants to be).
      const UnconstrainedBox(
        child: SizedBox(width: 5000, height: 10), // 5000px wide — will clip!
      ),
    ],
  );
}

// ============================================================
// WHY EXPANDED AND FLEXIBLE ONLY WORK INSIDE ROW/COLUMN/FLEX
// ============================================================
//
// Expanded and Flexible are not general sizing widgets — they are instructions
// TO the Flex layout algorithm. They use the Flex-specific layout protocol:
//
//   1. Flex first lays out all non-Flexible/Expanded children (to get their
//      "natural" sizes).
//   2. It calculates remaining space.
//   3. It distributes remaining space among Flexible/Expanded children
//      according to their `flex` factor.
//
// If you place Expanded outside a Flex (e.g., directly in a Stack or Center),
// the Expanded's RenderObject will not find a RenderFlex ancestor and will
// throw: "RenderFlex children have non-zero flex but incoming height
// constraints are unbounded."
//
// Flexible vs Expanded:
//   • Expanded is shorthand for Flexible(fit: FlexFit.tight, ...).
//     The child MUST fill the allocated flex space.
//   • Flexible(fit: FlexFit.loose) gives the child UP TO the flex space
//     but lets it be smaller (child sizes itself).

Widget flexExample() {
  return Row(
    children: [
      // This child takes exactly 2/3 of available width (tight fit).
      const Expanded(flex: 2, child: Placeholder()),
      // This child can be UP TO 1/3 of available width (loose fit).
      Flexible(flex: 1, fit: FlexFit.loose, child: Container(width: 30)),
      // A fixed-size child — doesn't participate in flex distribution.
      const SizedBox(width: 50, child: Placeholder()),
    ],
  );
}

// ============================================================
// OVERFLOW, CLIPRECT, CLIPRRECT
// ============================================================
//
// When a child is larger than its parent, RenderFlex logs a yellow-black
// overflow stripe in debug mode. There are two approaches:
//   A) Fix the layout so content fits (preferred).
//   B) Clip the overflow.

Widget overflowExamples() {
  return Column(
    children: [
      // ClipRect — clips child to its own bounding box (rectangle).
      // Use on any widget that might overflow, especially with animations.
      ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 0.5, // only show the top half of the child
          child: Container(width: 200, height: 200, color: Colors.red),
        ),
      ),

      // ClipRRect — same as ClipRect but with rounded corners.
      // Commonly used for rounded avatar images.
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network('https://picsum.photos/200'),
      ),

      // ClipOval — clips to an ellipse (useful for circular avatars).
      ClipOval(
        child: Container(width: 80, height: 80, color: Colors.green),
      ),

      // OverflowBox — deliberately allows child to be larger than parent.
      // The parent clips at its own bounds. The child paints outside if
      // no clip ancestor intercepts.
      // GOTCHA: OverflowBox can cause visually confusing overlaps.
      OverflowBox(
        maxWidth: 500,   // allow child to be 500px wide even if parent is smaller
        maxHeight: 500,
        child: Container(width: 500, height: 100, color: Colors.orange),
      ),
    ],
  );
}

// ============================================================
// CUSTOMSINGLECHILD LAYOUT
// ============================================================
//
// CustomSingleChildLayout delegates size and position decisions to a
// SingleChildLayoutDelegate. Use it when you need custom positioning logic
// that ConstrainedBox/Align/Padding cannot express.
//
// Contrast with CustomMultiChildLayout for multiple children.

class _CenteredWithOffsetDelegate extends SingleChildLayoutDelegate {
  final Offset offset;
  const _CenteredWithOffsetDelegate(this.offset);

  @override
  Size getSize(BoxConstraints constraints) {
    // The size WE want to be (the outer box).
    return constraints.biggest; // fill available space
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Constraints we pass DOWN to the child.
    return constraints.loosen(); // child can be any size up to parent
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // `size` is our own size. `childSize` is what the child chose.
    // Return the top-left offset for the child.
    return Offset(
      (size.width - childSize.width) / 2 + offset.dx,
      (size.height - childSize.height) / 2 + offset.dy,
    );
  }

  @override
  bool shouldRelayout(_CenteredWithOffsetDelegate oldDelegate) {
    return oldDelegate.offset != offset;
  }
}

Widget customSingleChildExample() {
  return CustomSingleChildLayout(
    delegate: const _CenteredWithOffsetDelegate(Offset(20, 10)),
    child: const Text('Offset-centered text'),
  );
}

// ============================================================
// CUSTOMMULTICHILD LAYOUT
// ============================================================
//
// CustomMultiChildLayout lays out multiple named children with full control
// over each child's constraints and position.
//
// Each child must be wrapped in LayoutId to give it an ID.
// The delegate references children by that ID.

enum _PanelId { header, body, footer }

class _ThreePanelDelegate extends MultiChildLayoutDelegate {
  final double headerHeight;
  final double footerHeight;

  _ThreePanelDelegate({
    required this.headerHeight,
    required this.footerHeight,
  });

  @override
  void performLayout(Size size) {
    // Lay out header — tight width, fixed height.
    if (hasChild(_PanelId.header)) {
      layoutChild(
        _PanelId.header,
        BoxConstraints.tightFor(width: size.width, height: headerHeight),
      );
      positionChild(_PanelId.header, Offset.zero);
    }

    // Lay out footer — tight width, fixed height, pinned to bottom.
    if (hasChild(_PanelId.footer)) {
      layoutChild(
        _PanelId.footer,
        BoxConstraints.tightFor(width: size.width, height: footerHeight),
      );
      positionChild(_PanelId.footer, Offset(0, size.height - footerHeight));
    }

    // Lay out body — fills remaining space.
    if (hasChild(_PanelId.body)) {
      final bodyHeight = size.height - headerHeight - footerHeight;
      layoutChild(
        _PanelId.body,
        BoxConstraints.tightFor(width: size.width, height: bodyHeight),
      );
      positionChild(_PanelId.body, Offset(0, headerHeight));
    }
  }

  @override
  bool shouldRelayout(_ThreePanelDelegate old) {
    return old.headerHeight != headerHeight || old.footerHeight != footerHeight;
  }
}

Widget customMultiChildExample() {
  return CustomMultiChildLayout(
    delegate: _ThreePanelDelegate(headerHeight: 60, footerHeight: 50),
    children: [
      LayoutId(
        id: _PanelId.header,
        child: Container(color: Colors.blue, child: const Text('Header')),
      ),
      LayoutId(
        id: _PanelId.body,
        child: Container(color: Colors.white, child: const Text('Body')),
      ),
      LayoutId(
        id: _PanelId.footer,
        child: Container(color: Colors.grey, child: const Text('Footer')),
      ),
    ],
  );
}
