import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A floating toolbar that appears above the text selection.
class FloatingToolbar extends StatelessWidget {
  /// Creates a new instance of [FloatingToolbar].
  const FloatingToolbar({
    super.key,
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.onStrikethrough,
    this.onColor,
    this.onLink,
    this.onHighlight,
    this.onAddNote,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
  });

  /// Callback when the bold button is pressed.
  final VoidCallback? onBold;

  /// Callback when the italic button is pressed.
  final VoidCallback? onItalic;

  /// Callback when the underline button is pressed.
  final VoidCallback? onUnderline;

  /// Callback when the strikethrough button is pressed.
  final VoidCallback? onStrikethrough;

  /// Callback when the color button is pressed.
  final VoidCallback? onColor;

  /// Callback when the link button is pressed.
  final VoidCallback? onLink;

  /// Callback when the highlight button is pressed.
  final VoidCallback? onHighlight;

  /// Callback when the note button is pressed.
  final VoidCallback? onAddNote;

  /// Whether the bold style is active.
  final bool isBold;

  /// Whether the italic style is active.
  final bool isItalic;

  /// Whether the underline style is active.
  final bool isUnderline;

  /// Whether the strikethrough style is active.
  final bool isStrikethrough;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentFloatingToolbar(context);
    }
    return _buildMaterialFloatingToolbar(context);
  }

  Widget _buildFluentFloatingToolbar(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return fluent.Card(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildFluentButton(
            fluent.FluentIcons.bold,
            onBold,
            'Negrito',
            isBold,
            theme,
          ),
          _buildFluentButton(
            fluent.FluentIcons.italic,
            onItalic,
            'Itálico',
            isItalic,
            theme,
          ),
          _buildFluentButton(
            fluent.FluentIcons.underline,
            onUnderline,
            'Sublinhado',
            isUnderline,
            theme,
          ),
          _buildFluentButton(
            fluent.FluentIcons.strikethrough,
            onStrikethrough,
            'Tachado',
            isStrikethrough,
            theme,
          ),
          const fluent.Divider(direction: Axis.vertical),
          _buildFluentButton(
            fluent.FluentIcons.font_color,
            onColor,
            'Cor do Texto',
            false,
            theme,
          ),
          _buildFluentButton(
            fluent.FluentIcons.link,
            onLink,
            'Inserir Link',
            false,
            theme,
          ),
          _buildFluentButton(
            fluent.FluentIcons.highlight,
            onHighlight,
            'Destacar',
            false,
            theme,
          ),
          _buildFluentButton(
            fluent.FluentIcons.quick_note,
            onAddNote,
            'Adicionar Nota',
            false,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFluentButton(
    IconData icon,
    VoidCallback? onPressed,
    String tooltip,
    bool selected,
    fluent.FluentThemeData theme,
  ) {
    return fluent.Tooltip(
      message: tooltip,
      child: fluent.IconButton(
        icon: Icon(icon, size: 16),
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
      ),
    );
  }

  Widget _buildMaterialFloatingToolbar(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildButton(Icons.format_bold, onBold, 'Bold'),
            _buildButton(Icons.format_italic, onItalic, 'Italic'),
            _buildButton(Icons.format_underline, onUnderline, 'Underline'),
            _buildButton(
              Icons.format_strikethrough,
              onStrikethrough,
              'Strikethrough',
            ),
            const VerticalDivider(width: 8, indent: 4, endIndent: 4),
            _buildButton(Icons.format_color_text, onColor, 'Text Color'),
            _buildButton(Icons.link, onLink, 'Insert Link'),
            _buildButton(Icons.border_color, onHighlight, 'Highlight'),
            _buildButton(Icons.sticky_note_2, onAddNote, 'Add Note'),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(IconData icon, VoidCallback? onPressed, String tooltip) {
    return IconButton(
      icon: Icon(icon, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
