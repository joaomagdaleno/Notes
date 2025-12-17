import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';

void main() {
  group('MarkdownConverter', () {
    test('converts *bold* pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello *World* '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 13);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.blocks.length, greaterThan(0));
      final spans = (result.document.blocks.first as TextBlock).spans;
      expect(spans.length, 3);
      expect(spans[0].text, 'Hello ');
      expect(spans[0].isBold, isFalse);
      expect(spans[1].text, 'World');
      expect(spans[1].isBold, isTrue);
      expect(spans[2].text, ' ');
      expect(spans[2].isBold, isFalse);
      expect(result.selection.baseOffset, 11);
    });

    test('converts _italic_ pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello _World_ '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 13);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(
        (result!.document.blocks.first as TextBlock).spans[1].isItalic,
        isTrue,
      );
    });

    test('converts -strikethrough- pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello -World- '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 13);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(
        (result!.document.blocks.first as TextBlock).spans[1].isStrikethrough,
        isTrue,
      );
    });

    test('converts # heading pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: '# My Title'),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 2); // After "# "

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      final spans = (result!.document.blocks.first as TextBlock).spans;
      expect(spans.length, 1);
      expect(spans[0].text, 'My Title');
      expect(spans[0].fontSize, 32.0);
    });

    test('converts - list pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: '- '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 2);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.toPlainText(), '• ');
    });

    test('does not convert incomplete patterns', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello *World'),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 12);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNull);
    });
  });
}
