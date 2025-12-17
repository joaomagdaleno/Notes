import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// A widget to display when a list is empty.
class EmptyState extends StatelessWidget {
  /// Creates a new instance of [EmptyState].
  const EmptyState({
    required this.message,
    super.key,
    this.icon = Icons.inbox,
  });

  /// The message to display.
  final String message;

  /// The icon to display above the message.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return fluent.Center(
        child: fluent.Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            fluent.Icon(
              icon,
              size: 64,
              color: fluent.FluentTheme.of(context).typography.body?.color?.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            fluent.Text(
              message,
              style: fluent.FluentTheme.of(context).typography.subtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
