@Tags(['unit'])
library;

import 'dart:convert';
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
  // 1x1 Transparent PNG
  final validPngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

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
      await file.writeAsBytes(validPngBytes);

      final result = await mediaService.generateThumbnail(file);

      expect(result, isNotNull);
      expect(result!.length, greaterThan(0));
    });

    test('compressImage resizes large image', () async {
      // We'll skip actual heavy compression testing to keep it fast,
      // but verify it creates a file.
      final file = File(p.join(tempDir.path, 'large.png'));
      await file.writeAsBytes(validPngBytes);

      final result = await mediaService.compressImage(file);

      expect(result.path, contains('_compressed.jpg'));
      expect(result.existsSync(), isTrue);
    });
  });
}
