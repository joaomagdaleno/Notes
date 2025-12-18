import 'package:universal_notes_flutter/models/note.dart';

class SyncConflict {
  final Note localNote;
  final Note remoteNote;
  final DateTime timestamp;

  SyncConflict({
    required this.localNote,
    required this.remoteNote,
  }) : timestamp = DateTime.now();
}
