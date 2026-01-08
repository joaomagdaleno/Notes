@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/models/snippet.dart';

void main() {
  group('Snippet', () {
    const snippet = Snippet(
      id: 's1',
      trigger: ';email',
      content: 'test@example.com',
    );

    test('should create a Snippet instance', () {
      expect(snippet.id, 's1');
      expect(snippet.trigger, ';email');
      expect(snippet.content, 'test@example.com');
    });

    test('fromMap should create a Snippet from a map', () {
      final map = {
        'id': 's2',
        'trigger': ';addr',
        'content': '123 Main St',
      };

      final fromMap = Snippet.fromMap(map);

      expect(fromMap.id, 's2');
      expect(fromMap.trigger, ';addr');
      expect(fromMap.content, '123 Main St');
    });

    test('toMap should convert a Snippet to a map', () {
      final map = snippet.toMap();

      expect(map['id'], 's1');
      expect(map['trigger'], ';email');
      expect(map['content'], 'test@example.com');
    });
  });
}
