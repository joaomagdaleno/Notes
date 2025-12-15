import 'package:flutter/material.dart';

class FloatingToolbar extends StatelessWidget {
  // Adicionaremos mais callbacks conforme necessário.

  const FloatingToolbar({
    super.key,
    this.onBold,
    this.onItalic,
  });
  final VoidCallback? onBold;
  final VoidCallback? onItalic;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: onBold,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: onItalic,
            ),
          ],
        ),
      ),
    );
  }
}
