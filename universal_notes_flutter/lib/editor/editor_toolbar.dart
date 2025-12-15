import 'package:flutter/material.dart';

/// A toolbar with basic text formatting options.
class EditorToolbar extends StatelessWidget {
  /// Creates a new instance of [EditorToolbar].
  const EditorToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    super.key,
  });

  /// Callback for when the bold button is pressed.
  final VoidCallback onBold;
  /// Callback for when the italic button is pressed.
  final VoidCallback onItalic;
  /// Callback for when the underline button is pressed.
  final VoidCallback onUnderline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.format_bold),
            onPressed: onBold,
          ),
          IconButton(
            icon: const Icon(Icons.format_italic),
            onPressed: onItalic,
          ),
          IconButton(
            icon: const Icon(Icons.format_underline),
            onPressed: onUnderline,
          ),
        ],
      ),
    );
  }
}
