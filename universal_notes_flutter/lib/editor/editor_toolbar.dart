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
    required this.onAlignment,
    required this.onIndent,
    required this.onList,
    required this.isDrawingMode,
    required this.onToggleDrawingMode,
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

  /// Callback for alignment changes.
  final ValueChanged<String> onAlignment;

  /// Callback for indentation changes (+1 or -1).
  final ValueChanged<int> onIndent;

  /// Callback for list toggles (ordered, unordered, checklist).
  final ValueChanged<String> onList;

  /// Callback for when the image button is pressed.
  final VoidCallback onImage;

  /// Callback for undo.
  final VoidCallback onUndo;

  /// Callback for redo.
  final VoidCallback onRedo;

  /// Whether undo is available.
  final bool canUndo;

  /// Whether redo is available.
  final bool canRedo;

  /// Notifier for word count.
  final ValueNotifier<int> wordCountNotifier;

  /// Notifier for character count.
  final ValueNotifier<int> charCountNotifier;

  /// Whether we are currently in Drawing Mode.
  final bool isDrawingMode;

  /// Callback to toggle drawing mode.
  final VoidCallback onToggleDrawingMode;

  /// Callback for when the text color button is pressed.
  final VoidCallback onColor;

  /// Callback for when the font size button is pressed.
  final VoidCallback onFontSize;

  /// Callback for when the snippets button is pressed.
  final VoidCallback onSnippets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200],
      height: 56, // Fixed height for scrollable row
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Mode Switcher
          IconButton(
            icon: Icon(isDrawingMode ? Icons.keyboard : Icons.edit),
            onPressed: onToggleDrawingMode,
            tooltip: isDrawingMode ? 'Back to Text' : 'Drawing Mode',
            // Highlight if drawing mode
            color: isDrawingMode ? Colors.blue : null,
          ),
          const VerticalDivider(),
          Semantics(
            label: 'Undo',
            child: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo',
            ),
          ),
          Semantics(
            label: 'Redo',
            child: IconButton(
              icon: const Icon(Icons.redo),
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo',
            ),
          ),
          const VerticalDivider(),
          if (!isDrawingMode) ...[
            // Font Styling
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: onBold,
              tooltip: 'Bold',
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: onItalic,
              tooltip: 'Italic',
            ),
            IconButton(
              icon: const Icon(Icons.format_underline),
              onPressed: onUnderline,
              tooltip: 'Underline',
            ),
            IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: onStrikethrough,
              tooltip: 'Strikethrough',
            ),
            IconButton(
              icon: const Icon(Icons.format_color_text),
              onPressed: onColor,
              tooltip: 'Text Color',
            ),
            // Alignment
            IconButton(
              icon: const Icon(Icons.format_align_left),
              onPressed: () => onAlignment('left'),
              tooltip: 'Align Left',
            ),
            IconButton(
              icon: const Icon(Icons.format_align_center),
              onPressed: () => onAlignment('center'),
              tooltip: 'Align Center',
            ),
            IconButton(
              icon: const Icon(Icons.format_align_right),
              onPressed: () => onAlignment('right'),
              tooltip: 'Align Right',
            ),
            // Lists
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: () => onList('unordered'),
              tooltip: 'Bullet List',
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: () => onList('ordered'),
              tooltip: 'Numbered List',
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => onList('checklist'),
              tooltip: 'Checklist',
            ),
            // Indent
            IconButton(
              icon: const Icon(Icons.format_indent_decrease),
              onPressed: () => onIndent(-1),
              tooltip: 'Decrease Indent',
            ),
            IconButton(
              icon: const Icon(Icons.format_indent_increase),
              onPressed: () => onIndent(1),
              tooltip: 'Increase Indent',
            ),
          ] else ...[
            // Drawing Tools Placeholder (Can expand later with Color/Size pickers)
            Center(
              child: Text(
                ' Drawing Mode ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ),
          ],
          if (!isDrawingMode) ...[
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.format_size),
              onPressed: onFontSize,
              tooltip: 'Font Size',
            ),
            IconButton(
              icon: const Icon(Icons.shortcut), // Snippets icon replacement?
              onPressed: onSnippets,
              tooltip: 'Snippets',
            ),
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: onImage,
              tooltip: 'Insert Image',
            ),
          ],
          const VerticalDivider(),
          // Stats
          Center(
            child: ValueListenableBuilder<int>(
              valueListenable: wordCountNotifier,
              builder: (context, count, child) {
                final readingTimeMinutes = (count / 200).ceil();
                final readingTimeText = readingTimeMinutes <= 1
                    ? '~1 min'
                    : '~$readingTimeMinutes min';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14),
                    const SizedBox(width: 4),
                    Text(readingTimeText),
                    const SizedBox(width: 12),
                    Text('$count words'),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Center(
            child: ValueListenableBuilder<int>(
              valueListenable: charCountNotifier,
              builder: (context, count, child) => Text('$count chars'),
            ),
          ),
        ],
      ),
    );
  }
}
