import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';

class CustomEditorToolbar extends StatelessWidget {
  final EditorState editorState;
  final DrawingController drawingController;

  const CustomEditorToolbar({
    super.key,
    required this.editorState,
    required this.drawingController,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          // Text formatting buttons for AppFlowy Editor
          _buildToolbarButton(
            'B',
            () => editorState.toggleAttribute(AppFlowyRichTextKeys.bold),
          ),
          _buildToolbarButton(
            'I',
            () => editorState.toggleAttribute(AppFlowyRichTextKeys.italic),
          ),
          _buildToolbarButton(
            'U',
            () => editorState.toggleAttribute(AppFlowyRichTextKeys.underline),
          ),
          // Add a separator between text and drawing tools
          const VerticalDivider(),
          // Drawing tool buttons for the Flutter Drawing Board
          _buildToolbarButton(
            '🖌️',
            () => drawingController.setPaintContent(SimpleLine()),
          ),
          _buildToolbarButton(
            '🧽',
            () => drawingController.setPaintContent(Eraser()),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String text, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Text(text),
    );
  }
}
