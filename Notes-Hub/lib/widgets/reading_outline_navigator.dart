import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget for navigating document outline (headings).
///
/// Displays a list of headings with collapse/expand functionality
/// and animated scrolling to selected sections.
class ReadingOutlineNavigator extends StatefulWidget {
  /// Creates a new [ReadingOutlineNavigator].
  const ReadingOutlineNavigator({
    required this.headings,
    required this.onHeadingTap,
    this.currentHeadingIndex,
    this.progressPercent,
    super.key,
  });

  /// List of document headings.
  final List<OutlineHeading> headings;

  /// Callback when a heading is tapped.
  final ValueChanged<OutlineHeading> onHeadingTap;

  /// Currently active heading index.
  final int? currentHeadingIndex;

  /// Reading progress percentage (0.0 to 1.0).
  final double? progressPercent;

  @override
  State<ReadingOutlineNavigator> createState() =>
      _ReadingOutlineNavigatorState();
}

class _ReadingOutlineNavigatorState extends State<ReadingOutlineNavigator> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentNavigator(context);
    } else {
      return _buildMaterialNavigator(context);
    }
  }

  Widget _buildFluentNavigator(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Contents', style: theme.typography.subtitle),
                const Spacer(),
                if (widget.progressPercent != null)
                  Text(
                    '${(widget.progressPercent! * 100).toInt()}%',
                    style: theme.typography.caption?.copyWith(
                      color: theme.accentColor,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.progressPercent != null)
            fluent.ProgressBar(value: widget.progressPercent! * 100),
          const Divider(height: 1),
          Expanded(
            child: widget.headings.isEmpty
                ? Center(
                    child: Text(
                      'No headings found',
                      style: theme.typography.body,
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.headings.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final heading = widget.headings[index];
                      final isActive = widget.currentHeadingIndex == index;
                      final hasChildren = _hasChildren(index);
                      final isExpanded = _expandedIndices.contains(index);
                      final isVisible = _isVisible(index);

                      if (!isVisible) return const SizedBox.shrink();

                      return _FluentHeadingTile(
                        heading: heading,
                        isActive: isActive,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        onTap: () => widget.onHeadingTap(heading),
                        onExpandToggle:
                            hasChildren ? () => _toggleExpanded(index) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialNavigator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Contents', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (widget.progressPercent != null)
                  Text(
                    '${(widget.progressPercent! * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.progressPercent != null)
            LinearProgressIndicator(
              value: widget.progressPercent,
              minHeight: 3,
            ),
          const Divider(height: 1),
          Expanded(
            child: widget.headings.isEmpty
                ? Center(
                    child: Text(
                      'No headings found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.headings.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final heading = widget.headings[index];
                      final isActive = widget.currentHeadingIndex == index;
                      final hasChildren = _hasChildren(index);
                      final isExpanded = _expandedIndices.contains(index);
                      final isVisible = _isVisible(index);

                      if (!isVisible) return const SizedBox.shrink();

                      return _MaterialHeadingTile(
                        heading: heading,
                        isActive: isActive,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        onTap: () => widget.onHeadingTap(heading),
                        onExpandToggle:
                            hasChildren ? () => _toggleExpanded(index) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _hasChildren(int index) {
    if (index >= widget.headings.length - 1) return false;
    final currentLevel = widget.headings[index].level;
    final nextLevel = widget.headings[index + 1].level;
    return nextLevel > currentLevel;
  }

  bool _isVisible(int index) {
    if (index == 0) return true;

    final heading = widget.headings[index];
    for (var i = index - 1; i >= 0; i--) {
      final parent = widget.headings[i];
      if (parent.level < heading.level) {
        if (!_expandedIndices.contains(i)) {
          return false;
        }
        break;
      }
    }
    return true;
  }

  void _toggleExpanded(int index) {
    setState(() {
      if (_expandedIndices.contains(index)) {
        _expandedIndices.remove(index);
      } else {
        _expandedIndices.add(index);
      }
    });
  }
}

class _FluentHeadingTile extends StatelessWidget {
  const _FluentHeadingTile({
    required this.heading,
    required this.isActive,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    this.onExpandToggle,
  });

  final OutlineHeading heading;
  final bool isActive;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onExpandToggle;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    final indent = (heading.level - 1) * 16.0;

    return fluent.HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        return Container(
          padding: EdgeInsets.only(
            left: 16 + indent,
            right: 8,
            top: 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? theme.accentColor.withValues(alpha: 0.1)
                : states.isHovered
                    ? theme.resources.subtleFillColorSecondary
                    : null,
            border: isActive
                ? Border(
                    left: BorderSide(color: theme.accentColor, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              if (hasChildren)
                GestureDetector(
                  onTap: onExpandToggle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      isExpanded
                          ? fluent.FluentIcons.chevron_down
                          : fluent.FluentIcons.chevron_right,
                      size: 12,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  heading.text,
                  style: theme.typography.body?.copyWith(
                    fontWeight: heading.level == 1
                        ? FontWeight.bold
                        : heading.level == 2
                            ? FontWeight.w600
                            : FontWeight.normal,
                    color: isActive ? theme.accentColor : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaterialHeadingTile extends StatelessWidget {
  const _MaterialHeadingTile({
    required this.heading,
    required this.isActive,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    this.onExpandToggle,
  });

  final OutlineHeading heading;
  final bool isActive;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onExpandToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indent = (heading.level - 1) * 16.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 16 + indent,
          right: 8,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            if (hasChildren)
              GestureDetector(
                onTap: onExpandToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                heading.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: heading.level == 1
                      ? FontWeight.bold
                      : heading.level == 2
                          ? FontWeight.w600
                          : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a heading in the document outline.
@immutable
class OutlineHeading {
  /// Creates a new [OutlineHeading].
  const OutlineHeading({
    required this.text,
    required this.level,
    required this.position,
  });

  /// The heading text.
  final String text;

  /// Heading level (1 = H1, 2 = H2, etc.).
  final int level;

  /// Character position in the document.
  final int position;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OutlineHeading &&
        other.text == text &&
        other.level == level &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(text, level, position);
}
