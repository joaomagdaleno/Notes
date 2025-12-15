import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/markdown_converter.dart';

void main() {
  group('MarkdownConverter', () {
    test('converts *bold* pattern', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello *World* '),
        ],
      );
      const selection = TextSelection.collapsed(offset: 13);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.spans.length, 3);
      expect(result.document.spans[0].text, 'Hello ');
      expect(result.document.spans[0].isBold, isFalse);
      expect(result.document.spans[1].text, 'World');
      expect(result.document.spans[1].isBold, isTrue);
      expect(result.document.spans[2].text, ' ');
      expect(result.document.spans[2].isBold, isFalse);
      expect(result.selection.baseOffset, 12);
    });

    test('converts _italic_ pattern', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello _World_ '),
        ],
      );
      const selection = TextSelection.collapsed(offset: 13);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.spans[1].isItalic, isTrue);
    });

    test('converts -strikethrough- pattern', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello -World- '),
        ],
      );
      const selection = TextSelection.collapsed(offset: 13);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.spans[1].isStrikethrough, isTrue);
    });

    test('converts # heading pattern', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: '# My Title'),
        ],
      );
      const selection = TextSelection.collapsed(offset: 2); // After "# "

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.spans.length, 1);
      expect(result.document.spans[0].text, 'My Title');
      expect(result.document.spans[0].fontSize, 32.0);
    });

    test('converts - list pattern', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: '- '),
        ],
      );
      const selection = TextSelection.collapsed(offset: 2);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNotNull);
      expect(result!.document.toPlainText(), '• ');
    });

    test('does not convert incomplete patterns', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello *World'),
        ],
      );
      const selection = TextSelection.collapsed(offset: 12);

      final result = MarkdownConverter.checkAndApply(doc, selection);

      expect(result, isNull);
    });
  });
}
