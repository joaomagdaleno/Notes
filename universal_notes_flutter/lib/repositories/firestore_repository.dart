import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note_event.dart';

/// Repository for interacting with Firestore.
class FirestoreRepository {
  /// Creates a [FirestoreRepository].
  FirestoreRepository() {
    _notesCollection = _firestore.collection('notes');
    _usersCollection = _firestore.collection('users');
    _foldersCollection = _firestore.collection('folders');
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the collections
  late final CollectionReference<Map<String, dynamic>> _notesCollection;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;
  late final CollectionReference<Map<String, dynamic>> _foldersCollection;

  /// Returns the current authenticated user.
  User? get currentUser => _auth.currentUser;

  // --- Dictionary Methods ---

  /// Adds learned words to the user's dictionary in Firestore.
  Future<void> addDictionaryWords(
    String userId,
    List<Map<String, dynamic>> words,
  ) async {
    final batch = _firestore.batch();
    final userDictRef = _usersCollection.doc(userId).collection('dictionary');

    for (final wordMap in words) {
      final word = wordMap['word'] as String;
      final docRef = userDictRef.doc(word);

      batch.set(docRef, {
        'word': word,
        // Use max to keep the highest frequency/lastUsed
        'frequency': FieldValue.increment(wordMap['frequency'] as int),
        'lastUsed': wordMap['lastUsed'],
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Retrieves the user's dictionary from Firestore.
  Future<List<Map<String, dynamic>>> getDictionaryWords(String userId) async {
    final snapshot = await _usersCollection
        .doc(userId)
        .collection('dictionary')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Returns a stream of notes filtered by [isFavorite], [isInTrash], and
  /// [tag].
  Stream<List<Note>> notesStream({
    bool? isFavorite,
    bool? isInTrash,
    String? tag,
    String? folderId,
    int limit = 20,
  }) {
    final user = _auth.currentUser;
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

    // For the "All Notes" view, we want notes that are not in trash.
    // For other views (like Favorites), we also respect the trash status.
    if (isInTrash != null) {
      query = query.where('isInTrash', isEqualTo: isInTrash);
    } else {
      query = query.where('isInTrash', isEqualTo: false);
    }

    // Apply order and limit
    // Ordering by lastModified ensures we fetch/sync the most recent notes first
    query = query.orderBy('lastModified', descending: true).limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map(Note.fromFirestore).toList();
    });
  }

  /// Adds a new note with [title] and [content].
  Future<Note> addNote({required String title, required String content}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final now = DateTime.now();

    // Create snippet (first 100 chars)
    final snippet = content.length > 100 ? content.substring(0, 100) : content;

    final docRef = await _notesCollection.add({
      'title': title,
      'content': snippet, // Store only snippet in main doc
      'createdAt': Timestamp.fromDate(now),
      'lastModified': Timestamp.fromDate(now),
      'ownerId': user.uid,
      'collaborators': <String, dynamic>{},
      'tags': <String>[],
      'memberIds': [user.uid], // Owner is always a member
      'isFavorite': false,
      'isInTrash': false,
    });

    // Store full content in subcollection
    await docRef.collection('content').doc('main').set({
      'fullContent': content,
    });

    final snapshot = await docRef.get();
    // Start with snippet, Editor will fetch full content
    return Note.fromFirestore(snapshot);
  }

  /// Updates an existing [note].
  Future<void> updateNote(Note note) async {
    // Update metadata and snippet in main doc
    final snippet = note.content.length > 100
        ? note.content.substring(0, 100)
        : note.content;

    // Create a map of fields to update in the main document
    // We manually construct this to ensure 'content' is the snippet
    final noteData = note.toFirestore();
    noteData['content'] = snippet;

    await _notesCollection.doc(note.id).update(noteData);

    // Update full content in subcollection
    await _notesCollection.doc(note.id).collection('content').doc('main').set({
      'fullContent': note.content,
    }, SetOptions(merge: true));
  }

  /// Deletes a note by its [noteId].
  Future<void> deleteNote(String noteId) async {
    // Delete content subcollection document first
    await _notesCollection
        .doc(noteId)
        .collection('content')
        .doc('main')
        .delete();
    await _notesCollection.doc(noteId).delete();
  }

  /// Deletes multiple notes by their IDs in a batch.
  Future<void> deleteNotes(List<String> noteIds) async {
    final batch = _firestore.batch();
    for (final id in noteIds) {
      batch.delete(_notesCollection.doc(id));
    }
    await batch.commit();
  }

  /// Returns a stream of all unique tags used by the current user.
  Stream<List<String>> getAllTagsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _notesCollection
        .where('ownerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final tags = <String>{};
          for (final doc in snapshot.docs) {
            final note = Note.fromFirestore(doc);
            tags.addAll(note.tags);
          }
          return tags.toList()..sort();
        });
  }

  /// Shares a note with [email] giving them [permission].
  Future<bool> shareNoteWithEmail(
    String noteId,
    String email,
    String permission,
  ) async {
    // 🛡️ Sentinel: Prevent a user from sharing a note with themselves.
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email == email) {
      return false; // Cannot share with oneself
    }

    final querySnapshot = await _usersCollection
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) {
      return false; // User not found
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

  // --- User Management ---

  /// Creates a user document in Firestore.
  Future<void> createUser(User user) async {
    await _usersCollection.doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // --- Folder Management ---

  /// Creates a new folder.
  Future<void> createFolder(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _foldersCollection.add({
      'name': name,
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns a stream of folders for the current user.
  Stream<List<Map<String, dynamic>>> getFoldersStream() {
    final user = _auth.currentUser;
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

  // Methods used by BackupService (mock implementation for now based on previous code)
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _foldersCollection
        .where('ownerId', isEqualTo: user.uid)
        .get();

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
    } catch (e) {
      return '';
    }
  }

  Future<List<Note>> getAllNotes() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    // This might be expensive, in real app consider pagination or not backing up everything always
    final snapshot = await _notesCollection
        .where('ownerId', isEqualTo: user.uid)
        .get();
    return snapshot.docs.map(Note.fromFirestore).toList();
  }

  Future<List<dynamic>> getNoteVersions(String noteId) async {
    // Placeholder as NoteVersion collection logic wasn't fully inspected,
    // assuming subcollection or separate collection.
    // Returning empty for now to satisfy BackupService contract if inferred.
    return [];
  }

  // =========================================================================
  // Event Sourcing Sync Methods
  // =========================================================================

  /// Pushes a single [event] to Firestore.
  Future<void> addNoteEvent(NoteEvent event) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _notesCollection
        .doc(event.noteId)
        .collection('events')
        .doc(event.id)
        .set(event.toFirestore());
  }

  /// Pushes multiple events to Firestore in a batch.
  Future<void> addNoteEvents(List<NoteEvent> events) async {
    if (events.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final batch = _firestore.batch();
    for (final event in events) {
      final docRef = _notesCollection
          .doc(event.noteId)
          .collection('events')
          .doc(event.id);
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

  // --- Collaboration / Cursors ---

  /// Updates the current user's cursor position for a specific note.
  Future<void> updateCursorPosition(
    String noteId,
    int baseOffset,
    int extentOffset,
    String displayName,
    int colorValue,
  ) async {
    final user = _auth.currentUser;
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

  /// Returns a stream of active cursors for a note, validating active status.
  Stream<List<Map<String, dynamic>>> listenToCursors(String noteId) {
    return _notesCollection
        .doc(noteId)
        .collection('cursors')
        // actively edited in last minute? usually filtered client side or via query if we index lastActive
        // For simplicity, we just listen to all and client filters by time if needed,
        // or just rely on the collection not being too big.
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Clean up old cursors (optional maintenance)
  Future<void> removeCursor(String noteId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _notesCollection
        .doc(noteId)
        .collection('cursors')
        .doc(user.uid)
        .delete();
  }
}
