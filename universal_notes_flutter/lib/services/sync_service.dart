import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/sync_conflict.dart';
import 'package:universal_notes_flutter/models/sync_status.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';

/// A service that handles synchronization between local and remote storage.
class SyncService {
  SyncService._();

  /// The singleton instance of [SyncService].
  static SyncService instance = SyncService._();

  bool _isDisposed = false;
  Future<void>? _syncUpFuture;

  @visibleForTesting
  late NoteRepository noteRepository = NoteRepository.instance;
  @visibleForTesting
  late FirestoreRepository firestoreRepository = FirestoreRepository.instance;

  // StreamControllers to broadcast local data changes
  final _notesController = StreamController<List<Note>>.broadcast();
  final _foldersController = StreamController<List<Folder>>.broadcast();
  final _tagsController = StreamController<List<String>>.broadcast();
  final _conflictController = StreamController<SyncConflict>.broadcast();

  /// A broadcast stream of all notes.
  Stream<List<Note>> get notesStream => _notesController.stream;

  /// A broadcast stream of all folders.
  Stream<List<Folder>> get foldersStream => _foldersController.stream;

  /// A broadcast stream of all tags.
  Stream<List<String>> get tagsStream => _tagsController.stream;

  /// A broadcast stream of synchronization conflicts.
  Stream<SyncConflict> get conflictsStream => _conflictController.stream;

  /// Initial fetch from local DB to populate streams
  Future<void> init() async {
    _isDisposed = false;
    await _remoteSubscription?.cancel();
    await refreshLocalData();
    // Start background sync
    _startBackgroundSync();
    // Try to push local changes
    _syncUpFuture = syncUp();
  }

  /// Cancels subscriptions for testing.
  @visibleForTesting
  Future<void> reset() async {
    _isDisposed = true;
    await _remoteSubscription?.cancel();
    _remoteSubscription = null;
    await _syncUpFuture;
    _syncUpFuture = null;
  }

  /// Re-reads data from SQLite and emits to streams
  Future<void> refreshLocalData({
    String? folderId,
    String? tagId,
    bool? isFavorite,
    bool? isInTrash,
  }) async {
    final notes = await noteRepository.getAllNotes(
      folderId: folderId,
      tagId: tagId,
      isFavorite: isFavorite,
      isInTrash: isInTrash,
    );
    _notesController.add(notes);

    final folders = await noteRepository.getAllFolders();
    _foldersController.add(folders);

    final tags = await noteRepository.getAllTagNames();
    _tagsController.add(tags);
  }

  // --- Synchronization Logic ---

  StreamSubscription<List<Note>>? _remoteSubscription;

  void _startBackgroundSync() {
    // Listen to remote changes (Firestore -> SQLite)
    _remoteSubscription = firestoreRepository.notesStream().listen((
      remoteNotes,
    ) async {
      if (_isDisposed) return;
      await _syncDown(remoteNotes);
    });
  }

  /// Syncs remote changes to local database (Firestore -> SQLite)
  Future<void> _syncDown(List<Note> remoteNotes) async {
    for (final remoteNote in remoteNotes) {
      Note? localNote;
      try {
        localNote = await noteRepository.getNoteWithContent(remoteNote.id);
      } on Exception catch (_) {
        // Local note not found
      }

      // If local doesn't exist, or remote is newer, update local
      // Using UTC check to be safe, assuming Note model handles Timezone or
      // stores UTC.
      final remoteNewer =
          localNote == null ||
          remoteNote.lastModified.toUtc().isAfter(
            localNote.lastModified.toUtc(),
          );

      if (remoteNewer) {
        // CONFLICT DETECTION
        if (localNote != null &&
            localNote.syncStatus != SyncStatus.synced &&
            localNote.content != remoteNote.content) {
          // Both modified since last sync
          _conflictController.add(
            SyncConflict(localNote: localNote, remoteNote: remoteNote),
          );
          continue; // Skip automatic update for now, wait for resolution
        }

        var content = remoteNote.content;

        // Fetch full content if needed (heuristic check)
        if (content.length < 100) {
          final fullContent = await firestoreRepository.getNoteContent(
            remoteNote.id,
          );
          if (fullContent.isNotEmpty) {
            content = fullContent;
          }
        }

        final noteToSave = remoteNote.copyWith(
          content: content,
          syncStatus: SyncStatus.synced,
        );

        if (localNote == null) {
          await noteRepository.insertNote(noteToSave);
        } else {
          // Bypass regular updateNote to avoid setting modified status again
          await noteRepository.updateNoteContent(noteToSave);
        }
      } else if (localNote.syncStatus != SyncStatus.synced) {
        // Even if local is newer or same, if it was marked as synced
        // but is now same as remote we could verify here. For now,
        // assume if remote is NOT newer, but local is the same,
        // we can mark it as synced IF we just uploaded it.
      }
    }
    // After processing remote updates, refresh the UI streams
    await refreshLocalData();
  }

