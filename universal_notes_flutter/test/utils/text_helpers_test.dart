import 'dart:convert';
import 'package:test/test.dart';
import 'package:universal_notes_flutter/utils/text_helpers.dart';

void main() {
  group('getPreviewText', () {
    test('should return empty string for empty content', () {
      expect(getPreviewText(''), '');
    });

    test('should return plain text from JSON text spans', () {
      final content = jsonEncode([
        {'text': 'Hello '},
        {'text': 'World!'},
      ]);
      expect(getPreviewText(content), 'Hello World!');
    });

    test('should return original content if it is not a list', () {
      const content = '{"key": "value"}';
      expect(getPreviewText(content), content);
    });

    test('should return original content if it is not valid JSON', () {
      const content = 'plain text that is not json';
      expect(getPreviewText(content), content);
    });

    test('should ignore non-text span maps in list', () {
      final content = jsonEncode([
        {'text': 'Valid '},
        {'other': 'invalid'},
        {'text': 'text'},
      ]);
      expect(getPreviewText(content), 'Valid text');
    });
  });
}
