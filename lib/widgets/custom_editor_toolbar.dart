import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

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
            _toggleButton(
              icon: Icons.format_bold,
              onPressed: () => _toggleAttribute(AppFlowyRichTextKeys.bold),
            ),
            _toggleButton(
              icon: Icons.format_italic,
              onPressed: () => _toggleAttribute(AppFlowyRichTextKeys.italic),
            ),
            _toggleButton(
              icon: Icons.format_underline,
              onPressed: () => _toggleAttribute(AppFlowyRichTextKeys.underline),
            ),
            const VerticalDivider(width: 1),
            _headingButton(HeadingLevel.h1, 'H1'),
            _headingButton(HeadingLevel.h2, 'H2'),
            _headingButton(HeadingLevel.h3, 'H3'),
            const VerticalDivider(width: 1),
            _toggleButton(
              icon: Icons.format_list_bulleted,
              onPressed: () => _toggleList('bulleted-list'),
            ),
            _toggleButton(
              icon: Icons.format_list_numbered,
              onPressed: () => _toggleList('numbered-list'),
            ),
            _toggleButton(
              icon: Icons.link,
              onPressed: () => _insertLink(),
            ),
            _toggleButton(
              icon: Icons.code,
              onPressed: () => _toggleAttribute(AppFlowyRichTextKeys.code),
            ),
            _toggleButton(
              icon: Icons.format_quote,
              onPressed: () => _toggleQuote(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton({required IconData icon, required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
    );
  }

  Widget _headingButton(HeadingLevel level, String label) {
    return TextButton(
      onPressed: () => _toggleHeading(level),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  void _toggleAttribute(String key) {
    final selection = editorState.selection;
    if (selection == null) return;

    final toggled = editorState.getAttributeInSelection(key) != true;
    editorState.updateAttribute(key, toggled);
  }

  void _toggleHeading(HeadingLevel level) {
    final selection = editorState.selection;
    if (selection == null) return;

    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;

    final attrs = {...node.attributes};
    if (attrs[HeadingBlockKeys.level] == level.name) {
      attrs.remove(HeadingBlockKeys.level);
      attrs[ParagraphBlockKeys.type] = ParagraphBlockKeys.type;
    } else {
      attrs[HeadingBlockKeys.level] = level.name;
      attrs[ParagraphBlockKeys.type] = HeadingBlockKeys.type;
    }

    final transaction = editorState.transaction
      ..updateNode(node, attrs);
    editorState.apply(transaction);
  }

  void _toggleList(String listType) {
    final selection = editorState.selection;
    if (selection == null) return;

    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;

    final attrs = {...node.attributes};
    if (attrs[ParagraphBlockKeys.type] == listType) {
      attrs[ParagraphBlockKeys.type] = ParagraphBlockKeys.type;
    } else {
      attrs[ParagraphBlockKeys.type] = listType;
    }

    final transaction = editorState.transaction
      ..updateNode(node, attrs);
    editorState.apply(transaction);
  }

  void _insertLink() {
    final selection = editorState.selection;
    if (selection == null) return;

    final link = 'https://example.com'; // You can prompt user here
    editorState.updateAttribute(AppFlowyRichTextKeys.href, link);
  }

  void _toggleQuote() {
    _toggleList('quote');
  }
}
