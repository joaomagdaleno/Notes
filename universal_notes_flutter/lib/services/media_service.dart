import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A service for handling media operations like image compression.
class MediaService {
  MediaService._();

  /// The singleton instance of [MediaService].
  static final MediaService instance = MediaService._();

  /// Compresses an image file locally.
  /// Returns a new File pointing to the compressed image.
  Future<File> compressImage(File file) async {
    // 1. Read the image
    final bytes = await file.readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) return file; // Could not decode

    // 2. Resize if too large (max 1200px width/height)
    if (image.width > 1200 || image.height > 1200) {
      image = img.copyResize(
        image,
        width: image.width > image.height ? 1200 : null,
        height: image.height >= image.width ? 1200 : null,
      );
    }

    // 3. Compress as JPEG (quality 80)
    final compressedBytes = img.encodeJpg(image, quality: 80);

    // 4. Save to temp directory
    final tempDir = await getTemporaryDirectory();
    final fileName = '${p.basenameWithoutExtension(file.path)}_compressed.jpg';
    final compressedFile = File(p.join(tempDir.path, fileName));

    await compressedFile.writeAsBytes(compressedBytes);

    return compressedFile;
  }

  /// Generates a 64x64 thumbnail for an image.
  Future<Uint8List?> generateThumbnail(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final thumbnail = img.copyResize(image, width: 64, height: 64);
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 50));
    } on Exception {
      return null;
    }
  }
}
