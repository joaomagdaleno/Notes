import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// Material Design view for GraphView
class MaterialGraphView extends StatelessWidget {
  /// Creates a [MaterialGraphView].
  const MaterialGraphView({
    required this.notes,
    required this.isLoading,
    required this.painter,
    super.key,
  });

  /// The list of notes to display.
  final List<Note> notes;
  /// Whether the app is currently loading data.
  final bool isLoading;
  /// The painter for the graph.
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Local Graph View')),
      body: CustomPaint(
        painter: painter,
        child: Container(),
      ),
    );
  }
}
