// NOT RUNNABLE STANDALONE — Flutter learning reference file.
// Requires a Flutter project. Covers CustomPainter and the Canvas API.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============================================================
// CUSTOMPAINT WIDGET
// ============================================================
//
// CustomPaint gives you a raw Canvas to draw on. It sits in the widget tree
// like any other widget; its size is determined by the normal constraint system.
//
// Parameters:
//   painter           — draws BEHIND the child widget
//   foregroundPainter — draws IN FRONT of the child widget
//   child             — optional widget rendered between painter and foreground
//   size              — explicit size (only used when there is no child;
//                       if there is a child, CustomPaint sizes to the child)
//   isComplex         — hint to the raster cache that this painting is
//                       expensive; Flutter may cache the result as a bitmap.
//   willChange        — hint that the painting will change frequently;
//                       disables raster caching for this widget.
//
// Use painter + child + foregroundPainter together to layer:
//   [painted background] → [child widget] → [painted overlay]

// ============================================================
// CUSTOMPAINTER BASE CLASS
// ============================================================
//
// Override two methods:
//   paint(Canvas canvas, Size size) — the actual drawing code.
//   shouldRepaint(oldDelegate)      — return true if the painting has changed.
//
// PERFORMANCE: shouldRepaint is called on every parent rebuild.
// Return false whenever nothing affecting the visual output has changed.
// Returning true unnecessarily causes extra rasterization work.

// ============================================================
// PRACTICAL EXAMPLE 1 — Progress Ring
// ============================================================

class ProgressRingPainter extends CustomPainter {
  final double progress;  // 0.0 → 1.0
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const ProgressRingPainter({
    required this.progress,
    this.trackColor = const Color(0xFFE0E0E0),
    this.progressColor = Colors.blue,
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // The center point and radius of the ring.
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // ---- PAINT OBJECT ----
    // Paint describes how to draw: color, stroke width, fill vs stroke, etc.
    // It is a mutable object — create a new one (or use ..cascade notation)
    // for each distinct drawing style.

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      // PaintingStyle.stroke → draw only the outline (no fill).
      // PaintingStyle.fill   → fill the shape (default).
      ..style = PaintingStyle.stroke
      // StrokeCap.round  → rounded line ends.
      // StrokeCap.butt   → flat line ends (default).
      // StrokeCap.square → square line ends (extend half strokeWidth beyond).
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // ---- DRAWING A FULL CIRCLE (the track) ----
    canvas.drawCircle(center, radius, trackPaint);

    // ---- DRAWING AN ARC (the progress) ----
    // drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter, Paint paint)
    // - startAngle is in radians; 0 = right (3 o'clock). -π/2 = top (12 o'clock).
    // - sweepAngle is in radians; positive = clockwise.
    // - useCenter: true connects the arc endpoints to the center (pie slice).
    //              false draws just the arc edge.
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,    // start at top
      sweepAngle,      // sweep clockwise by progress amount
      false,           // do NOT connect to center
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    // Only repaint if something actually changed.
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class ProgressRing extends StatelessWidget {
  final double progress;
  const ProgressRing({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 120),
      painter: ProgressRingPainter(progress: progress),
      // `child` is optional — could place a Text widget showing the percentage.
      child: Center(
        child: Text(
          '${(progress * 100).round()}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ============================================================
// CANVAS DRAWING OPERATIONS
// ============================================================

class DrawingCatalogPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2;

    // drawLine — a straight line between two Offsets.
    canvas.drawLine(
      const Offset(10, 10),
      Offset(size.width - 10, 10),
      paint,
    );

    // drawRect — axis-aligned rectangle.
    canvas.drawRect(
      Rect.fromLTWH(10, 30, 100, 60),
      paint,
    );

    // drawRRect — rounded rectangle.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(120, 30, 100, 60),
        const Radius.circular(12),
      ),
      paint,
    );

    // drawCircle — center + radius.
    canvas.drawCircle(const Offset(290, 60), 30, paint);

    // drawOval — ellipse inscribed in a Rect.
    canvas.drawOval(const Rect.fromLTWH(330, 30, 80, 60), paint);

    // ---- PATH API ----
    // For arbitrary shapes, build a Path and call canvas.drawPath().
    final path = Path()
      // moveTo — move the "pen" to a position without drawing.
      ..moveTo(10, 120)
      // lineTo — draw a straight line from current position to here.
      ..lineTo(60, 180)
      // quadraticBezierTo(cpX, cpY, endX, endY) — quadratic Bézier curve.
      ..quadraticBezierTo(110, 120, 160, 180)
      // cubicTo(cp1X, cp1Y, cp2X, cp2Y, endX, endY) — cubic Bézier.
      ..cubicTo(180, 120, 220, 180, 250, 120)
      // arcToPoint — arc to a point, optionally specifying the radius.
      ..arcToPoint(
        const Offset(320, 120),
        radius: const Radius.circular(40),
        clockwise: false,
      )
      // close — draws a line back to the first moveTo point.
      ..close();
    canvas.drawPath(path, paint..color = Colors.purple);

    // drawShadow — draws a Material-style drop shadow.
    canvas.drawShadow(path, Colors.black, 4.0, false);

    // drawImage — draws a dart:ui Image (obtained via ImageProvider.resolve).
    // Not shown here as it requires async image loading.
    // canvas.drawImage(image, offset, paint);

    // drawImageRect — draws a portion of an Image scaled to a target Rect.
    // canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(DrawingCatalogPainter old) => false;
}

// ============================================================
// PAINT — GRADIENTS (SHADER)
// ============================================================

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Apply a gradient by setting the shader on a Paint.
    // Shaders are created by Gradient.createShader(Rect bounds).

    // Linear gradient
    final linearPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.red, Colors.orange, Colors.yellow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width / 2 - 10, size.height), linearPaint);

    // Radial gradient
    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.blue, Colors.transparent],
        center: Alignment.center,
        radius: 0.5,
      ).createShader(Rect.fromLTWH(size.width / 2 + 10, 0, size.width / 2 - 10, size.height));
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 + 10, 0, size.width / 2 - 10, size.height),
      radialPaint,
    );
  }

  @override
  bool shouldRepaint(GradientPainter old) => false;
}

