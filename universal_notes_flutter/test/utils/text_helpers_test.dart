import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/utils/text_helpers.dart';

void main() {
  group('getPreviewText', () {
    test('extracts text from valid JSON', () {
      const json = r'[{"insert":"Hello World"},{"insert":"\n"}]';
      expect(getPreviewText(json), 'Hello World');
    });

    test('returns ellipsis for invalid JSON', () {
      const json = 'invalid-json';
      expect(getPreviewText(json), '...');
    });
  });
}
