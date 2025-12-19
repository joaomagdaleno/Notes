import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Local Graph View')),
      body: CustomPaint(
        painter: GraphPainter(notes: _notes),
        child: Container(),
      ),
    );
  }
}

/// A custom painter for drawing note graphs.
class GraphPainter extends CustomPainter {
  /// Creates a new [GraphPainter] with the given notes.
  GraphPainter({required this.notes});

  /// The list of notes to display.
  final List<Note> notes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;

    final nodePaint = Paint()..color = Colors.red;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Simple circle layout for now
    for (var i = 0; i < notes.length; i++) {
      // Real layout would use force-directed or similar
      final actualOffset = Offset(
        center.dx + radius * (i.isEven ? 1 : -1) * (i / notes.length),
        center.dy + radius * (i % 3 == 0 ? 1 : -1) * (i / notes.length),
      );

      canvas.drawCircle(actualOffset, 10, nodePaint);

      // Draw links to folder/tags (simplified)
      if (notes[i].folderId != null) {
        canvas.drawLine(actualOffset, center, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
