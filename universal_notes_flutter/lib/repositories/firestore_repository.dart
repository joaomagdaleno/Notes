import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_notes_flutter/models/note.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the 'notes' collection
  late final CollectionReference<Map<String, dynamic>> _notesCollection;

  FirestoreRepository() {
    _notesCollection = _firestore.collection('notes');
  }

  Stream<List<Note>> notesStream({
    bool? isFavorite,
    bool? isInTrash,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query =
        _notesCollection.where('ownerId', isEqualTo: user.uid);

    if (isFavorite != null) {
      query = query.where('isFavorite', isEqualTo: isFavorite);
    }
    // For the "All Notes" view, we want notes that are not in trash.
    // For other views (like Favorites), we also respect the trash status.
    if (isInTrash != null) {
      query = query.where('isInTrash', isEqualTo: isInTrash);
    } else {
      query = query.where('isInTrash', isEqualTo: false);
    }


    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
    });
  }

  Future<void> addNote({required String title, required String content}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    final now = DateTime.now();
    await _notesCollection.add({
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(now),
      'lastModified': Timestamp.fromDate(now),
      'ownerId': user.uid,
      'collaborators': {},
      'tags': [],
      'isFavorite': false,
      'isInTrash': false,
    });
  }

  Future<void> updateNote(Note note) async {
    await _notesCollection.doc(note.id).update(note.toFirestore());
  }

  Future<void> deleteNote(String noteId) async {
    await _notesCollection.doc(noteId).delete();
  }
}
