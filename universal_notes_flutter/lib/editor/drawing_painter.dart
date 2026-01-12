import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/stroke.dart';

/// A painter that renders a list of strokes on the canvas.
class DrawingPainter extends CustomPainter {
  /// Creates a [DrawingPainter] with a list of [strokes].
  DrawingPainter(this.strokes);

  /// The list of strokes to paint.
  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      // If single point, draw a dot
      if (stroke.points.length == 1) {
        final point = stroke.points.first;
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.width * point.pressure
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.fill; // Dot is effectively a filled circle
        canvas.drawCircle(
          Offset(point.x, point.y),
          (stroke.width * point.pressure) / 2,
          paint,
        );
        continue;
      }

      // Check if we need variable pressure (any point has pressure != 1.0)
      final hasVariablePressure = stroke.points.any((p) => p.pressure != 1.0);

      if (!hasVariablePressure) {
        // Fast path: Use efficient Path with quadratic beziers
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        final path = Path()
          ..moveTo(stroke.points.first.x, stroke.points.first.y);

        for (var i = 0; i < stroke.points.length - 1; i++) {
          final p0 = stroke.points[i];
          final p1 = stroke.points[i + 1];
          // Midpoint
          final mX = (p0.x + p1.x) / 2;
          final mY = (p0.y + p1.y) / 2;
          path.quadraticBezierTo(p0.x, p0.y, mX, mY);
        }
        // Connect last point
        path.lineTo(stroke.points.last.x, stroke.points.last.y);

        canvas.drawPath(path, paint);
      } else {
        // Variable width path (slower but supports pressure)
        // Variable width path (slower but supports pressure)
        // We draw small segments. For better quality, we should calculate an
        // outline, but simple segments with Round Cap is a good start.
        for (var i = 0; i < stroke.points.length - 1; i++) {
          final p0 = stroke.points[i];
          final p1 = stroke.points[i + 1];

          final paint = Paint()
            ..color = stroke.color
            ..strokeWidth = stroke.width * ((p0.pressure + p1.pressure) / 2)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

          canvas.drawLine(Offset(p0.x, p0.y), Offset(p1.x, p1.y), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return true; // Optimize later check for deep equality or changed ref
  }
}
