import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Service for interacting with Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file to Firebase Storage and returns the download URL.
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = const Uuid().v4();
      final ref = _storage.ref().child('note_images').child(fileName);
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on Exception catch (_) {
      // TODO(developer): Log error to a logging service
      return null;
    }
  }
}
