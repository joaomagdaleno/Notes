import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/reading_bookmark.dart';
import 'package:intl/intl.dart';

/// Widget for managing reading bookmarks.
///
/// Displays a list of bookmarks with excerpts, creation dates,
/// and functionality to navigate or delete.
class ReadingBookmarksList extends StatelessWidget {
  /// Creates a new [ReadingBookmarksList].
  const ReadingBookmarksList({
    required this.bookmarks,
    required this.onBookmarkTap,
    required this.onBookmarkDelete,
    super.key,
  });

  /// List of bookmarks.
  final List<ReadingBookmark> bookmarks;

  /// Callback when a bookmark is tapped.
  final ValueChanged<ReadingBookmark> onBookmarkTap;

  /// Callback when a bookmark is deleted.
  final ValueChanged<ReadingBookmark> onBookmarkDelete;

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
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Bookmarks',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: bookmarks.isEmpty
                ? _buildEmptyState(theme)
                : _buildBookmarksList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(ThemeData theme) {
    final dateFormat = DateFormat.yMMMd().add_Hm();

    return ListView.builder(
      itemCount: bookmarks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return ListTile(
          leading: Icon(Icons.bookmark, color: theme.colorScheme.primary),
          title: Text(
            bookmark.name ?? 'Bookmark ${index + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookmark.excerpt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    bookmark.excerpt!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Text(
                dateFormat.format(bookmark.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => onBookmarkDelete(bookmark),
            tooltip: 'Remove bookmark',
          ),
          onTap: () => onBookmarkTap(bookmark),
        );
      },
    );
  }
}
