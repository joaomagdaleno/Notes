import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_notes_flutter/services/media_service.dart';
import 'package:uuid/uuid.dart';

/// Service for interacting with Firebase Storage.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image file to Firebase Storage and returns the download URL.
  /// Compresses the image locally first to save bandwidth and storage.
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Compress before upload
      final compressedFile = await MediaService.instance.compressImage(
        imageFile,
      );

      final fileName = const Uuid().v4();
      final ref = _storage.ref().child('note_images').child(fileName);
      final uploadTask = ref.putFile(compressedFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Cleanup temp compressed file if it's different from original
      if (compressedFile.path != imageFile.path) {
        await compressedFile.delete();
      }

      return downloadUrl;
    } on Exception catch (e) {
      debugPrint('Error uploading image to Firebase Storage: $e');
      return null;
    }
  }
}