// ============================================================
// CANVAS TRANSFORMATIONS — save/restore, translate, rotate, scale
// ============================================================
//
// canvas.save()    — pushes the current transformation matrix onto a stack.
// canvas.restore() — pops and restores the previous matrix.
// Always pair save/restore! Unbalanced saves accumulate transforms.
//
// Use canvas.saveLayer(bounds, paint) when you need to apply an opacity or
// blend mode to a group of drawing operations. More expensive than save().

class TransformPainter extends CustomPainter {
  final double angle; // radians

  const TransformPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ---- Draw a static background element ----
    canvas.drawCircle(center, 10, Paint()..color = Colors.grey);

    // ---- Save state, then rotate and draw a "hand" ----
    canvas.save(); // push current transform

    // Translate to the center before rotating, so rotation is around center.
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle); // rotate by `angle` radians

    // Now draw at (0,0) which is actually `center` in the original space.
    canvas.drawRect(
      const Rect.fromLTWH(-3, -50, 6, 50),
      Paint()..color = Colors.red..style = PaintingStyle.fill,
    );

    canvas.restore(); // pop transform — subsequent draws are unaffected

    // canvas.scale(sx, sy) — scale the coordinate system.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(0.5, 0.5);
    canvas.drawRect(
      const Rect.fromLTWH(-30, -30, 60, 60),
      Paint()..color = Colors.blue.withOpacity(0.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(TransformPainter old) => old.angle != angle;
}

// ============================================================
// DRAWING TEXT — TextPainter
// ============================================================
//
// Canvas.drawParagraph uses the lower-level dart:ui Paragraph API.
// TextPainter is the higher-level Flutter wrapper; prefer it.

class TextPainterExample extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Create a TextSpan with style.
    const textSpan = TextSpan(
      text: 'Custom Canvas Text',
      style: TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );

    // 2. Create a TextPainter. textDirection is required.
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      // textAlign: TextAlign.center — only meaningful after layout.
    );

    // 3. Layout the text within the available width.
    //    After this call, textPainter.size is known.
    textPainter.layout(minWidth: 0, maxWidth: size.width);

    // 4. Paint at a specific offset.
    //    Here we center the text horizontally and vertically.
    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(TextPainterExample old) => false;
}

// ============================================================
// PRACTICAL EXAMPLE 2 — Simple Bar Chart
// ============================================================

class BarChartPainter extends CustomPainter {
  final List<double> values; // normalized 0.0–1.0
  final List<Color> colors;
  final double barSpacing;

  const BarChartPainter({
    required this.values,
    required this.colors,
    this.barSpacing = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final barCount = values.length;
    // Calculate bar width so all bars + spacing fit in the available width.
    final totalSpacing = barSpacing * (barCount - 1);
    final barWidth = (size.width - totalSpacing) / barCount;
    final maxBarHeight = size.height * 0.85; // leave 15% for labels

    for (int i = 0; i < barCount; i++) {
      final barHeight = values[i] * maxBarHeight;
      final left = i * (barWidth + barSpacing);
      final top = size.height - barHeight - 20; // 20px for labels

      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);

      // Bar fill
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = colors[i % colors.length],
      );

      // Value label above the bar
      final label = TextPainter(
        text: TextSpan(
          text: '${(values[i] * 100).round()}%',
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(left + (barWidth - label.width) / 2, top - label.height - 2),
      );
    }

    // X-axis line
    canvas.drawLine(
      Offset(0, size.height - 20),
      Offset(size.width, size.height - 20),
      Paint()..color = Colors.black26..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(BarChartPainter old) {
    return old.values != values || old.colors != colors;
  }
}

class BarChartWidget extends StatelessWidget {
  const BarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: BarChartPainter(
        values: const [0.4, 0.7, 0.5, 0.9, 0.3, 0.6],
        colors: [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.red,
          Colors.teal,
        ],
      ),
    );
  }
}

// ============================================================
// REPAINTBOUNDARY — isolate repaints
// ============================================================
//
// By default, a repaint propagates up the render tree until it hits a
// repaint boundary. Without explicit boundaries, a single animated
// CustomPaint can cause the entire screen to repaint on every frame.
//
// Wrap expensive or frequently-animating painters in RepaintBoundary
// to limit the repaint to just that widget's layer.
//
// Flutter DevTools → "Highlight Repaints" mode shows which areas repaint
// each frame — use it to verify your boundaries are effective.

class IsolatedAnimatedRing extends StatelessWidget {
  final double progress;
  const IsolatedAnimatedRing({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      // Everything inside this boundary repaints independently.
      // The surrounding widget tree is NOT repainted when progress changes.
      child: CustomPaint(
        size: const Size(120, 120),
        painter: ProgressRingPainter(progress: progress),
      ),
    );
  }
}
