import 'package:universal_notes_flutter/models/note.dart';

class SyncConflict {

  SyncConflict({
    required this.localNote,
    required this.remoteNote,
  }) : timestamp = DateTime.now();
  final Note localNote;
  final Note remoteNote;
  final DateTime timestamp;
}
