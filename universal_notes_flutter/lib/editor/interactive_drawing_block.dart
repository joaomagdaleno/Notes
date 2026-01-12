import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/drawing_painter.dart';
import 'package:universal_notes_flutter/models/stroke.dart';

/// A block that allows interactive drawing with stylus or touch support.
class InteractiveDrawingBlock extends StatefulWidget {
  /// Creates an [InteractiveDrawingBlock].
  const InteractiveDrawingBlock({
    required this.strokes,
    required this.height,
    required this.isDrawingMode,
    required this.onStrokeAdded,
    this.onStrokeRemoved,
    this.currentColor = Colors.black,
    this.currentStrokeWidth = 2.0,
    super.key,
  });

  /// The list of strokes already present in the block.
  final List<Stroke> strokes;

  /// The height of the drawing area.
  final double height;

  /// Whether drawing mode is active.
  final bool isDrawingMode;

  /// Callback when a new stroke is completed.
  final ValueChanged<Stroke> onStrokeAdded;

  /// Callback when a stroke should be removed (e.g., via eraser).
  final ValueChanged<Stroke>? onStrokeRemoved;

  /// The color to use for new strokes.
  final Color currentColor;

  /// The width to use for new strokes.
  final double currentStrokeWidth;

  @override
  State<InteractiveDrawingBlock> createState() =>
      _InteractiveDrawingBlockState();
}

class _InteractiveDrawingBlockState extends State<InteractiveDrawingBlock> {
  // Current stroke being drawn
  List<Point> _currentPoints = [];
  bool _isEraserActive = false;

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isDrawingMode) return;

    // Check for S Pen button using buttons flags
    // kSecondaryButton usually corresponds to the side button on styluses
    final isStylusButton = (event.buttons & kSecondaryButton) != 0;

    if (isStylusButton) {
      setState(() {
        _isEraserActive = true;
      });
      // Eraser logic is handled in move
      _eraseAt(event.localPosition);
      return;
    }

    setState(() {
      _isEraserActive = false;
      _currentPoints = [
        Point(event.localPosition.dx, event.localPosition.dy, event.pressure),
      ];
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.isDrawingMode) return;

    // Check if the stylus button is held down during the move
    final isStylusButton = (event.buttons & kSecondaryButton) != 0;

    if (isStylusButton || _isEraserActive) {
      _eraseAt(event.localPosition);
      return;
    }

    setState(() {
      _currentPoints.add(
        Point(event.localPosition.dx, event.localPosition.dy, event.pressure),
      );
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!widget.isDrawingMode) return;

    if (_isEraserActive) {
      setState(() {
        _isEraserActive = false;
      });
      return;
    }

    if (_currentPoints.isNotEmpty) {
      final stroke = Stroke(
        points: List.from(_currentPoints),
        color: widget.currentColor,
        width: widget.currentStrokeWidth,
      );
      widget.onStrokeAdded(stroke);
      setState(() {
        _currentPoints = [];
      });
    }
  }

  void _eraseAt(Offset position) {
    if (widget.onStrokeRemoved == null) return;

    // Simple hit detection threshold
    const eraseThreshold = 20;

    for (final stroke in widget.strokes) {
      for (final point in stroke.points) {
        final dx = point.x - position.dx;
        final dy = point.y - position.dy;
        if (dx * dx + dy * dy < eraseThreshold * eraseThreshold) {
          widget.onStrokeRemoved!(stroke);
          return; // Remove one stroke per frame/check to avoid state issues or multi-delete
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine existing strokes with current stroke preview
    final allStrokes = [...widget.strokes];
    if (_currentPoints.isNotEmpty && !_isEraserActive) {
      allStrokes.add(
        Stroke(
          points: _currentPoints,
          color: widget.currentColor,
          width: widget.currentStrokeWidth,
        ),
      );
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      behavior: widget.isDrawingMode
          ? HitTestBehavior.opaque
          : HitTestBehavior.translucent,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          color: Colors.white,
        ),
        child: CustomPaint(
          painter: DrawingPainter(allStrokes),
        ),
      ),
    );
  }
}
