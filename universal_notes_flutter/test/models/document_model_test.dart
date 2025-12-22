import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/stroke.dart';

void main() {
  group('TextSpanModel', () {
    test('toJson and fromJson should be symmetric', () {
      const span = TextSpanModel(
        text: 'Hello',
        isBold: true,
        isItalic: true,
        isUnderline: true,
        isStrikethrough: true,
        isCode: true,
        fontSize: 18,
        color: Colors.red,
        backgroundColor: Colors.yellow,
        fontFamily: 'Roboto',
        linkUrl: 'https://example.com',
      );

      final json = span.toJson();
      final fromJson = TextSpanModel.fromJson(json);

      expect(fromJson.text, span.text);
      expect(fromJson.isBold, span.isBold);
      expect(fromJson.isItalic, span.isItalic);
      expect(fromJson.isUnderline, span.isUnderline);
      expect(fromJson.isStrikethrough, span.isStrikethrough);
      expect(fromJson.isCode, span.isCode);
      expect(fromJson.fontSize, span.fontSize);
      expect(fromJson.color?.toARGB32(), span.color?.toARGB32());
      expect(
        fromJson.backgroundColor?.toARGB32(),
        span.backgroundColor?.toARGB32(),
      );
      expect(fromJson.fontFamily, span.fontFamily);
      expect(fromJson.linkUrl, span.linkUrl);
    });

    test('copyWith should work correctly', () {
      const span = TextSpanModel(text: 'Hello');
      final updated = span.copyWith(text: 'World', isBold: true);

      expect(updated.text, 'World');
      expect(updated.isBold, true);
      expect(updated.isItalic, false);
    });

    test('toTextSpan should handle styles and decorations', () {
      const span = TextSpanModel(
        text: 'Styled',
        isBold: true,
        isUnderline: true,
        isStrikethrough: true,
      );

      final textSpan = span.toTextSpan();
      expect(textSpan.text, 'Styled');
      expect(textSpan.style?.fontWeight, FontWeight.bold);
      // Combinations are harder to test directly but we check if it doesn't crash
      expect(textSpan.style?.decoration, isNotNull);
    });

    test('toTextSpan should handle links', () {
      const span = TextSpanModel(
        text: 'Link',
        linkUrl: 'https://google.com',
      );

      final textSpan = span.toTextSpan(onLinkTap: (_) {});
      expect(textSpan.style?.color, Colors.blue);
      expect(textSpan.recognizer, isNotNull);
    });
  });

  group('TextBlock', () {
    test('toPlainText should join spans', () {
      final block = TextBlock(
        spans: [
          const TextSpanModel(text: 'Hello '),
          const TextSpanModel(text: 'World'),
        ],
      );

      expect(block.toPlainText(), 'Hello World');
    });
  });

  group('DocumentModel', () {
    test('empty() should have no blocks', () {
      final doc = DocumentModel.empty();
      expect(doc.blocks, isEmpty);
    });

    test('fromPlainText should create a single TextBlock', () {
      final doc = DocumentModel.fromPlainText('Hello');
      expect(doc.blocks.length, 1);
      expect(doc.blocks.first, isA<TextBlock>());
      expect((doc.blocks.first as TextBlock).toPlainText(), 'Hello');
    });

    test('toJson and fromJson should handle multiple block types', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'Title')]),
          ImageBlock(imagePath: 'path/to/img.png'),
          CalloutBlock(
            type: CalloutType.warning,
            spans: [const TextSpanModel(text: 'Careful')],
          ),
          MathBlock(tex: 'E=mc^2'),
          TransclusionBlock(noteTitle: 'Other Note'),
        ],
      );

      final json = doc.toJson();
      final fromJson = DocumentModel.fromJson(json);

      expect(fromJson.blocks.length, 5);
      expect(fromJson.blocks[0], isA<TextBlock>());
      expect(fromJson.blocks[1], isA<ImageBlock>());
      expect(fromJson.blocks[2], isA<CalloutBlock>());
      expect(fromJson.blocks[3], isA<MathBlock>());
      expect(fromJson.blocks[4], isA<TransclusionBlock>());

      expect((fromJson.blocks[1] as ImageBlock).imagePath, 'path/to/img.png');
      expect((fromJson.blocks[2] as CalloutBlock).type, CalloutType.warning);
      expect((fromJson.blocks[3] as MathBlock).tex, 'E=mc^2');
      expect(
        (fromJson.blocks[4] as TransclusionBlock).noteTitle,
        'Other Note',
      );
    });

    test('toJson and fromJson should handle DrawingBlock', () {
      final doc = DocumentModel(
        blocks: [
          DrawingBlock(
            strokes: [
              const Stroke(
                points: [Point(0, 0)],
                color: Colors.black,
                width: 1,
              ),
            ],
            height: 300,
          ),
        ],
      );

      final json = doc.toJson();
      final fromJson = DocumentModel.fromJson(json);

      expect(fromJson.blocks.length, 1);
      expect(fromJson.blocks[0], isA<DrawingBlock>());
      expect((fromJson.blocks[0] as DrawingBlock).strokes.length, 1);
    });

    test('toJson and fromJson should handle TableBlock', () {
      final doc = DocumentModel(
        blocks: [
          TableBlock(
            rows: [
              [
                const TableCellModel(
                  content: [TextSpanModel(text: 'Header')],
                  isHeader: true,
                ),
              ],
              [
                const TableCellModel(content: [TextSpanModel(text: 'Data')]),
              ],
            ],
          ),
        ],
      );

      final json = doc.toJson();
      final fromJson = DocumentModel.fromJson(json);

      expect(fromJson.blocks.length, 1);
      expect(fromJson.blocks[0], isA<TableBlock>());
      final table = fromJson.blocks[0] as TableBlock;
      expect(table.rows.length, 2);
      expect(table.rows[0][0].isHeader, true);
      expect(table.rows[1][0].content[0].text, 'Data');
    });

    test(
      'fromJson should handle unknown types by falling back to TextBlock',
      () {
        final json = {
          'blocks': [
            {
              'type': 'unknown_type',
              'spans': [
                {'text': 'Fallback'},
              ],
            },
          ],
        };
        final doc = DocumentModel.fromJson(json);
        expect(doc.blocks.length, 1);
        expect(doc.blocks[0], isA<TextBlock>());
        expect((doc.blocks[0] as TextBlock).spans[0].text, 'Fallback');
      },
    );

    test('fromJson should handle null blocks', () {
      final json = {'blocks': null};
      final doc = DocumentModel.fromJson(json);
      expect(doc.blocks, isEmpty);
    });

    test('toPlainText should concatenate text blocks', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'A')]),
          TextBlock(spans: [const TextSpanModel(text: 'B')]),
        ],
      );

      expect(doc.toPlainText(), 'AB');
    });

    test('toTextSpan should include children from text blocks', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'A')]),
        ],
      );

      final textSpan = doc.toTextSpan();
      expect(textSpan.children?.length, 1);
      expect(textSpan.children?.first.toPlainText(), 'A');
    });

    test('fromJson should handle legacy list format', () {
      final fromJson = DocumentModel.fromJson([]);
      expect(fromJson.blocks, isEmpty);
    });
  });

  group('TableCellModel', () {
    test('toJson and fromJson symmetry', () {
      const cell = TableCellModel(
        content: [TextSpanModel(text: 'Cell')],
        isHeader: true,
      );

      final json = cell.toJson();
      final fromJson = TableCellModel.fromJson(json);

      expect(fromJson.isHeader, true);
      expect(fromJson.content.first.text, 'Cell');
    });
  });
}
