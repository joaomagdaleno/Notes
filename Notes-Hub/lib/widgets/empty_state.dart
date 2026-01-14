import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A widget to display when a list is empty.
class EmptyState extends StatelessWidget {
  /// Creates a new instance of [EmptyState].
  const EmptyState({
    required this.message,
    super.key,
    this.icon = Icons.inbox,
    this.fluentIcon = fluent.FluentIcons.inbox,
    this.subtitle,
  });

  /// The message to display.
  final String message;

  /// An optional subtitle to display below the message.
  final String? subtitle;

  /// The Material icon to display above the message.
  final IconData icon;

  /// The Fluent icon to display above the message on Windows.
  final IconData fluentIcon;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentEmptyState(context);
    } else {
      return _buildMaterialEmptyState(context);
    }
  }

  Widget _buildFluentEmptyState(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            fluentIcon,
            size: 64,
            color: theme.resources.textFillColorSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.typography.subtitle,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.typography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
