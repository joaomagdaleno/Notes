import 'package:test/test.dart';
import 'package:universal_notes_flutter/models/snippet.dart';

void main() {
  group('Snippet', () {
    test('should create a Snippet instance', () {
      const snippet = Snippet(
        id: 's1',
        trigger: '/date',
        content: '2023-10-27',
      );

      expect(snippet.id, 's1');
      expect(snippet.trigger, '/date');
      expect(snippet.content, '2023-10-27');
    });

    test('fromMap should create a Snippet from a map', () {
      final map = {
        'id': 's2',
        'trigger': ';email',
        'content': 'test@example.com',
      };

      final snippet = Snippet.fromMap(map);

      expect(snippet.id, 's2');
      expect(snippet.trigger, ';email');
      expect(snippet.content, 'test@example.com');
    });

    test('toMap should convert a Snippet to a map', () {
      const snippet = Snippet(
        id: 's3',
        trigger: ';sig',
        content: 'Best regards,\nJohn Doe',
      );

      final map = snippet.toMap();

      expect(map['id'], 's3');
      expect(map['trigger'], ';sig');
      expect(map['content'], 'Best regards,\nJohn Doe');
    });
  });
}
