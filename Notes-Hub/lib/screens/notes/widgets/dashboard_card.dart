import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// A card displayed on the dashboard with a title, subtitle, and icon.
class DashboardCard extends StatefulWidget {
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

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  // ⚡ Bolt: Base styles are static const to avoid re-creating them.
  static const _titleTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  static const _subtitleTextStyle = TextStyle(
    fontSize: 12,
  );

  // ⚡ Bolt: Cache computed styles to avoid re-creating them on every build.
  // This is more efficient than using .copyWith() inside the build method.
  late TextStyle _finalTitleTextStyle;
  late TextStyle _finalSubtitleTextStyle;

  @override
  void initState() {
    super.initState();
    _updateStyles();
  }

  @override
  void didUpdateWidget(DashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _updateStyles();
    }
  }

  void _updateStyles() {
    _finalTitleTextStyle = _titleTextStyle.copyWith(color: widget.color);
    _finalSubtitleTextStyle = _subtitleTextStyle.copyWith(
      color: widget.color.withValues(alpha: 0.7),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: fluent.HoverButton(
        onPressed: widget.onTap,
        builder: (context, states) {
          return fluent.Card(
            padding: const EdgeInsets.all(16),
            backgroundColor: states.isHovered
                ? widget.color.withValues(alpha: 0.15)
                : widget.color.withValues(alpha: 0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fluent.Icon(widget.icon, color: widget.color, size: 32),
                const SizedBox(height: 12),
                fluent.Text(
                  widget.title,
                  style: _finalTitleTextStyle,
                ),
                fluent.Text(
                  widget.subtitle,
                  style: _finalSubtitleTextStyle,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
