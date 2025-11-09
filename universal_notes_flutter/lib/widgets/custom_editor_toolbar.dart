import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ColorPicker;

class CustomEditorToolbar extends StatelessWidget {
  final EditorState editorState;
  final bool isVisible;

  const CustomEditorToolbar({
    super.key,
    required this.editorState,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      height: 48,
      color: Colors.grey[200],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              tooltip: 'Negrito',
              onPressed: () {
                editorState.toggleMark('bold');
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              tooltip: 'Itálico',
              onPressed: () {
                editorState.toggleMark('italic');
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_underline),
              tooltip: 'Sublinhado',
              onPressed: () {
                editorState.toggleMark('underline');
              },
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              tooltip: 'Lista',
              onPressed: () {
                editorState.toggleMark('list');
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              tooltip: 'Lista Numerada',
              onPressed: () {
                editorState.toggleMark('numbered-list');
              },
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.format_quote),
              tooltip: 'Citação',
              onPressed: () {
                editorState.toggleMark('quote');
              },
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.title),
              tooltip: 'Título 1',
              onPressed: () {
                editorState.formatNode(
                  (transaction) => transaction
                      .replaceText(editorState.selection, '# '),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.title),
              tooltip: 'Título 2',
              onPressed: () {
                editorState.formatNode(
                  (transaction) => transaction
                      .replaceText(editorState.selection, '## '),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.title),
              tooltip: 'Título 3',
              onPressed: () {
                editorState.formatNode(
                  (transaction) => transaction
                      .replaceText(editorState.selection, '### '),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
