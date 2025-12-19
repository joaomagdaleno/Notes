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

    test('converts ~strikethrough~ pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello ~World~ '),
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
      final block = result!.document.blocks.first as TextBlock;
      expect(block.attributes['blockType'], 'heading');
      expect(block.attributes['level'], 1);
      // We expect the # to be removed
      final spans = block.spans;
      expect(spans[0].text, 'My Title');
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
      final block = result!.document.blocks.first as TextBlock;
      expect(block.attributes['blockType'], 'unordered-list');
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

    test('converts 1. ordered list pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: '1. '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 3);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      final block = result!.document.blocks.first as TextBlock;
      expect(block.attributes['blockType'], 'ordered-list');
    });

    test('converts - [ ] unchecked checkbox pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: '- [ ] '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 6);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      final block = result!.document.blocks.first as TextBlock;
      expect(block.attributes['blockType'], 'checklist');
      expect(block.attributes['checked'], false);
    });

    test('converts - [x] checked checkbox pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: '- [x] '),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 6);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      final block = result!.document.blocks.first as TextBlock;
      expect(block.attributes['blockType'], 'checklist');
      expect(block.attributes['checked'], true);
    });

    test('converts [link](url) pattern', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Click [here](https://example.com)'),
            ],
          ),
        ],
      );
      const selection = TextSelection.collapsed(offset: 33); // End of string

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      final spans = (result!.document.blocks.first as TextBlock).spans;
      expect(spans.length, 2);
      expect(spans[0].text, 'Click ');
      expect(spans[1].text, 'here');
      expect(spans[1].linkUrl, 'https://example.com');
      expect(spans[1].isUnderline, true);
    });
  });
}
