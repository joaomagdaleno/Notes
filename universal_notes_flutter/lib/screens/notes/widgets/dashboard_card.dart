import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// A card displayed on the dashboard with a title, subtitle, and icon.
class DashboardCard extends StatelessWidget {
  /// Creates a [DashboardCard].
  const DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  /// The primary title shown on the card.
  final String title;

  /// A descriptive subtitle shown below the title.
  final String subtitle;

  /// The icon to display on the card.
  final IconData icon;

  /// The base color for the card's theme.
  final Color color;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  static const _titleTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  static const _subtitleTextStyle = TextStyle(
    fontSize: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: fluent.HoverButton(
        onPressed: onTap,
        builder: (context, states) {
          return fluent.Card(
            padding: const EdgeInsets.all(16),
            backgroundColor: states.isHovered 
                ? color.withValues(alpha: 0.15) 
                : color.withValues(alpha: 0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fluent.Icon(icon, color: color, size: 32),
                const SizedBox(height: 12),
                fluent.Text(
                  title,
                  style: _titleTextStyle.copyWith(color: color),
                ),
                fluent.Text(
                  subtitle,
                  style: _subtitleTextStyle.copyWith(
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
