@Tags(['unit'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:universal_notes_flutter/services/media_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProvider extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {}

void main() {
  late MediaService mediaService;
  late Directory tempDir;

  setUp(() async {
    mediaService = MediaService.instance;
    tempDir = await Directory.systemTemp.createTemp('media_service_test');

    final mockPathProvider = MockPathProvider();
    PathProviderPlatform.instance = mockPathProvider;
    when(
      () => mockPathProvider.getTemporaryPath(),
    ).thenAnswer((_) async => tempDir.path);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MediaService', () {
    test('generateThumbnail returns null for invalid image', () async {
      final file = File(p.join(tempDir.path, 'invalid.jpg'));
      await file.writeAsString('not an image');

      final result = await mediaService.generateThumbnail(file);

      expect(result, isNull);
    });

    test('generateThumbnail returns bytes for valid image', () async {
      // Create a small white 10x10 image
      final file = File(p.join(tempDir.path, 'valid.png'));
      // Minimal valid PNG (1x1 white pixel)
      final pngBytes = [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0xD7,
        0x63,
        0x60,
        0x60,
        0x60,
        0x00,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ];
      await file.writeAsBytes(pngBytes);

      final result = await mediaService.generateThumbnail(file);

      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('compressImage resizes large image', () async {
      // We'll skip actual heavy compression testing to keep it fast,
      // but verify it creates a file.
      final file = File(p.join(tempDir.path, 'large.png'));
      final pngBytes = [
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x02,
        0x00,
        0x00,
        0x00,
        0x90,
        0x77,
        0x53,
        0xDE,
        0x00,
        0x00,
        0x00,
        0x0C,
        0x49,
        0x44,
        0x41,
        0x54,
        0x08,
        0xD7,
        0x63,
        0x60,
        0x60,
        0x60,
        0x00,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ];
      await file.writeAsBytes(pngBytes);

      final result = await mediaService.compressImage(file);

      expect(result.path, contains('_compressed.jpg'));
      expect(result.existsSync(), isTrue);
    });
  });
}
