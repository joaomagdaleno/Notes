import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/note_event.dart';
import 'package:notes_hub/services/tracing_service.dart';

/// A repository for interacting with Firestore.
class FirestoreRepository {
  /// Creates a [FirestoreRepository] instance.
  ///
  /// Uses the default [FirebaseFirestore.instance] unless explicit
  /// dependency injection is used.
  FirestoreRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : firestore = firestore ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance {
    _initCollections();
  }

  FirestoreRepository._internal()
      : firestore = FirebaseFirestore.instance,
        auth = FirebaseAuth.instance {
    _initCollections();
  }

  /// The Firestore instance.
  FirebaseFirestore firestore;

  /// The FirebaseAuth instance.
  FirebaseAuth auth;

  /// The singleton instance of [FirestoreRepository].
  // ignore: prefer_constructors_over_static_methods
  static FirestoreRepository get instance {
    if (_instance == null) {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        _instance = FirestoreRepository();
      } else {
        // Fallback for Windows/Linux or if specifically mocked
        _instance = FirestoreRepository._internal();
      }
    }
    return _instance!;
  }

  /// Sets the singleton instance for testing.
  @visibleForTesting
  static set instance(FirestoreRepository? value) => _instance = value;

  static FirestoreRepository? _instance;

  void _initCollections() {
    _notesCollection = firestore.collection('notes');
    _usersCollection = firestore.collection('users');
    _foldersCollection = firestore.collection('folders');
    _userMetadataCollection = firestore.collection('metadata');
  }

  late final CollectionReference<Map<String, dynamic>> _notesCollection;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>> _foldersCollection;
  late final CollectionReference<Map<String, dynamic>> _userMetadataCollection;

  /// Returns the current authenticated user.
  User? get currentUser => auth.currentUser;

  /// Adds learned words to the user's dictionary in Firestore.
  Future<void> addDictionaryWords(
    String userId,
    List<Map<String, dynamic>> words,
  ) async {
    final batch = firestore.batch();
    final userDictRef = _usersCollection.doc(userId).collection('dictionary');

    for (final wordMap in words) {
      final word = wordMap['word'] as String;
      final docRef = userDictRef.doc(word);

      batch.set(
        docRef,
        {
          'word': word,
          'frequency': FieldValue.increment(wordMap['frequency'] as int),
          'lastUsed': wordMap['lastUsed'],
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  /// Retrieves the user's dictionary from Firestore.
  Future<List<Map<String, dynamic>>> getDictionaryWords(String userId) async {
    final snapshot =
        await _usersCollection.doc(userId).collection('dictionary').get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Returns a stream of notes filtered by [isFavorite], [isInTrash], and
  /// [tag], with support for cursor-based pagination via [lastDocument].
  Stream<List<Note>> notesStream({
    bool? isFavorite,
    bool? isInTrash,
    String? tag,
    String? folderId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) {
    final user = auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    var query = _notesCollection.where('memberIds', arrayContains: user.uid);

    if (isFavorite != null) {
      query = query.where('isFavorite', isEqualTo: isFavorite);
    }
    if (tag != null) {
      query = query.where('tags', arrayContains: tag);
    }
    if (folderId != null) {
      query = query.where('folderId', isEqualTo: folderId);
    }

    if (isInTrash != null) {
      query = query.where('isInTrash', isEqualTo: isInTrash);
    } else {
      query = query.where('isInTrash', isEqualTo: false);
    }

    query = query.orderBy('lastModified', descending: true);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(Note.fromFirestore).toList();
    });
  }

  /// Adds a new note with [title] and [content].
  Future<Note> addNote({required String title, required String content}) async {
    final span = TracingService().startSpan('FirestoreRepository.addNote');
    try {
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      final now = DateTime.now();

      final snippet =
          content.length > 100 ? content.substring(0, 100) : content;

      final docRef = await _notesCollection.add({
        'title': title,
        'content': snippet,
        'createdAt': Timestamp.fromDate(now),
        'lastModified': Timestamp.fromDate(now),
        'ownerId': user.uid,
        'collaborators': <String, dynamic>{},
        'tags': <String>[],
        'memberIds': [user.uid],
        'isFavorite': false,
        'isInTrash': false,
      });

      await docRef.collection('content').doc('main').set({
        'fullContent': content,
      });

      final snapshot = await docRef.get();

      return Note.fromFirestore(snapshot);
    } finally {
      span.end();
    }
  }

  Future<void> _updateUserTags(String userId, List<String> tags) async {
    await _userMetadataCollection.doc(userId).set(
      {
        'tags': FieldValue.arrayUnion(tags),
      },
      SetOptions(merge: true),
    );
  }

  /// Updates an existing [note].
  Future<void> updateNote(Note note) async {
    final snippet = note.content.length > 100
        ? note.content.substring(0, 100)
        : note.content;

    final noteData = note.toFirestore();
    noteData['content'] = snippet;

    await _notesCollection.doc(note.id).update(noteData);

    if (note.tags.isNotEmpty) {
      final user = auth.currentUser;
      if (user != null) {
        await _updateUserTags(user.uid, note.tags);
      }
    }

    await _notesCollection.doc(note.id).collection('content').doc('main').set(
      {
        'fullContent': note.content,
      },
      SetOptions(merge: true),
    );
  }

  /// Deletes a note by its [noteId].
  Future<void> deleteNote(String noteId) async {
    await _notesCollection
        .doc(noteId)
        .collection('content')
        .doc('main')
        .delete();
    await _notesCollection.doc(noteId).delete();
  }

  /// Deletes multiple notes by their IDs in a batch.
  Future<void> deleteNotes(List<String> noteIds) async {
    final batch = firestore.batch();
    for (final id in noteIds) {
      batch.delete(_notesCollection.doc(id));
    }
    await batch.commit();
  }

  /// Returns a stream of all unique tags used by the current user.
  Stream<List<String>> getAllTagsStream() {
    final user = auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _userMetadataCollection.doc(user.uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      if (data == null) return [];
      final tags = (data['tags'] as List<dynamic>?)?.cast<String>() ?? [];
      return tags..sort();
    });
  }

  /// Shares a note with [email] giving them [permission].
  Future<bool> shareNoteWithEmail(
    String noteId,
    String email,
    String permission,
  ) async {
    final currentUser = auth.currentUser;
    if (currentUser != null && currentUser.email == email) {
      return false;
    }

    final querySnapshot =
        await _usersCollection.where('email', isEqualTo: email).limit(1).get();
    if (querySnapshot.docs.isEmpty) {
      return false;
    }
    final collaboratorId = querySnapshot.docs.first.id;

    await _notesCollection.doc(noteId).update({
      'collaborators.$collaboratorId': permission,
      'memberIds': FieldValue.arrayUnion([collaboratorId]),
    });
    return true;
  }

  /// Removes a collaborator from a note.
  Future<void> unshareNoteWithCollaborator(
    String noteId,
    String collaboratorId,
  ) async {
    await _notesCollection.doc(noteId).update({
      'collaborators.$collaboratorId': FieldValue.delete(),
      'memberIds': FieldValue.arrayRemove([collaboratorId]),
    });
  }

  /// Creates a user document in Firestore.
  Future<void> createUser(User user) async {
    await _usersCollection.doc(user.uid).set(
      {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Creates a new folder.
  Future<void> createFolder(String name) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _foldersCollection.add({
      'name': name,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of folders for the current user.
  Stream<List<Map<String, dynamic>>> getFoldersStream() {
    final user = auth.currentUser;
    if (user == null) return Stream.value([]);

    return _foldersCollection
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Deletes a folder.
  Future<void> deleteFolder(String folderId) async {
    await _foldersCollection.doc(folderId).delete();
  }

  /// Retrieves all folders (for backup).
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final user = auth.currentUser;
    if (user == null) return [];

    final snapshot =
        await _foldersCollection.where('ownerId', isEqualTo: user.uid).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Fetches the full content of a note from the subcollection.
  Future<String> getNoteContent(String noteId) async {
    try {
      final doc = await _notesCollection
          .doc(noteId)
          .collection('content')
          .doc('main')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['fullContent'] as String? ?? '';
      }
      return '';
    } on Exception catch (_) {
      return '';
    }
  }

  /// Retrieves all notes (for backup).
  Future<List<Note>> getAllNotes() async {
    final user = auth.currentUser;
    if (user == null) return [];
    final snapshot =
        await _notesCollection.where('ownerId', isEqualTo: user.uid).get();
    return snapshot.docs.map(Note.fromFirestore).toList();
  }

  /// Retrieves note versions (for backup).
  Future<List<dynamic>> getNoteVersions(String noteId) async {
    return [];
  }

  /// Pushes a single [event] to Firestore.
  Future<void> addNoteEvent(NoteEvent event) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _notesCollection
        .doc(event.noteId)
        .collection('events')
        .doc(event.id)
        .set(event.toFirestore());
  }

  /// Pushes multiple [events] to Firestore in a batch.
  Future<void> addNoteEvents(List<NoteEvent> events) async {
    if (events.isEmpty) return;
    final user = auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final batch = firestore.batch();
    for (final event in events) {
      final docRef =
          _notesCollection.doc(event.noteId).collection('events').doc(event.id);
      batch.set(docRef, event.toFirestore());
    }
    await batch.commit();
  }

  /// Returns a stream of events for a note, ordered by timestamp.
  Stream<List<NoteEvent>> getNoteEventsStream(String noteId) {
    return _notesCollection
        .doc(noteId)
        .collection('events')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NoteEvent.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Fetches all remote events for a note after [sinceTimestamp].
  Future<List<NoteEvent>> getNoteEventsSince(
    String noteId,
    DateTime sinceTimestamp,
  ) async {
    final snapshot = await _notesCollection
        .doc(noteId)
        .collection('events')
        .where(
          'timestamp',
          isGreaterThan: sinceTimestamp.millisecondsSinceEpoch,
        )
        .orderBy('timestamp')
        .get();

    return snapshot.docs.map((doc) {
      return NoteEvent.fromFirestore(doc.data(), doc.id);
    }).toList();
  }

  /// Updates the current user's cursor position for a specific note.
  Future<void> updateCursorPosition(
    String noteId,
    int baseOffset,
    int extentOffset,
    String displayName,
    int colorValue,
  ) async {
    final user = auth.currentUser;
    if (user == null) return;

    await _notesCollection.doc(noteId).collection('cursors').doc(user.uid).set({
      'userId': user.uid,
      'displayName': displayName,
      'colorValue': colorValue,
      'baseOffset': baseOffset,
      'extentOffset': extentOffset,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of active cursors for a note.
  Stream<List<Map<String, dynamic>>> listenToCursors(String noteId) {
    return _notesCollection.doc(noteId).collection('cursors').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Removes the current user's cursor from a note.
  Future<void> removeCursor(String noteId) async {
    final user = auth.currentUser;
    if (user == null) return;
    await _notesCollection
        .doc(noteId)
        .collection('cursors')
        .doc(user.uid)
        .delete();
  }
}
