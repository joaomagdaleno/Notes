import 'dart:async';
import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
<<<<<<<< HEAD:notes_hub/lib/screens/graph_view/graph_view_screen.dart
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/screens/graph_view/views/fluent_graph_view.dart';
import 'package:notes_hub/screens/graph_view/views/material_graph_view.dart';
========
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/repositories/note_repository.dart';
>>>>>>>> dev:Notes-Hub/lib/screens/graph_view_screen.dart

/// GraphView controller - platform-adaptive
class GraphView extends StatefulWidget {
  /// Creates a [GraphView].
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

  CustomPainter _createPainter(BuildContext context, bool isFluent) {
    if (isFluent) {
      final theme = fluent.FluentTheme.of(context);
      return GraphPainter(
        notes: _notes,
        accentColor: theme.accentColor,
        textColor: theme.typography.body?.color ?? fluent.Colors.black,
        nodeColor: theme.accentColor.light,
      );
    } else {
      return GraphPainter(
        notes: _notes,
        accentColor: Colors.blue,
        textColor: Colors.black,
        nodeColor: Colors.blue.withValues(alpha: 0.3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = defaultTargetPlatform == TargetPlatform.windows;

    if (isWindows) {
      return FluentGraphView(
        notes: _notes,
        isLoading: _isLoading,
        painter: _createPainter(context, true),
      );
    } else {
      return MaterialGraphView(
        notes: _notes,
        isLoading: _isLoading,
        painter: _createPainter(context, false),
      );
    }
  }
<<<<<<<< HEAD:notes_hub/lib/screens/graph_view/graph_view_screen.dart
========

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
>>>>>>>> dev:Notes-Hub/lib/screens/graph_view_screen.dart
}

/// Custom painter for the notes graph.
class GraphPainter extends CustomPainter {
  /// Creates a [GraphPainter].
  GraphPainter({
    required this.notes,
    required this.accentColor,
    required this.textColor,
    required this.nodeColor,
  });

  /// The list of notes to display.
  final List<Note> notes;
  /// The accent color for lines and nodes.
  final Color accentColor;
  /// The color for text labels.
  final Color textColor;
  /// The color for node backgrounds.
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

<<<<<<<< HEAD:notes_hub/lib/screens/graph_view/graph_view_screen.dart
========
    // Use a slightly more organic layout distribution
>>>>>>>> dev:Notes-Hub/lib/screens/graph_view_screen.dart
    final positions = <Offset>[];
    for (var i = 0; i < count; i++) {
      final angle = (i * 2 * 3.14159) / count;
      final dist = (size.width < size.height ? size.width : size.height) * 0.35;
<<<<<<<< HEAD:notes_hub/lib/screens/graph_view/graph_view_screen.dart
      positions.add(Offset(
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
                (i.isEven ? 1 : 1.05) *
                (i / count > 0.5 ? 0.95 : 1) *
                math.sin(angle),
              ),
========
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
>>>>>>>> dev:Notes-Hub/lib/screens/graph_view_screen.dart
      );
    }

    for (var i = 0; i < count; i++) {
      if (notes[i].folderId != null) {
        canvas.drawLine(positions[i], center, paint);
      }
    }

    for (var i = 0; i < count; i++) {
<<<<<<<< HEAD:notes_hub/lib/screens/graph_view/graph_view_screen.dart
      canvas
        ..drawCircle(positions[i], 8, nodeOutlinePaint)
========
      // Glow/Outline
      canvas
        ..drawCircle(positions[i], 8, nodeOutlinePaint)
        // Actual node
>>>>>>>> dev:Notes-Hub/lib/screens/graph_view_screen.dart
        ..drawCircle(positions[i], 4, nodePaint);

      if (count < 20) {
<<<<<<<< HEAD:notes_hub/lib/screens/graph_view/graph_view_screen.dart
========
        // Only draw labels if not too many nodes
>>>>>>>> dev:Notes-Hub/lib/screens/graph_view_screen.dart
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
