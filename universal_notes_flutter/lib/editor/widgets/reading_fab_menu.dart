import 'package:flutter/material.dart';

/// FAB menu for Zen mode reading controls.
class ReadingFabMenu extends StatefulWidget {
  /// Creates a new [ReadingFabMenu].
  const ReadingFabMenu({
    required this.onSettingsTap,
    required this.onOutlineTap,
    required this.onBookmarksTap,
    required this.onAddBookmarkTap,
    required this.onScrollToTopTap,
    required this.onSearchTap,
    this.onNextTap,
    this.onPrevTap,
    this.onNextPlanNote,
    this.onPrevPlanNote,
    super.key,
  });

  /// Callback when settings button is tapped.
  final VoidCallback? onSettingsTap;

  /// Callback when outline button is tapped.
  final VoidCallback? onOutlineTap;

  /// Callback when bookmarks button is tapped.
  final VoidCallback? onBookmarksTap;

  /// Callback when add bookmark button is tapped.
  final VoidCallback? onAddBookmarkTap;

  /// Callback when scroll to top button is tapped.
  final VoidCallback? onScrollToTopTap;

  /// Callback when next button is tapped (Smart Nav).
  final VoidCallback? onNextTap;

  /// Callback when previous button is tapped (Smart Nav).
  final VoidCallback? onPrevTap;

  /// Callback when next plan note button is tapped.
  final VoidCallback? onNextPlanNote;

  /// Callback when previous plan note button is tapped.
  final VoidCallback? onPrevPlanNote;

  /// Callback when search button is tapped.
  final VoidCallback onSearchTap;

  @override
  State<ReadingFabMenu> createState() => _ReadingFabMenuState();
}

class _ReadingFabMenuState extends State<ReadingFabMenu> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return FloatingActionButton.small(
        heroTag: 'zen_reading_menu',
        onPressed: () => setState(() => _isExpanded = true),
        child: const Icon(Icons.import_contacts),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Navigation Controls
        if (widget.onPrevPlanNote != null || widget.onNextPlanNote != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onPrevPlanNote != null)
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: widget.onPrevPlanNote,
                    tooltip: 'Previous Note in Plan',
                    iconSize: 20,
                  ),
                if (widget.onNextPlanNote != null)
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: widget.onNextPlanNote,
                    tooltip: 'Next Note in Plan',
                    iconSize: 20,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (widget.onPrevTap != null || widget.onNextTap != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onPrevTap != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onPrevTap,
                    tooltip: 'Previous (Smart)',
                    iconSize: 20,
                  ),
                if (widget.onNextTap != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: widget.onNextTap,
                    tooltip: 'Next (Smart)',
                    iconSize: 20,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Menu Items
        _buildMenuItem(
          icon: Icons.search,
          label: 'Search',
          onTap: () {
            widget.onSearchTap();
            setState(() => _isExpanded = false);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.settings,
          label: 'Settings',
          onTap: () {
            widget.onSettingsTap?.call();
            setState(() => _isExpanded = false);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.format_list_bulleted,
          label: 'Outline',
          onTap: () {
            widget.onOutlineTap?.call();
            setState(() => _isExpanded = false);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.bookmark,
          label: 'Bookmarks',
          onTap: () {
            widget.onBookmarksTap?.call();
            setState(() => _isExpanded = false);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.bookmark_add,
          label: 'Add Bookmark',
          onTap: () {
            widget.onAddBookmarkTap?.call();
            setState(() => _isExpanded = false);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuItem(
          icon: Icons.vertical_align_top,
          label: 'Top',
          onTap: () {
            widget.onScrollToTopTap?.call();
            setState(() => _isExpanded = false);
          },
        ),
        const SizedBox(height: 16),

        // Main FAB
        FloatingActionButton.small(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: 'zen_reading_$label',
          onPressed: onTap,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.primary,
          elevation: 2,
          child: Icon(icon, size: 20),
        ),
      ],
    );
  }
}
