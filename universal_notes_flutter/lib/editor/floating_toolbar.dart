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

  @override
  Widget build(BuildContext context) {
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
