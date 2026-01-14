import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:notes_hub/editor/editor_widget.dart';

/// A platform-adaptive toolbar for the [EditorWidget] with formatting controls.
class WriterToolbar extends StatelessWidget {
  /// Creates a [WriterToolbar].
  const WriterToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onStrikethrough,
    required this.onColor,
    required this.onFontSize,
    required this.onAlignment,
    required this.onIndent,
    required this.onList,
    required this.onImage,
    required this.onLink,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo,
    required this.canRedo,
    required this.onStyleToggle,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.currentAlignment = 'left',
    this.currentListType,
    super.key,
  });

  /// Callback for toggling bold style.
  final VoidCallback onBold;

  /// Callback for toggling italic style.
  final VoidCallback onItalic;

  /// Callback for toggling underline style.
  final VoidCallback onUnderline;

  /// Callback for toggling strikethrough style.
  final VoidCallback onStrikethrough;

  /// Callback for changing text color.
  final VoidCallback onColor;

  /// Callback for changing font size.
  final VoidCallback onFontSize;

  /// Callback for changing text alignment.
  final ValueChanged<String> onAlignment;

  /// Callback for changing indentation.
  final ValueChanged<int> onIndent;

  /// Callback for changing list style.
  final ValueChanged<String> onList;

  /// Callback for inserting an image.
  final VoidCallback onImage;

  /// Callback for inserting a link.
  final VoidCallback onLink;

  /// Callback for undoing the last action.
  final VoidCallback onUndo;

  /// Callback for redoing the last undone action.
  final VoidCallback onRedo;

  /// Whether undo is currently available.
  final bool canUndo;

  /// Whether redo is currently available.
  final bool canRedo;

  /// Callback for toggling text style (e.g., headings).
  final ValueChanged<String> onStyleToggle;

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
    if (Platform.isWindows) {
      return _buildFluentToolbar(context);
    } else {
      return _buildMaterialToolbar(context);
    }
  }

  Widget _buildFluentToolbar(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.resources.dividerStrokeColorDefault,
            width: 0.5,
          ),
        ),
      ),
      child: CommandBar(
        primaryItems: [
          // Undo/Redo
          CommandBarButton(
            icon: const Icon(FluentIcons.undo),
            label: const Text('Desfazer'),
            onPressed: canUndo ? onUndo : null,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.redo),
            label: const Text('Refazer'),
            onPressed: canRedo ? onRedo : null,
          ),
          const CommandBarSeparator(),

          // Text Style
          CommandBarBuilderItem(
            builder: (context, mode, w) {
              return Tooltip(
                message: 'Estilo do Texto',
                child: DropDownButton(
                  leading: const Icon(FluentIcons.text_field, size: 14),
                  title: const Text('Estilo', style: TextStyle(fontSize: 12)),
                  items: [
                    MenuFlyoutItem(
                      text: const Text('Texto normal'),
                      onPressed: () => onStyleToggle('normal'),
                    ),
                    MenuFlyoutItem(
                      text: const Text('Título 1'),
                      onPressed: () => onStyleToggle('h1'),
                    ),
                    MenuFlyoutItem(
                      text: const Text('Título 2'),
                      onPressed: () => onStyleToggle('h2'),
                    ),
                    MenuFlyoutItem(
                      text: const Text('Título 3'),
                      onPressed: () => onStyleToggle('h3'),
                    ),
                  ],
                ),
              );
            },
            wrappedItem: CommandBarButton(
              icon: const Icon(FluentIcons.text_field),
              label: const Text('Estilo'),
              onPressed: () {},
            ),
          ),
          const CommandBarSeparator(),

          // Formatting
          _FluentCommandBarItem(
            icon: FluentIcons.bold,
            label: 'Negrito',
            onPressed: onBold,
            selected: isBold,
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.italic,
            label: 'Itálico',
            onPressed: onItalic,
            selected: isItalic,
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.underline,
            label: 'Sublinhado',
            onPressed: onUnderline,
            selected: isUnderline,
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.strikethrough,
            label: 'Tachado',
            onPressed: onStrikethrough,
            selected: isStrikethrough,
            theme: theme,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.font_color),
            label: const Text('Cor'),
            onPressed: onColor,
          ),
          const CommandBarSeparator(),

          // Alignment
          _FluentCommandBarItem(
            icon: FluentIcons.align_left,
            label: 'Esquerda',
            onPressed: () => onAlignment('left'),
            selected: currentAlignment == 'left',
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.align_center,
            label: 'Centro',
            onPressed: () => onAlignment('center'),
            selected: currentAlignment == 'center',
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.align_right,
            label: 'Direita',
            onPressed: () => onAlignment('right'),
            selected: currentAlignment == 'right',
            theme: theme,
          ),
          const CommandBarSeparator(),

          // Lists
          _FluentCommandBarItem(
            icon: FluentIcons.bulleted_list,
            label: 'Marcadores',
            onPressed: () => onList('unordered'),
            selected: currentListType == 'unordered',
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.numbered_list,
            label: 'Numerada',
            onPressed: () => onList('ordered'),
            selected: currentListType == 'ordered',
            theme: theme,
          ),
          _FluentCommandBarItem(
            icon: FluentIcons.check_list,
            label: 'Tarefas',
            onPressed: () => onList('checklist'),
            selected: currentListType == 'checklist',
            theme: theme,
          ),
          const CommandBarSeparator(),

          // Indent
          CommandBarButton(
            icon: const Icon(FluentIcons.decrease_indent),
            label: const Text('Diminuir Recuo'),
            onPressed: () => onIndent(-1),
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.increase_indent),
            label: const Text('Aumentar Recuo'),
            onPressed: () => onIndent(1),
          ),
          const CommandBarSeparator(),

          // Insert
          CommandBarButton(
            icon: const Icon(FluentIcons.link),
            label: const Text('Link'),
            onPressed: onLink,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.photo2),
            label: const Text('Imagem'),
            onPressed: onImage,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialToolbar(BuildContext context) {
    // We explicitly use Material widgets here
    return material.Material(
      color: material.Theme.of(context).colorScheme.surfaceContainer,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: material.Theme.of(context).dividerColor,
            ),
          ),
        ),
        child: material.ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            material.IconButton(
              icon: const material.Icon(material.Icons.undo),
              onPressed: canUndo ? onUndo : null,
              tooltip: 'Undo',
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.redo),
              onPressed: canRedo ? onRedo : null,
              tooltip: 'Redo',
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_bold),
              onPressed: onBold,
              tooltip: 'Bold',
              color: isBold
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: isBold
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_italic),
              onPressed: onItalic,
              tooltip: 'Italic',
              color: isItalic
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: isItalic
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_underlined),
              onPressed: onUnderline,
              tooltip: 'Underline',
              color: isUnderline
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: isUnderline
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.strikethrough_s),
              onPressed: onStrikethrough,
              tooltip: 'Strikethrough',
              color: isStrikethrough
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: isStrikethrough
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_align_left),
              onPressed: () => onAlignment('left'),
              color: currentAlignment == 'left'
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: currentAlignment == 'left'
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_align_center),
              onPressed: () => onAlignment('center'),
              color: currentAlignment == 'center'
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: currentAlignment == 'center'
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_align_right),
              onPressed: () => onAlignment('right'),
              color: currentAlignment == 'right'
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: currentAlignment == 'right'
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_list_bulleted),
              onPressed: () => onList('unordered'),
              color: currentListType == 'unordered'
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: currentListType == 'unordered'
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_list_numbered),
              onPressed: () => onList('ordered'),
              color: currentListType == 'ordered'
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: currentListType == 'ordered'
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.checklist),
              onPressed: () => onList('checklist'),
              color: currentListType == 'checklist'
                  ? material.Theme.of(context).colorScheme.primary
                  : null,
              style: currentListType == 'checklist'
                  ? material.IconButton.styleFrom(
                      backgroundColor: material.Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                    )
                  : null,
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_indent_decrease),
              onPressed: () => onIndent(-1),
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_indent_increase),
              onPressed: () => onIndent(1),
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.link),
              onPressed: onLink,
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.image),
              onPressed: onImage,
            ),
          ],
        ),
      ),
    );
  }
}

class _FluentCommandBarItem extends CommandBarBuilderItem {
  _FluentCommandBarItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool selected,
    required FluentThemeData theme,
  }) : super(
          builder: (context, mode, w) => Tooltip(
            message: label,
            child: IconButton(
              icon: Icon(icon),
              onPressed: onPressed,
              style: selected
                  ? ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        theme.accentColor.withValues(alpha: 0.1),
                      ),
                      foregroundColor:
                          WidgetStateProperty.all(theme.accentColor),
                    )
                  : null,
            ),
          ),
          wrappedItem: CommandBarButton(
            icon: Icon(icon),
            label: Text(label),
            onPressed: onPressed,
          ),
        );
}
