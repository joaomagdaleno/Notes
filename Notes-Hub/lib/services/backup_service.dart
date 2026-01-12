import 'dart:convert';
import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:notes_hub/models/folder.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/note_version.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The mode for restoring a backup.
enum RestoreMode {
  /// Merges the backup with existing data (skips conflicts).
  merge,

  /// Replaces all existing data with the backup.
  replace,
}

/// The result of a backup restore operation.
class RestoreResult {
  /// Creates a new [RestoreResult].
  const RestoreResult({
    required this.notesImported,
    required this.foldersImported,
    required this.versionsImported,
    required this.conflictsSkipped,
    this.errors = const [],
  });

  /// The number of notes imported.
  final int notesImported;

  /// The number of folders imported.
  final int foldersImported;

  /// The number of note versions imported.
  final int versionsImported;

  /// The number of items skipped due to conflicts (in merge mode).
  final int conflictsSkipped;

  /// List of errors encountered during restore.
  final List<String> errors;

  /// Returns true if the restore was successful (no errors).
  bool get isSuccess => errors.isEmpty;

  /// Returns a summary string of the restore operation.
  String get summary {
    final parts = <String>[];
    if (notesImported > 0) parts.add('$notesImported notas');
    if (foldersImported > 0) parts.add('$foldersImported pastas');
    if (versionsImported > 0) parts.add('$versionsImported versões');
    if (conflictsSkipped > 0) parts.add('$conflictsSkipped ignorados');
    return parts.isEmpty ? 'Nenhum item importado' : parts.join(', ');
  }
}

/// A service to handle encrypted database backup and restore.
class BackupService {
  BackupService._();

  /// The singleton instance of [BackupService].
  static BackupService instance = BackupService._();

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
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
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
  Future<RestoreResult> importBackup(
    File file,
    String password, {
    RestoreMode mode = RestoreMode.merge,
  }) async {
    final noteRepository = NoteRepository.instance;
    final errors = <String>[];
    var notesImported = 0;
    var foldersImported = 0;
    var versionsImported = 0;
    var conflictsSkipped = 0;

    try {
      final content = await file.readAsString();
      final backupWrapper = json.decode(content) as Map<String, dynamic>;

      final iv = IV.fromBase64(backupWrapper['iv'] as String);
      final encryptedData = backupWrapper['data'] as String;

      final key = Key.fromUtf8(password.padRight(32).substring(0, 32));
      final encrypter = Encrypter(AES(key));

      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      final data = json.decode(decrypted) as Map<String, dynamic>;

      // Validate structure
      if (!data.containsKey('notes')) {
        return const RestoreResult(
          notesImported: 0,
          foldersImported: 0,
          versionsImported: 0,
          conflictsSkipped: 0,
          errors: ['Arquivo de backup inválido: campo "notes" não encontrado'],
        );
      }

      // If replace mode, clear existing data first
      if (mode == RestoreMode.replace) {
        await clearAllData(noteRepository);
      }

      // Import folders first (notes may depend on them)
      final foldersData = data['folders'] as List<dynamic>? ?? [];
      for (final folderMap in foldersData) {
        try {
          final folder = Folder.fromMap(folderMap as Map<String, dynamic>);

          if (mode == RestoreMode.merge) {
            // Check if folder already exists
            final existingFolders = await noteRepository.getAllFolders();
            final exists = existingFolders.any((f) => f.id == folder.id);
            if (exists) {
              conflictsSkipped++;
              continue;
            }
          }

          await noteRepository.insertFolder(folder);
          foldersImported++;
        } on Exception catch (e) {
          errors.add('Erro ao importar pasta: $e');
        }
      }

      // Import notes
      final notesData = data['notes'] as List<dynamic>? ?? [];
      for (final noteMap in notesData) {
        try {
          final note = Note.fromMap(noteMap as Map<String, dynamic>);

          if (mode == RestoreMode.merge) {
            // Check if note already exists
            try {
              await noteRepository.getNoteWithContent(note.id);
              // Note exists, skip
              conflictsSkipped++;
              continue;
            } on Exception {
              // Note doesn't exist, proceed with import
            }
          }

          await noteRepository.insertNote(note);
          notesImported++;
        } on Exception catch (e) {
          errors.add('Erro ao importar nota: $e');
        }
      }

      // Import note versions
      final versionsData = data['note_versions'] as List<dynamic>? ?? [];
      for (final versionMap in versionsData) {
        try {
          final version = NoteVersion.fromMap(
            versionMap as Map<String, dynamic>,
          );

          if (mode == RestoreMode.merge) {
            // Check if version already exists
            final existingVersions = await noteRepository.getNoteVersions(
              version.noteId,
            );
            final exists = existingVersions.any((v) => v.id == version.id);
            if (exists) {
              conflictsSkipped++;
              continue;
            }
          }

          await noteRepository.createNoteVersion(version);
          versionsImported++;
        } on Exception catch (e) {
          errors.add('Erro ao importar versão: $e');
        }
      }

      return RestoreResult(
        notesImported: notesImported,
        foldersImported: foldersImported,
        versionsImported: versionsImported,
        conflictsSkipped: conflictsSkipped,
        errors: errors,
      );
    } on FormatException catch (e) {
      return RestoreResult(
        notesImported: 0,
        foldersImported: 0,
        versionsImported: 0,
        conflictsSkipped: 0,
        errors: ['Formato JSON/Criptografia inválido: $e'],
      );
    } on Exception catch (e) {
      return RestoreResult(
        notesImported: notesImported,
        foldersImported: foldersImported,
        versionsImported: versionsImported,
        conflictsSkipped: conflictsSkipped,
        errors: [...errors, 'Erro inesperado: $e'],
      );
    }
  }

  /// Clears all data from the database.
  Future<void> clearAllData(NoteRepository repository) async {
    // Get all notes and delete them
    final notes = await repository.getAllNotes();
    for (final note in notes) {
      await repository.deleteNotePermanently(note.id);
    }

    // Get all folders and delete them
    final folders = await repository.getAllFolders();
    for (final folder in folders) {
      await repository.deleteFolder(folder.id);
    }
  }
}
