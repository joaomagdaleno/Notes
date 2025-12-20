import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';

void main() {
  group('DocumentAdapter', () {
    test('fromJson should return empty document for empty string', () {
      final doc = DocumentAdapter.fromJson('');
      expect(doc.blocks.length, 1);
      expect(doc.toPlainText(), '');
    });

    test('fromJson should handle simple text json', () {
      const jsonStr = '[{"type": "text", "spans": [{"text": "Hello"}]}]';
      final doc = DocumentAdapter.fromJson(jsonStr);
      expect(doc.toPlainText(), 'Hello');
    });

    test('fromJson should handle image blocks', () {
      const jsonStr = '[{"type": "image", "imagePath": "path/to/img.png"}]';
      final doc = DocumentAdapter.fromJson(jsonStr);
      expect(doc.blocks.first, isA<ImageBlock>());
      expect((doc.blocks.first as ImageBlock).imagePath, 'path/to/img.png');
    });

    test('fromJson should fallback to plain text for invalid JSON', () {
      const plainText = 'Just a regular string';
      final doc = DocumentAdapter.fromJson(plainText);
      expect(doc.toPlainText(), plainText);
    });

    test('toJson should convert document to JSON string', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'Hello', isBold: true)]),
          ImageBlock(imagePath: 'img.pnj'),
        ],
      );
      final jsonStr = DocumentAdapter.toJson(doc);
      expect(jsonStr, contains('"type":"text"'));
      expect(jsonStr, contains('"text":"Hello"'));
      expect(jsonStr, contains('"isBold":true'));
      expect(jsonStr, contains('"type":"image"'));
      expect(jsonStr, contains('"imagePath":"img.pnj"'));
    });

    test('roundtrip fromJson(toJson(doc)) should preserve content', () {
      final original = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'Line 1')]),
          TextBlock(spans: [const TextSpanModel(text: 'Line 2')]),
        ],
      );

      final jsonStr = DocumentAdapter.toJson(original);
      final restored = DocumentAdapter.fromJson(jsonStr);

      expect(restored.toPlainText(), original.toPlainText());
      expect(restored.blocks.length, original.blocks.length);
    });
  });
}
