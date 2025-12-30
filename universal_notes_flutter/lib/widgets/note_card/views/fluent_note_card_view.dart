import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/models/note.dart';

class FluentNoteCardView extends StatelessWidget {
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

  final Note note;
  final String plainTextContent;
  final bool isHovered;
  final fluent.FlyoutController flyoutController;
  final DateFormat dateFormat;
  final VoidCallback? onTap;
  final void Function(TapUpDetails) onSecondaryTapUp;
  final void Function(LongPressStartDetails) onLongPressStart;
  final void Function(bool) onHoverChanged;
  final VoidCallback onShowPreview;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return fluent.FlyoutTarget(
      controller: flyoutController,
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapUp: onSecondaryTapUp,
        onLongPressStart: onLongPressStart,
        child: MouseRegion(
          onEnter: (_) => onHoverChanged(true),
          onExit: (_) => onHoverChanged(false),
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
                        style: theme.typography.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          plainTextContent,
                          style: theme.typography.body,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFormat.format(note.date),
                        style: theme.typography.caption,
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