  /// Syncs local changes to Firestore (SQLite -> Firestore)
  Future<void> syncUp() async {
    if (_isDisposed) return;
    // Dirty Sync strategy: Only push local notes that are modified or local.
    final localNotes = await noteRepository.getUnsyncedNotes();
    for (final note in localNotes) {
      if (_isDisposed) break;
      await syncUpNote(note);
    }
  }

  /// Uploads a local note to Firestore
  Future<void> syncUpNote(Note note) async {
    // This uses the split content logic we implemented in
    // FirestoreRepository.
    if (note.syncStatus == SyncStatus.local) {
      // Create
      final newNote = await firestoreRepository.addNote(
        title: note.title,
        content: note.content,
      );
      // Update local note with Firestore ID and synced status
      await noteRepository.deleteNotePermanently(note.id); // Remove temp ID
      await noteRepository.insertNote(
        newNote.copyWith(syncStatus: SyncStatus.synced),
      );
    } else {
      // Update
      await firestoreRepository.updateNote(note);
      await noteRepository.updateNoteContent(
        note.copyWith(syncStatus: SyncStatus.synced),
      );
    }
  }

  // =========================================================================
  // Event-Based Sync Methods
  // =========================================================================

  /// Syncs local unsynced events to Firestore for a specific note.
  Future<void> syncUpEvents(String noteId) async {
    final localEvents = await noteRepository.getNoteEvents(noteId);

    // Filter to only unsynced events
    final unsyncedEvents = localEvents
        .where((e) => e.syncStatus == SyncStatus.local)
        .toList();

    if (unsyncedEvents.isEmpty) return;

    // Push to Firestore
    await firestoreRepository.addNoteEvents(unsyncedEvents);

    // Mark as synced locally
    for (final event in unsyncedEvents) {
      final syncedEvent = event.copyWith(syncStatus: SyncStatus.synced);
      await noteRepository.updateNoteEvent(syncedEvent);
    }
  }

  /// Pulls remote events for a note and merges into local DB.
  Future<void> syncDownEvents(String noteId) async {
    // Get last synced timestamp from local events
    final localEvents = await noteRepository.getNoteEvents(noteId);
    final lastLocalTimestamp = localEvents.isNotEmpty
        ? localEvents.last.timestamp
        : DateTime.fromMillisecondsSinceEpoch(0);

    // Fetch newer events from Firestore
    final remoteEvents = await firestoreRepository.getNoteEventsSince(
      noteId,
      lastLocalTimestamp,
    );

    // Filter out events we already have (by ID)
    final localIds = localEvents.map((e) => e.id).toSet();
    final newEvents = remoteEvents.where((e) => !localIds.contains(e.id));

    // Insert new events into local DB
    for (final event in newEvents) {
      await noteRepository.addNoteEvent(event);
    }
  }

  // =========================================================================
  // Dictionary Sync Methods
  // =========================================================================

  /// Syncs learned words to Firestore (automatic background sync).
  Future<void> syncDictionary() async {
    final user = firestoreRepository.currentUser;
    if (user == null) return;

    // Push unsynced words
    await _syncUpDictionary(user.uid);

    // Pull remote words
    await _syncDownDictionary(user.uid);
  }

  Future<void> _syncUpDictionary(String userId) async {
    final unsyncedWords = await noteRepository.getUnsyncedWords();
    if (unsyncedWords.isEmpty) return;

    // Push to Firestore
    await firestoreRepository.addDictionaryWords(userId, unsyncedWords);

    // Mark as synced
    final words = unsyncedWords.map((w) => w['word'] as String).toList();
    await noteRepository.markWordsSynced(words);
  }

  Future<void> _syncDownDictionary(String userId) async {
    final cloudWords = await firestoreRepository.getDictionaryWords(userId);
    await noteRepository.importWords(cloudWords);
  }

  /// Disposes of the controllers and subscriptions.
  void dispose() {
    unawaited(_remoteSubscription?.cancel());
    unawaited(_notesController.close());
    unawaited(_foldersController.close());
    unawaited(_conflictController.close());
  }
}
