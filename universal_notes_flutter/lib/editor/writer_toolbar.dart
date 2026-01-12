import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:universal_notes_flutter/editor/editor_widget.dart';

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
          CommandBarButton(
            icon: const Icon(FluentIcons.bold),
            label: const Text('Negrito'),
            onPressed: onBold,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.italic),
            label: const Text('Itálico'),
            onPressed: onItalic,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.underline),
            label: const Text('Sublinhado'),
            onPressed: onUnderline,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.strikethrough),
            label: const Text('Tachado'),
            onPressed: onStrikethrough,
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.font_color),
            label: const Text('Cor'),
            onPressed: onColor,
          ),
          const CommandBarSeparator(),

          // Alignment
          CommandBarButton(
            icon: const Icon(FluentIcons.align_left),
            label: const Text('Esquerda'),
            onPressed: () => onAlignment('left'),
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.align_center),
            label: const Text('Centro'),
            onPressed: () => onAlignment('center'),
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.align_right),
            label: const Text('Direita'),
            onPressed: () => onAlignment('right'),
          ),
          const CommandBarSeparator(),

          // Lists
          CommandBarButton(
            icon: const Icon(FluentIcons.bulleted_list),
            label: const Text('Marcadores'),
            onPressed: () => onList('unordered'),
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.numbered_list),
            label: const Text('Numerada'),
            onPressed: () => onList('ordered'),
          ),
          CommandBarButton(
            icon: const Icon(FluentIcons.check_list),
            label: const Text('Tarefas'),
            onPressed: () => onList('checklist'),
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
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_italic),
              onPressed: onItalic,
              tooltip: 'Italic',
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_underlined),
              onPressed: onUnderline,
              tooltip: 'Underline',
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.strikethrough_s),
              onPressed: onStrikethrough,
              tooltip: 'Strikethrough',
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_align_left),
              onPressed: () => onAlignment('left'),
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_align_center),
              onPressed: () => onAlignment('center'),
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_align_right),
              onPressed: () => onAlignment('right'),
            ),
            const material.VerticalDivider(indent: 12, endIndent: 12),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_list_bulleted),
              onPressed: () => onList('unordered'),
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.format_list_numbered),
              onPressed: () => onList('ordered'),
            ),
            material.IconButton(
              icon: const material.Icon(material.Icons.checklist),
              onPressed: () => onList('checklist'),
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
