import 'package:test/test.dart';
import 'package:universal_notes_flutter/models/folder.dart';

void main() {
  group('Folder', () {
    test('should create a Folder instance', () {
      const folder = Folder(
        id: '1',
        name: 'Test Folder',
        isSmart: true,
        query: 'SELECT * FROM notes',
      );

      expect(folder.id, '1');
      expect(folder.name, 'Test Folder');
      expect(folder.isSmart, true);
      expect(folder.query, 'SELECT * FROM notes');
    });

    test('fromMap should create a Folder from a map', () {
      final map = {
        'id': '2',
        'name': 'Smart Folder',
        'isSmart': 1,
        'query': 'SELECT * FROM notes WHERE tags LIKE "%work%"',
      };

      final folder = Folder.fromMap(map);

      expect(folder.id, '2');
      expect(folder.name, 'Smart Folder');
      expect(folder.isSmart, true);
      expect(folder.query, 'SELECT * FROM notes WHERE tags LIKE "%work%"');
    });

    test('toMap should convert a Folder to a map', () {
      const folder = Folder(
        id: '3',
        name: 'Normal Folder',
      );

      final map = folder.toMap();

      expect(map['id'], '3');
      expect(map['name'], 'Normal Folder');
      expect(map['isSmart'], 0);
      expect(map['query'], isNull);
    });
  });
}
