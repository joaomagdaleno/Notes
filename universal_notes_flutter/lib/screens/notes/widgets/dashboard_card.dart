import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
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
