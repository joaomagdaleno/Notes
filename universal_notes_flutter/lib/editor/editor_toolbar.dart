import 'package:flutter/material.dart';

/// A toolbar with basic text formatting options and undo/redo buttons.
class EditorToolbar extends StatelessWidget {
  /// Creates a new instance of [EditorToolbar].
  const EditorToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrikethrough,
    required this.onColor,
    required this.onFontSize,
    required this.onSnippets,
    required this.onImage,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.wordCountNotifier,
    required this.charCountNotifier,
    super.key,
  });

  /// Callback for when the bold button is pressed.
  final VoidCallback onBold;

  /// Callback for when the italic button is pressed.
  final VoidCallback onItalic;

  /// Callback for when the underline button is pressed.
  final VoidCallback onUnderline;

  /// Callback for when the strikethrough button is pressed.
  final VoidCallback onStrikethrough;

  /// Callback to open the color selection UI.
  final VoidCallback onColor;

  /// Callback to open the font size selection UI.
  final VoidCallback onFontSize;

  /// Callback to open the snippets management screen.
  final VoidCallback onSnippets;

  /// Callback to insert an image.
  final VoidCallback onImage;

  /// Callback for when the undo button is pressed.
  final VoidCallback onUndo;

  /// Callback for when the redo button is pressed.
  final VoidCallback onRedo;

  /// Whether the undo action is available.
  final bool canUndo;

  /// Whether the redo action is available.
  final bool canRedo;

  /// The word count of the document.
  final ValueNotifier<int> wordCountNotifier;

  /// The character count of the document.
  final ValueNotifier<int> charCountNotifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200],
      child: Row(
        children: [
          Semantics(
            label: 'Undo',
            child: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: canUndo ? onUndo : null,
            ),
          ),
          Semantics(
            label: 'Redo',
            child: IconButton(
              icon: const Icon(Icons.redo),
              onPressed: canRedo ? onRedo : null,
            ),
          ),
          const VerticalDivider(),
          Semantics(
            label: 'Bold',
            child: IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: onBold,
            ),
          ),
          Semantics(
            label: 'Italic',
            child: IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: onItalic,
            ),
          ),
          Semantics(
            label: 'Underline',
            child: IconButton(
              icon: const Icon(Icons.format_underline),
              onPressed: onUnderline,
            ),
          ),
          Semantics(
            label: 'Strikethrough',
            child: IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: onStrikethrough,
            ),
          ),
          const VerticalDivider(),
          Semantics(
            label: 'Text color',
            child: IconButton(
              icon: const Icon(Icons.format_color_text),
              onPressed: onColor,
            ),
          ),
          Semantics(
            label: 'Font size',
            child: IconButton(
              icon: const Icon(Icons.format_size),
              onPressed: onFontSize,
            ),
          ),
          Semantics(
            label: 'Snippets',
            child: IconButton(
              icon: const Icon(Icons.shortcut),
              onPressed: onSnippets,
            ),
          ),
          Semantics(
            label: 'Insert image',
            child: IconButton(
              icon: const Icon(Icons.image),
              onPressed: onImage,
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<int>(
            valueListenable: wordCountNotifier,
            builder: (context, wordCount, child) {
              return ValueListenableBuilder<int>(
                valueListenable: charCountNotifier,
                builder: (context, charCount, child) {
                  return Text(
                    '$wordCount words / $charCount characters',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
