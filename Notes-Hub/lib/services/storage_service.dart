import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:notes_hub/services/media_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service for storing images locally (local-first approach).
class StorageService {
  StorageService._();

  /// The singleton instance of [StorageService].
  static StorageService instance = StorageService._();

  /// Saves an image file locally and returns the local path.
  /// Uses local storage on all platforms for a local-first experience.
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Compress before saving
      final compressedFile = await MediaService.instance.compressImage(
        imageFile,
      );

      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/notes_hub_images');
      if (!imagesDir.existsSync()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${const Uuid().v4()}.jpg';
      final localPath = '${imagesDir.path}/$fileName';
      await compressedFile.copy(localPath);

      // Cleanup temp compressed file if it's different from original
      if (compressedFile.path != imageFile.path) {
        await compressedFile.delete();
      }

      return localPath;
    } on Exception catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }
}
