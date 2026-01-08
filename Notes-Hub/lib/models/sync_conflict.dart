import 'package:notes_hub/models/note.dart';

/// Represents a synchronization conflict between local and remote notes.
class SyncConflict {
  /// Creates a new [SyncConflict] with the given local and remote notes.
  SyncConflict({
    required this.localNote,
    required this.remoteNote,
  }) : timestamp = DateTime.now();

  /// The local version of the note.
  final Note localNote;

  /// The remote version of the note.
  final Note remoteNote;

  /// The timestamp when the conflict was detected.
  final DateTime timestamp;
}
