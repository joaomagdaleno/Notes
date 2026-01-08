/// Fast unit tests for FirebaseService
/// Tagged as @unit for quick execution (<5s timeout)
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/models/document_model.dart';
import 'package:notes_hub/services/firebase_service.dart';

void main() {
  group('FirebaseService', () {
    late FirebaseService service;

    setUp(() {
      service = FirebaseService();
    });

    tearDown(() {
      service.dispose();
    });

    test('getDocument returns initial empty document', () async {
      final doc = await service.getDocument('note-1');

      expect(doc, isA<Map<String, dynamic>>());
      expect(doc.containsKey('content'), isTrue);
    });

    test('updateDocument emits updated content on stream', () async {
      final testDoc = DocumentModel.empty();

      // Listen for updates
      final future = service.documentStream.first;

      // Update document
      await service.updateDocument('note-1', testDoc);

      // Verify stream received update
      final result = await future;
      expect(result['content'], equals(testDoc.toJson()));
    });

    test('updateUserPresence adds user to presence map', () async {
      const userId = 'user-123';
      final cursorData = {
        'x': 100,
        'y': 200,
        'name': 'Test User',
        'color': '#FF0000',
      };

      // Listen for presence updates
      final future = service.presenceStream.first;

      // Update presence
      await service.updateUserPresence('note-1', userId, cursorData);

      // Verify stream received update
      final result = await future;
      expect(result.containsKey(userId), isTrue);
      expect(result[userId], equals(cursorData));
    });

    test('removeUserPresence removes user from presence map', () async {
      const userId = 'user-123';
      final cursorData = {'x': 100};

      // First add a user
      await service.updateUserPresence('note-1', userId, cursorData);

      // Listen for removal
      final future = service.presenceStream.first;

      // Remove user
      await service.removeUserPresence('note-1', userId);

      // Verify user removed
      final result = await future;
      expect(result.containsKey(userId), isFalse);
    });

    test('documentStream is broadcast stream', () {
      // Multiple listeners should work
      service.documentStream.listen((_) {});
      service.documentStream.listen((_) {});

      // No error should be thrown
      expect(true, isTrue);
    });

    test('presenceStream is broadcast stream', () {
      // Multiple listeners should work
      service.presenceStream.listen((_) {});
      service.presenceStream.listen((_) {});

      // No error should be thrown
      expect(true, isTrue);
    });
  });
}
