@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';
import 'package:universal_notes_flutter/models/document_model.dart';

void main() {
  group('MarkdownConverter', () {
    test('should apply bold style on *text* ', () {
      final doc = DocumentModel.fromPlainText('*Bold* ');
      const selection = TextSelection.collapsed(offset: 7);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.toPlainText(), 'Bold ');
      final textBlock = result.document.blocks.first as TextBlock;
      expect(textBlock.spans.first.isBold, true);
    });

    test('should apply italic style on _text_ ', () {
      final doc = DocumentModel.fromPlainText('_Italic_ ');
      const selection = TextSelection.collapsed(offset: 9);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(
        result,
        isNotNull,
        reason: 'MarkdownConverter.checkAndApply returned null for italic',
      );
      expect(result!.document.toPlainText(), 'Italic ');
      final textBlock = result.document.blocks.first as TextBlock;
      expect(textBlock.spans.first.isItalic, true);
    });

    test('should apply heading block on # ', () {
      final doc = DocumentModel.fromPlainText('# ');
      const selection = TextSelection.collapsed(offset: 2);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.blocks.first.attributes['blockType'], 'heading');
      expect(result.document.blocks.first.attributes['level'], 1);
    });

    test('should apply checklist on - [ ] ', () {
      final doc = DocumentModel.fromPlainText('- [ ] ');
      const selection = TextSelection.collapsed(offset: 6);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(
        result!.document.blocks.first.attributes['blockType'],
        'checklist',
      );
      expect(result.document.blocks.first.attributes['checked'], false);
    });

    test('should handle links [text](url)', () {
      final doc = DocumentModel.fromPlainText('[Google](https://google.com)');
      const selection = TextSelection.collapsed(offset: 28);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.toPlainText(), 'Google');
      final textBlock = result.document.blocks.first as TextBlock;
      expect(textBlock.spans.first.linkUrl, 'https://google.com');
    });

    test('should convert table separator |---|', () {
      // Header row
      // Separator row
      final doc = DocumentModel.fromPlainText('| A | B |\n|---|---|');
      // Cursor at the end of separator line
      const selection = TextSelection.collapsed(offset: 19);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.blocks.first, isA<TableBlock>());
      final table = result.document.blocks.first as TableBlock;
      expect(table.rows.first.length, 2);
      expect(table.rows.first[0].content.first.text, 'A');
    });

    test(r'should handle math block $$tex$$', () {
      final doc = DocumentModel.fromPlainText(r'$$E=mc^2$$');
      const selection = TextSelection.collapsed(offset: 10);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.blocks.first, isA<MathBlock>());
      expect((result.document.blocks.first as MathBlock).tex, 'E=mc^2');
    });

    test('should handle transclusion ![[note]]', () {
      final doc = DocumentModel.fromPlainText('![[My Note]]');
      const selection = TextSelection.collapsed(offset: 12);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.blocks.first, isA<TransclusionBlock>());
      expect(
        (result.document.blocks.first as TransclusionBlock).noteTitle,
        'My Note',
      );
    });
  });
}
