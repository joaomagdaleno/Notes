import 'package:flutter/material.dart';

/// A widget to display when a list is empty.
class EmptyState extends StatelessWidget {
  /// Creates a new instance of [EmptyState].
  const EmptyState({
    required this.message, super.key,
    this.icon = Icons.inbox,
  });

  /// The message to display.
  final String message;

  /// The icon to display above the message.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
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
