import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notes_hub/models/note.dart';

/// A Material Design view for the note list item (card).
class MaterialNoteCardView extends StatelessWidget {
  /// Creates a [MaterialNoteCardView].
  const MaterialNoteCardView({
    required this.note,
    required this.plainTextContent,
    required this.isHovered,
    required this.dateFormat,
    required this.onTap,
    required this.onLongPress,
    required this.onHoverChanged,
    required this.onFavorite,
    required this.onTrash,
    super.key,
  });

  /// The note to display in the card.
  final Note note;

  /// The plain text summary of the note content.
  final String plainTextContent;

  /// Whether the card is currently being hovered.
  final bool isHovered;

  /// Format for displaying the note's date.
  final DateFormat dateFormat;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the card is long pressed.
  final VoidCallback onLongPress;

  /// Callback when the hover state changes.
  final void Function({required bool isHovered}) onHoverChanged;

  /// Callback to toggle the favorite status of the note.
  final void Function(Note)? onFavorite;

  /// Callback to move the note to trash.
  final void Function(Note)? onTrash;

  static final _gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.black.withAlpha(153),
        Colors.transparent,
        Colors.black.withAlpha(204),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  static final _favoriteBackgroundDecoration = BoxDecoration(
    color: Colors.amber,
    borderRadius: BorderRadius.circular(12),
  );

  static final _deleteBackgroundDecoration = BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(12),
  );

  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt: Cache TextTheme to avoid multiple expensive lookups in the build
    // method.
    final textTheme = Theme.of(context).textTheme;
    // ⚡ Bolt: Cache derived TextStyles. By hoisting these .copyWith() calls
    // out of the Text widgets, we create the style objects once per build,
    // reducing redundant allocations and improving build performance.
    final titleStyle = textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    final contentStyle = textTheme.bodySmall?.copyWith(
      color: Colors.white70,
      fontSize: 11,
    );
    final dateStyle = textTheme.bodySmall?.copyWith(
      color: Colors.white70,
      fontSize: 10,
    );

    final hasImage = note.imageUrl?.isNotEmpty ?? false;

    final card = Card(
      elevation: isHovered ? 8 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: MouseRegion(
        onEnter: (_) => onHoverChanged(isHovered: true),
        onExit: (_) => onHoverChanged(isHovered: false),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Semantics(
            label: note.title.isNotEmpty
                ? 'Nota: ${note.title}'
                : 'Nota Sem Título',
            hint: 'Modificado em ${dateFormat.format(note.lastModified)}',
            button: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  Image.network(
                    note.imageUrl!,
                    fit: BoxFit.cover,
                  ),
                Container(
                  decoration: _gradientDecoration,
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (note.isFavorite)
                        const Align(
                          alignment: Alignment.topRight,
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      Text(
                        note.title,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (plainTextContent.isNotEmpty)
                        Flexible(
                          child: Text(
                            plainTextContent,
                            style: contentStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(note.lastModified),
                            style: dateStyle,
                          ),
                          if (note.isInTrash && note.trashedAt != null) ...[
                            () {
                              final daysLeft = 30 -
                                  DateTime.now()
                                      .difference(note.trashedAt!)
                                      .inDays;
                              return Text(
                                '$daysLeft days left',
                                style: dateStyle?.copyWith(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }(),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (onFavorite == null && onTrash == null) {
      return card;
    }

    return Dismissible(
      key: Key(note.id),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onFavorite?.call(note);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          onTrash?.call(note);
          return false;
        }
        return false;
      },
      background: Container(
        decoration: _favoriteBackgroundDecoration,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          note.isFavorite ? Icons.star_border : Icons.star,
          color: Colors.white,
          size: 32,
        ),
      ),
      secondaryBackground: Container(
        decoration: _deleteBackgroundDecoration,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: card,
    );
  }
}
