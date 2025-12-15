import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

/// A service to handle database backup and restore.
class BackupService {
  /// Exports the entire database content to a JSON file.
  /// Returns the path of the saved file.
  Future<String> exportDatabaseToJson() async {
    final noteRepository = NoteRepository.instance;

    // 1. Fetch all data from the database.
    final folders = await noteRepository.getAllFolders();
    // We need to fetch all notes, regardless of folder.
    final notes = await noteRepository.getAllNotes();

    final allVersions = <NoteVersion>[];
    for (final note in notes) {
      final versions = await noteRepository.getNoteVersions(note.id);
      allVersions.addAll(versions);
    }

    // 2. Structure the data into a single JSON object.
    final backupData = {
      'folders': folders.map((f) => f.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'note_versions': allVersions.map((v) => v.toMap()).toList(),
    };

    final jsonString = json.encode(backupData);

    // 3. Find the user's documents directory and save the file.
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/universal_notes_backup.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return filePath;
  }
}
