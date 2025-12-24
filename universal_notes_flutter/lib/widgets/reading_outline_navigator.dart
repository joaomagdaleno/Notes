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
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Contents',
                  style: theme.textTheme.titleLarge,
                ),
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

          // Progress bar
          if (widget.progressPercent != null)
            LinearProgressIndicator(
              value: widget.progressPercent,
              minHeight: 3,
            ),

          const Divider(height: 1),

          // Headings list
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

                      return _HeadingTile(
                        heading: heading,
                        isActive: isActive,
                        hasChildren: hasChildren,
                        isExpanded: isExpanded,
                        onTap: () => widget.onHeadingTap(heading),
                        onExpandToggle: hasChildren
                            ? () => _toggleExpanded(index)
                            : null,
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

    // Find parent heading
    final heading = widget.headings[index];
    for (var i = index - 1; i >= 0; i--) {
      final parent = widget.headings[i];
      if (parent.level < heading.level) {
        // This is the parent - check if it's expanded
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

class _HeadingTile extends StatelessWidget {
  const _HeadingTile({
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
