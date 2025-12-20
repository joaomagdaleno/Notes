import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/tag.dart';

void main() {
  group('Tag', () {
    const tag = Tag(
      id: 't1',
      name: 'Work',
      color: Colors.blue,
    );

    test('should create a Tag instance', () {
      expect(tag.id, 't1');
      expect(tag.name, 'Work');
      expect(tag.color, Colors.blue);
    });

    test('fromMap should create a Tag from a map', () {
      final map = {
        'id': 't2',
        'name': 'Personal',
        'color': Colors.red.toARGB32(),
      };

      final fromMap = Tag.fromMap(map);

      expect(fromMap.id, 't2');
      expect(fromMap.name, 'Personal');
      expect(fromMap.color?.toARGB32(), Colors.red.toARGB32());
    });

    test('fromMap should handle null color', () {
      final map = {
        'id': 't3',
        'name': 'Misc',
        'color': null,
      };

      final fromMap = Tag.fromMap(map);

      expect(fromMap.id, 't3');
      expect(fromMap.name, 'Misc');
      expect(fromMap.color, isNull);
    });

    test('toMap should convert a Tag to a map', () {
      final map = tag.toMap();

      expect(map['id'], 't1');
      expect(map['name'], 'Work');
      expect(map['color'], Colors.blue.toARGB32());
    });
  });
}
