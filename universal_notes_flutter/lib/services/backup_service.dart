import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_version.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

/// A service to handle encrypted database backup and restore.
class BackupService {
  static final BackupService instance = BackupService._();
  BackupService._();

  /// Exports the entire database content to an encrypted JSON file.
  /// Returns the path of the saved file.
  Future<String> exportBackup(String password) async {
    final noteRepository = NoteRepository.instance;

    // 1. Fetch all data
    final folders = await noteRepository.getAllFolders();
    final notes = await noteRepository.getAllNotes();
    final allVersions = <NoteVersion>[];
    for (final note in notes) {
      final versions = await noteRepository.getNoteVersions(note.id);
      allVersions.addAll(versions);
    }

    final backupData = {
      'folders': folders.map((f) => f.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'note_versions': allVersions.map((v) => v.toMap()).toList(),
    };

    final jsonString = json.encode(backupData);

    // 2. Encryption
    final key = Key.fromUtf8(password.padRight(32).substring(0, 32));
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(jsonString, iv: iv);

    // 3. Save
    final directory = await getApplicationDocumentsDirectory();
    final filePath = p.join(directory.path, 'universal_notes_backup.enc');
    final file = File(filePath);

    final finalOutput = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };

    await file.writeAsString(json.encode(finalOutput));
    return filePath;
  }

  /// Imports and decrypts data from a backup file.
  Future<void> importBackup(File file, String password) async {
    final noteRepository = NoteRepository.instance;
    final content = await file.readAsString();
    final backupWrapper = json.decode(content) as Map<String, dynamic>;

    final iv = IV.fromBase64(backupWrapper['iv'] as String);
    final encryptedData = backupWrapper['data'] as String;

    final key = Key.fromUtf8(password.padRight(32).substring(0, 32));
    final encrypter = Encrypter(AES(key));

    final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
    final data = json.decode(decrypted) as Map<String, dynamic>;

    // Import Folders
    final foldersJson = data['folders'] as List<dynamic>;
    for (final _ in foldersJson) {
      // Logic for folder import... assuming NoteRepository has it
    }

    // Import Notes
    final notesJson = data['notes'] as List<dynamic>;
    for (final n in notesJson) {
      final note = Note.fromMap(n as Map<String, dynamic>);
      await noteRepository.insertNote(note);
    }

    // Import Versions
    final versionsJson = data['note_versions'] as List<dynamic>;
    for (final v in versionsJson) {
      final version = NoteVersion.fromMap(v as Map<String, dynamic>);
      await noteRepository.createNoteVersion(version);
    }
  }
}
