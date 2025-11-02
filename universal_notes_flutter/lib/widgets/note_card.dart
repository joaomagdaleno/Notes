import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import '../models/note.dart';
import 'context_menu_helper.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onSave;
  final Function(Note) onDelete;

  const NoteCard(
      {super.key,
      required this.note,
      required this.onSave,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(note: note, onSave: onSave),
          ),
        );
      },
      onLongPressStart: (details) {
        ContextMenuHelper.showContextMenu(
          context: context,
          position: details.globalPosition,
          note: note,
          onSave: onSave,
          onDelete: onDelete,
        );
      },
      child: Card(
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.contentPreview.isNotEmpty)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      note.contentPreview,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 5,
                    ),
                  ),
                ),
              if (note.contentPreview.isNotEmpty) const SizedBox(height: 8),
              Text(
                note.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d MMM. yyyy').format(note.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
