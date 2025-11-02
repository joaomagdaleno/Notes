import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final Function(Note) onSave;
  final bool isSelectionMode;
  final bool isSelected;
  final Function(String) onToggleSelection;
  final AuthService _authService = AuthService();

  NoteCard({
    super.key,
    required this.note,
    required this.onSave,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (isSelectionMode) {
          onToggleSelection(note.id);
        } else {
          if (note.isLocked) {
            final didAuthenticate = await _authService.authenticate();
            if (didAuthenticate) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      NoteEditorScreen(note: note, onSave: onSave),
                ),
              );
            }
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    NoteEditorScreen(note: note, onSave: onSave),
              ),
            );
          }
        }
      },
      onLongPress: () {
        onToggleSelection(note.id);
      },
      onSecondaryTap: () {
        onToggleSelection(note.id);
      },
      child: Card(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          note.contentPreview,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          note.isFavorite ? Icons.star : Icons.star_border,
                          color: note.isFavorite ? Colors.amber : Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          note.isFavorite = !note.isFavorite;
                          onSave(note);
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM. yyyy').format(note.date),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            if (note.isLocked)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
