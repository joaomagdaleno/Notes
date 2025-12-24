@Tags(['widget'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/virtual_text_buffer.dart';
import 'package:universal_notes_flutter/models/document_model.dart';

void main() {
  group('VirtualTextBuffer', () {
    test('should split text blocks by newlines', () {
      final doc = DocumentModel.fromPlainText('Line 1\nLine 2');
      final buffer = VirtualTextBuffer(doc);

      expect(buffer.lines.length, 2);
      expect(buffer.lines[0], isA<TextLine>());
      expect((buffer.lines[0] as TextLine).toPlainText(), 'Line 1');
      expect((buffer.lines[1] as TextLine).toPlainText(), 'Line 2');
    });

    test('should handle callout blocks with multiple lines', () {
      final doc = DocumentModel(
        blocks: [
          CalloutBlock(
            type: CalloutType.note,
            spans: [const TextSpanModel(text: 'C1\nC2')],
          ),
        ],
      );
      final buffer = VirtualTextBuffer(doc);

      expect(buffer.lines.length, 2);
      expect(buffer.lines[0], isA<CalloutLine>());
      expect((buffer.lines[0] as CalloutLine).isFirst, true);
      expect((buffer.lines[0] as CalloutLine).isLast, false);
      expect((buffer.lines[1] as CalloutLine).isFirst, false);
      expect((buffer.lines[1] as CalloutLine).isLast, true);
    });

    test('getLineTextPositionForOffset should return correct position', () {
      final doc = DocumentModel.fromPlainText('ABC\nDEF');
      final buffer = VirtualTextBuffer(doc);

      // 'ABC\nDEF' -> length is 7 total (if \n is included in length calculation)
      // Line 1: 'ABC' (len 3) + \n (len 1) = 4
      // Line 2: 'DEF' (len 3)

      var pos = buffer.getLineTextPositionForOffset(0);
      expect(pos.line, 0);
      expect(pos.character, 0);

      pos = buffer.getLineTextPositionForOffset(3);
      expect(pos.line, 0);
      expect(pos.character, 3);

      pos = buffer.getLineTextPositionForOffset(4);
      expect(pos.line, 1);
      expect(pos.character, 0);

      pos = buffer.getLineTextPositionForOffset(6);
      expect(pos.line, 1);
      expect(pos.character, 2);
    });

    test('getOffsetForLineTextPosition should return correct offset', () {
      final doc = DocumentModel.fromPlainText('ABC\nDEF');
      final buffer = VirtualTextBuffer(doc);

      var offset = buffer.getOffsetForLineTextPosition(
        const LineTextPosition(line: 0, character: 0),
      );
      expect(offset, 0);

      offset = buffer.getOffsetForLineTextPosition(
        const LineTextPosition(line: 0, character: 3),
      );
      expect(offset, 3);

      offset = buffer.getOffsetForLineTextPosition(
        const LineTextPosition(line: 1, character: 0),
      );
      expect(offset, 4);

      offset = buffer.getOffsetForLineTextPosition(
        const LineTextPosition(line: 1, character: 3),
      );
      expect(offset, 7);
    });

    test('should handle non-text blocks as length 1', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(spans: [const TextSpanModel(text: 'A')]),
          ImageBlock(imagePath: 'path/to/img'),
          TextBlock(spans: [const TextSpanModel(text: 'B')]),
        ],
      );
      final buffer = VirtualTextBuffer(doc);

      // Line 1: 'A' (length 1 + 1 for newline?) wait...
      // If Blocks are distinct, DocumentModel usually implies newlines between them?
      // Check DocumentModel.toPlainText() or VirtualTextBuffer logic.
      // _lineLengths[i] adds 1 if not last line.

      expect(buffer.lines.length, 3);
      // Line 0 (Text): length 1 + 1 = 2
      // Line 1 (Image): length 1 + 1 = 2
      // Line 2 (Text): length 1 = 1

      var pos = buffer.getLineTextPositionForOffset(2); // Start of ImageLine
      expect(pos.line, 1);
      expect(pos.character, 0);

      pos = buffer.getLineTextPositionForOffset(4); // Start of last TextLine
      expect(pos.line, 2);
      expect(pos.character, 0);
    });
  });
}
