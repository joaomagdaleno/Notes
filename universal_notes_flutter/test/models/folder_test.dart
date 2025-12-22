import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/folder.dart';

void main() {
  group('Folder', () {
    const folder = Folder(
      id: '1',
      name: 'Test Folder',
      isSmart: true,
      query: 'SELECT * FROM notes',
    );

    test('should create a Folder instance', () {
      expect(folder.id, '1');
      expect(folder.name, 'Test Folder');
      expect(folder.isSmart, isTrue);
      expect(folder.query, 'SELECT * FROM notes');
    });

    test('fromMap should create a Folder from a map', () {
      final map = {
        'id': '2',
        'name': 'Map Folder',
        'isSmart': 0,
        'query': null,
      };

      final fromMap = Folder.fromMap(map);

      expect(fromMap.id, '2');
      expect(fromMap.name, 'Map Folder');
      expect(fromMap.isSmart, isFalse);
      expect(fromMap.query, isNull);
    });

    test('toMap should convert a Folder to a map', () {
      final map = folder.toMap();

      expect(map['id'], '1');
      expect(map['name'], 'Test Folder');
      expect(map['isSmart'], 1);
      expect(map['query'], 'SELECT * FROM notes');
    });

    test('fromMap should handle 1 for isSmart', () {
      final map = {'id': '3', 'name': 'Smart', 'isSmart': 1};
      final fromMap = Folder.fromMap(map);
      expect(fromMap.isSmart, isTrue);
    });
  });
}
