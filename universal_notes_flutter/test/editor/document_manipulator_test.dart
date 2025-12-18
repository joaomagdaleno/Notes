import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/models/note_event.dart';

void main() {
  group('DocumentManipulator.toggleStyle', () {
    test('applies bold to a selection in a single span', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello World'),
            ],
          ),
        ],
      );
      const selection = TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      ); // "World"

      final result = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.bold,
      );
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.format);
      expect(result.eventPayload['attr'], 'bold');

      expect((newDoc.blocks.first as TextBlock).spans.length, 2);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'Hello ');
      expect((newDoc.blocks.first as TextBlock).spans[0].isBold, isFalse);
      expect((newDoc.blocks.first as TextBlock).spans[1].text, 'World');
      expect((newDoc.blocks.first as TextBlock).spans[1].isBold, isTrue);
    });

    test('removes bold from a selection', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello '),
              const TextSpanModel(text: 'World', isBold: true),
            ],
          ),
        ],
      );
      const selection = TextSelection(baseOffset: 6, extentOffset: 11);

      final result = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.bold,
      );
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.format);

      expect((newDoc.blocks.first as TextBlock).spans.length, 1);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'Hello World');
      expect((newDoc.blocks.first as TextBlock).spans[0].isBold, isFalse);
    });

    test('applies italic across multiple spans', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'One '),
              const TextSpanModel(text: 'Two '),
              const TextSpanModel(text: 'Three'),
            ],
          ),
        ],
      );
      const selection = TextSelection(
        baseOffset: 2,
        extentOffset: 10,
      ); // "e Two Thre"

      final result = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.italic,
      );
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.format);

      expect((newDoc.blocks.first as TextBlock).spans.length, 5);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'On');
      expect((newDoc.blocks.first as TextBlock).spans[0].isItalic, isFalse);
      expect((newDoc.blocks.first as TextBlock).spans[1].text, 'e ');
      expect((newDoc.blocks.first as TextBlock).spans[1].isItalic, isTrue);
      expect((newDoc.blocks.first as TextBlock).spans[2].text, 'Two ');
      expect((newDoc.blocks.first as TextBlock).spans[2].isItalic, isTrue);
      expect((newDoc.blocks.first as TextBlock).spans[3].text, 'Thre');
      expect((newDoc.blocks.first as TextBlock).spans[3].isItalic, isTrue);
      expect((newDoc.blocks.first as TextBlock).spans[4].text, 'e');
      expect((newDoc.blocks.first as TextBlock).spans[4].isItalic, isFalse);
    });
  });

  group('DocumentManipulator.insertText', () {
    test('inserts text into a styled span', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello ', isBold: true),
              const TextSpanModel(text: 'World', isItalic: true),
            ],
          ),
        ],
      );

      final result = DocumentManipulator.insertText(doc, 8, 'Cruel ');
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.insert);
      expect(result.eventPayload['text'], 'Cruel ');

      expect((newDoc.blocks.first as TextBlock).spans.length, 2);
      expect((newDoc.blocks.first as TextBlock).spans[1].text, 'WoCruel rld');
      expect((newDoc.blocks.first as TextBlock).spans[1].isItalic, isTrue);
      expect(newDoc.toPlainText(), 'Hello WoCruel rld');
    });
  });

  group('DocumentManipulator.deleteText', () {
    test('deletes text within a single span', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello World', isBold: true),
            ],
          ),
        ],
      );

      final result = DocumentManipulator.deleteText(doc, 5, 6); // " World"
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.delete);

      expect((newDoc.blocks.first as TextBlock).spans.length, 1);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'Hello');
      expect((newDoc.blocks.first as TextBlock).spans[0].isBold, isTrue);
    });

    test('deletes text across multiple spans', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'One ', isBold: true),
              const TextSpanModel(text: 'Two ', isItalic: true),
              const TextSpanModel(text: 'Three', isUnderline: true),
            ],
          ),
        ],
      );

      final result = DocumentManipulator.deleteText(doc, 2, 8); // "e Two Th"
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.delete);

      expect((newDoc.blocks.first as TextBlock).spans.length, 2);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'On');
      expect((newDoc.blocks.first as TextBlock).spans[0].isBold, isTrue);
      expect((newDoc.blocks.first as TextBlock).spans[1].text, 'ree');
      expect((newDoc.blocks.first as TextBlock).spans[1].isUnderline, isTrue);
    });
  });

  group('DocumentManipulator.applyColor', () {
    test('applies color to a selection', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello World'),
            ],
          ),
        ],
      );
      const selection = TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      ); // "Hello"

      final result = DocumentManipulator.applyColor(doc, selection, Colors.red);
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.format);
      // ignore: deprecated_member_use
      expect(result.eventPayload['color'], Colors.red.value);

      expect((newDoc.blocks.first as TextBlock).spans.length, 2);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'Hello');
      expect((newDoc.blocks.first as TextBlock).spans[0].color, Colors.red);
      expect((newDoc.blocks.first as TextBlock).spans[1].text, ' World');
      expect((newDoc.blocks.first as TextBlock).spans[1].color, isNull);
    });
  });

  group('DocumentManipulator.applyFontSize', () {
    test('applies font size to a selection', () {
      final doc = DocumentModel(
        blocks: [
          TextBlock(
            spans: [
              const TextSpanModel(text: 'Hello World'),
            ],
          ),
        ],
      );
      const selection = TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      ); // "World"

      final result = DocumentManipulator.applyFontSize(doc, selection, 24);
      final newDoc = result.document;

      expect(result.eventType, NoteEventType.format);
      expect(result.eventPayload['fontSize'], 24.0);

      expect((newDoc.blocks.first as TextBlock).spans.length, 2);
      expect((newDoc.blocks.first as TextBlock).spans[0].text, 'Hello ');
      expect((newDoc.blocks.first as TextBlock).spans[0].fontSize, isNull);
      expect((newDoc.blocks.first as TextBlock).spans[1].text, 'World');
      expect((newDoc.blocks.first as TextBlock).spans[1].fontSize, 24.0);
    });
  });
}
