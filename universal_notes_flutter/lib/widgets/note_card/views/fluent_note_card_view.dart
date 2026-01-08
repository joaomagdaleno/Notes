import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// A Windows-specific view for the note list item (card).
class FluentNoteCardView extends StatelessWidget {
  /// Creates a [FluentNoteCardView].
  const FluentNoteCardView({
    required this.note,
    required this.plainTextContent,
    required this.isHovered,
    required this.flyoutController,
    required this.dateFormat,
    required this.onTap,
    required this.onSecondaryTapUp,
    required this.onLongPressStart,
    required this.onHoverChanged,
    required this.onShowPreview,
    super.key,
  });

  /// The note to display in the card.
  final Note note;

  /// The plain text summary of the note content.
  final String plainTextContent;

  /// Whether the card is currently being hovered.
  final bool isHovered;

  /// Controller for the flyout menu.
  final fluent.FlyoutController flyoutController;

  /// Format for displaying the note's date.
  final DateFormat dateFormat;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback for secondary tap (right click).
  final void Function(TapUpDetails) onSecondaryTapUp;

  /// Callback when a long press starts.
  final void Function(LongPressStartDetails) onLongPressStart;

  /// Callback when the hover state changes.
  final void Function({required bool isHovered}) onHoverChanged;

  /// Callback to show the note preview.
  final VoidCallback onShowPreview;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    // ⚡ Bolt: Cache Typography to avoid multiple expensive lookups in the build
    // method.
    final typography = theme.typography;

    return fluent.FlyoutTarget(
      controller: flyoutController,
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapUp: onSecondaryTapUp,
        onLongPressStart: onLongPressStart,
        child: MouseRegion(
          onEnter: (_) => onHoverChanged(isHovered: true),
          onExit: (_) => onHoverChanged(isHovered: false),
          child: fluent.Card(
            backgroundColor: isHovered
                ? theme.selectionColor.withValues(alpha: 0.1)
                : theme.cardColor,
            child: Stack(
              children: [
                if (note.isFavorite)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Semantics(
                      label: 'Favorite',
                      child: fluent.Icon(
                        fluent.FluentIcons.favorite_star_fill,
                        color: theme.accentColor,
                        size: 16,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: typography.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          plainTextContent,
                          style: typography.body,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(note.date),
                        style: typography.caption,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: fluent.Tooltip(
                    message: 'Preview',
                    child: fluent.IconButton(
                      icon: const fluent.Icon(fluent.FluentIcons.view),
                      onPressed: onShowPreview,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
