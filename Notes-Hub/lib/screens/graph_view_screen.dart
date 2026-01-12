import 'dart:async';
import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/repositories/note_repository.dart';

/// A screen that displays a graph view of notes.
class GraphView extends StatefulWidget {
  /// Creates a new [GraphView].
  const GraphView({super.key});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    final notes = await NoteRepository.instance.getAllNotes();
    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    if (_isLoading) {
      return const Center(child: fluent.ProgressRing());
    }

    final theme = fluent.FluentTheme.of(context);

    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('Local Graph View'),
      ),
      content: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: CustomPaint(
          painter: GraphPainter(
            notes: _notes,
            accentColor: theme.accentColor,
            textColor: theme.typography.body?.color ?? fluent.Colors.black,
            nodeColor: theme.accentColor.light,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Local Graph View')),
      body: CustomPaint(
        painter: GraphPainter(
          notes: _notes,
          accentColor: Colors.blue,
          textColor: Colors.black,
          nodeColor: Colors.blue.withValues(alpha: 0.3),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// A custom painter for drawing note graphs.
class GraphPainter extends CustomPainter {
  /// Creates a new [GraphPainter] with the given notes.
  GraphPainter({
    required this.notes,
    required this.accentColor,
    required this.textColor,
    required this.nodeColor,
  });

  /// The list of notes to display.
  final List<Note> notes;

  /// The primary accent color for links.
  final Color accentColor;

  /// The color for text labels.
  final Color textColor;

  /// The color for nodes.
  final Color nodeColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (notes.isEmpty) return;

    final paint = Paint()
      ..color = accentColor.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    final nodePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final nodeOutlinePaint = Paint()
      ..color = nodeColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final count = notes.length;

    // Use a slightly more organic layout distribution
    final positions = <Offset>[];
    for (var i = 0; i < count; i++) {
      final angle = (i * 2 * 3.14159) / count;
      final dist = (size.width < size.height ? size.width : size.height) * 0.35;
      positions.add(
        Offset(
          center.dx +
              dist *
                  (0.8 + 0.2 * (i % 2)) *
                  (i % 3 == 0 ? 0.9 : 1.1) *
                  (i.isEven ? 1 : 1.05) *
                  (i / count > 0.5 ? 0.95 : 1) *
                  math.cos(angle),
          center.dy +
              dist *
                  (0.8 + 0.2 * (i % 2)) *
                  (i % 3 == 0 ? 0.9 : 1.1) *
                  math.sin(angle),
        ),
      );
    }

    // Draw links
    for (var i = 0; i < count; i++) {
      if (notes[i].folderId != null) {
        canvas.drawLine(positions[i], center, paint);
      }
    }

    // Draw nodes
    for (var i = 0; i < count; i++) {
      // Glow/Outline
      canvas
        ..drawCircle(positions[i], 8, nodeOutlinePaint)
        // Actual node
        ..drawCircle(positions[i], 4, nodePaint);

      // Label (Simplified)
      if (count < 20) {
        // Only draw labels if not too many nodes
        TextPainter(
          text: TextSpan(
            text: notes[i].title.length > 15
                ? '${notes[i].title.substring(0, 12)}...'
                : notes[i].title,
            style: TextStyle(color: textColor, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )
          ..layout()
          ..paint(
            canvas,
            positions[i] + const Offset(10, -5),
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
