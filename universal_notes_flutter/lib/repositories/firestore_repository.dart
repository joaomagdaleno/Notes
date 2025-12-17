import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_notes_flutter/models/note.dart';

/// Repository for interacting with Firestore.
class FirestoreRepository {
  /// Creates a [FirestoreRepository].
  FirestoreRepository() {
    _notesCollection = _firestore.collection('notes');
    _usersCollection = _firestore.collection('users');
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the collections
  late final CollectionReference<Map<String, dynamic>> _notesCollection;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;

  /// Returns a stream of notes filtered by [isFavorite], [isInTrash], and
  /// [tag].
  Stream<List<Note>> notesStream({
    bool? isFavorite,
    bool? isInTrash,
    String? tag,
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

    // For the "All Notes" view, we want notes that are not in trash.
    // For other views (like Favorites), we also respect the trash status.
    if (isInTrash != null) {
      query = query.where('isInTrash', isEqualTo: isInTrash);
    } else {
      query = query.where('isInTrash', isEqualTo: false);
    }

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
    final docRef = await _notesCollection.add({
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(now),
      'lastModified': Timestamp.fromDate(now),
      'ownerId': user.uid,
      'collaborators': <String, dynamic>{},
      'tags': <String>[],
      'memberIds': [user.uid], // Owner is always a member
      'isFavorite': false,
      'isInTrash': false,
    });
    final snapshot = await docRef.get();
    return Note.fromFirestore(snapshot);
  }

  /// Updates an existing [note].
  Future<void> updateNote(Note note) async {
    await _notesCollection.doc(note.id).update(note.toFirestore());
  }

  /// Deletes a note by its [noteId].
  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
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
}
