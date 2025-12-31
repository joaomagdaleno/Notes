import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// Material Design view for GraphView
class MaterialGraphView extends StatelessWidget {
  final List<Note> notes;
  final bool isLoading;
  final CustomPainter painter;

  const MaterialGraphView({
    super.key,
    required this.notes,
    required this.isLoading,
    required this.painter,
  });

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
