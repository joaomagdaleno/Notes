import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
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
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.currentAlignment = 'left',
    this.currentListType,
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

  /// Active style states
  final bool isBold;

  /// Whether the italic style is active.
  final bool isItalic;

  /// Whether the underline style is active.
  final bool isUnderline;

  /// Whether the strikethrough style is active.
  final bool isStrikethrough;

  /// The current text alignment.
  final String currentAlignment;

  /// The current list type, if any.
  final String? currentListType;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentToolbar(context);
    }
    return _buildMaterialToolbar(context);
  }

  Widget _buildFluentToolbar(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.resources.dividerStrokeColorDefault,
            width: 0.5,
          ),
        ),
      ),
      height: 50,
      child: fluent.ListView(
        scrollDirection: Axis.horizontal,
        children: [
          fluent.IconButton(
            icon: Icon(
              isDrawingMode
                  ? fluent.FluentIcons.keyboard_classic
                  : fluent.FluentIcons.edit,
            ),
            onPressed: onToggleDrawingMode,
            style: isDrawingMode
                ? fluent.ButtonStyle(
                    backgroundColor: fluent.WidgetStateProperty.all(
                      theme.accentColor.withValues(alpha: 0.1),
                    ),
                  )
                : null,
          ),
          const fluent.Divider(direction: Axis.vertical),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.undo),
            onPressed: canUndo ? onUndo : null,
          ),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.redo),
            onPressed: canRedo ? onRedo : null,
          ),
          const fluent.Divider(direction: Axis.vertical),
          if (!isDrawingMode) ...[
            _FluentToolbarButton(
              icon: fluent.FluentIcons.bold,
              onPressed: onBold,
              selected: isBold,
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.italic,
              onPressed: onItalic,
              selected: isItalic,
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.underline,
              onPressed: onUnderline,
              selected: isUnderline,
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.strikethrough,
              onPressed: onStrikethrough,
              selected: isStrikethrough,
              theme: theme,
            ),
            fluent.IconButton(
              icon: const Icon(fluent.FluentIcons.font_color),
              onPressed: onColor,
            ),
            const fluent.Divider(direction: Axis.vertical),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.align_left,
              onPressed: () => onAlignment('left'),
              selected: currentAlignment == 'left',
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.align_center,
              onPressed: () => onAlignment('center'),
              selected: currentAlignment == 'center',
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.align_right,
              onPressed: () => onAlignment('right'),
              selected: currentAlignment == 'right',
              theme: theme,
            ),
            const fluent.Divider(direction: Axis.vertical),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.bulleted_list,
              onPressed: () => onList('unordered'),
              selected: currentListType == 'unordered',
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.numbered_list,
              onPressed: () => onList('ordered'),
              selected: currentListType == 'ordered',
              theme: theme,
            ),
            _FluentToolbarButton(
              icon: fluent.FluentIcons.check_list,
              onPressed: () => onList('checklist'),
              selected: currentListType == 'checklist',
              theme: theme,
            ),
          ],
          const fluent.Divider(direction: Axis.vertical),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.font_size),
            onPressed: onFontSize,
          ),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.page_list),
            onPressed: onSnippets,
          ),
          fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.photo2),
            onPressed: onImage,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialToolbar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      height: 50, // Slightly more compact
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
              color: isBold ? theme.colorScheme.primary : null,
              style: isBold
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: onItalic,
              tooltip: 'Italic',
              color: isItalic ? theme.colorScheme.primary : null,
              style: isItalic
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_underline),
              onPressed: onUnderline,
              tooltip: 'Underline',
              color: isUnderline ? theme.colorScheme.primary : null,
              style: isUnderline
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_strikethrough),
              onPressed: onStrikethrough,
              tooltip: 'Strikethrough',
              color: isStrikethrough ? theme.colorScheme.primary : null,
              style: isStrikethrough
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
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
              color:
                  currentAlignment == 'left' ? theme.colorScheme.primary : null,
              style: currentAlignment == 'left'
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_align_center),
              onPressed: () => onAlignment('center'),
              tooltip: 'Align Center',
              color: currentAlignment == 'center'
                  ? theme.colorScheme.primary
                  : null,
              style: currentAlignment == 'center'
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_align_right),
              onPressed: () => onAlignment('right'),
              tooltip: 'Align Right',
              color: currentAlignment == 'right'
                  ? theme.colorScheme.primary
                  : null,
              style: currentAlignment == 'right'
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            // Lists
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: () => onList('unordered'),
              tooltip: 'Bullet List',
              color: currentListType == 'unordered'
                  ? theme.colorScheme.primary
                  : null,
              style: currentListType == 'unordered'
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: () => onList('ordered'),
              tooltip: 'Numbered List',
              color: currentListType == 'ordered'
                  ? theme.colorScheme.primary
                  : null,
              style: currentListType == 'ordered'
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: () => onList('checklist'),
              tooltip: 'Checklist',
              color: currentListType == 'checklist'
                  ? theme.colorScheme.primary
                  : null,
              style: currentListType == 'checklist'
                  ? IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                    )
                  : null,
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

class _FluentToolbarButton extends StatelessWidget {
  const _FluentToolbarButton({
    required this.icon,
    required this.onPressed,
    required this.selected,
    required this.theme,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final fluent.FluentThemeData theme;

  @override
  Widget build(BuildContext context) {
    return fluent.IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      style: selected
          ? fluent.ButtonStyle(
              backgroundColor: fluent.WidgetStateProperty.all(
                theme.accentColor.withValues(alpha: 0.1),
              ),
              foregroundColor:
                  fluent.WidgetStateProperty.all(theme.accentColor),
            )
          : null,
    );
  }
}
