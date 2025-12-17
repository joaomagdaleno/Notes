import 'dart:async';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _noteRepository = NoteRepository.instance;
  final _firestoreRepository = FirestoreRepository();

  // StreamControllers to broadcast local data changes
  final _notesController = StreamController<List<Note>>.broadcast();
  final _foldersController = StreamController<List<Folder>>.broadcast();

  Stream<List<Note>> get notesStream => _notesController.stream;
  Stream<List<Folder>> get foldersStream => _foldersController.stream;

  /// Initial fetch from local DB to populate streams
  Future<void> init() async {
    await refreshLocalData();
    // Start background sync
    _startBackgroundSync();
    // Try to push local changes
    unawaited(syncUp());
  }

  /// Re-reads data from SQLite and emits to streams
  Future<void> refreshLocalData({
    String? folderId,
    String? tagId,
    bool? isFavorite,
    bool? isInTrash,
  }) async {
    final notes = await _noteRepository.getAllNotes(
      folderId: folderId,
      tagId: tagId,
      isFavorite: isFavorite,
      isInTrash: isInTrash,
    );
    _notesController.add(notes);

    final folders = await _noteRepository.getAllFolders();
    _foldersController.add(folders);
  }

  // --- Synchronization Logic ---

  StreamSubscription<List<Note>>? _remoteSubscription;

  void _startBackgroundSync() {
    // Listen to remote changes (Firestore -> SQLite)
    _remoteSubscription = _firestoreRepository.notesStream().listen((
      remoteNotes,
    ) async {
      await _syncDown(remoteNotes);
    });
  }

  /// Syncs remote changes to local database (Firestore -> SQLite)
  Future<void> _syncDown(List<Note> remoteNotes) async {
    for (var remoteNote in remoteNotes) {
      Note? localNote;
      try {
        localNote = await _noteRepository.getNoteWithContent(remoteNote.id);
      } catch (_) {
        // Local note not found
      }

      // If local doesn't exist, or remote is newer, update local
      // Using UTC check to be safe, assuming Note model handles Timezone or stores UTC
      if (localNote == null ||
          remoteNote.lastModified.toUtc().isAfter(
            localNote.lastModified.toUtc(),
          )) {
        String content = remoteNote.content;

        // Fetch full content if needed (heuristic check)
        if (content.length < 100) {
          final fullContent = await _firestoreRepository.getNoteContent(
            remoteNote.id,
          );
          if (fullContent.isNotEmpty) {
            content = fullContent;
          }
        }

        final noteToSave = remoteNote.copyWith(content: content);

        if (localNote == null) {
          await _noteRepository.insertNote(noteToSave);
        } else {
          await _noteRepository.updateNote(noteToSave);
        }
      }
    }
    // After processing remote updates, refresh the UI streams
    await refreshLocalData();
  }

  /// Syncs local changes to Firestore (SQLite -> Firestore)
  Future<void> syncUp() async {
    // Basic strategy: Try to push all local notes.
    // Optimization needed: Only push dirty.
    // For now, we iterate and try to update/create.
    final localNotes = await _noteRepository.getAllNotes();
    for (final note in localNotes) {
      await syncUpNote(note);
    }
  }

  /// Uploads a local note to Firestore
  Future<void> syncUpNote(Note note) async {
    // This uses the split content logic we implemented in FirestoreRepository
    if (note.id.isEmpty) {
      // Create
      await _firestoreRepository.addNote(
        title: note.title,
        content: note.content,
      );
    } else {
      // Update
      await _firestoreRepository.updateNote(note);
    }
  }

  void dispose() {
    _remoteSubscription?.cancel();
    _notesController.close();
    _foldersController.close();
  }
}
