import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';

void main() {
  group('DocumentManipulator.toggleStyle', () {
    test('applies bold to a selection in a single span', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello World'),
        ],
      );
      const selection = TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      ); // "World"

      final newDoc = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.bold,
      );

      expect(newDoc.spans.length, 2);
      expect(newDoc.spans[0].text, 'Hello ');
      expect(newDoc.spans[0].isBold, isFalse);
      expect(newDoc.spans[1].text, 'World');
      expect(newDoc.spans[1].isBold, isTrue);
    });

    test('removes bold from a selection', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello '),
          TextSpanModel(text: 'World', isBold: true),
        ],
      );
      const selection = TextSelection(baseOffset: 6, extentOffset: 11);

      final newDoc = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.bold,
      );

      expect(newDoc.spans.length, 1);
      expect(newDoc.spans[0].text, 'Hello World');
      expect(newDoc.spans[0].isBold, isFalse);
    });

    test('applies italic across multiple spans', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'One '),
          TextSpanModel(text: 'Two '),
          TextSpanModel(text: 'Three'),
        ],
      );
      const selection = TextSelection(
        baseOffset: 2,
        extentOffset: 10,
      ); // "e Two Thre"

      final newDoc = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.italic,
      );

      expect(newDoc.spans.length, 5);
      expect(newDoc.spans[0].text, 'On');
      expect(newDoc.spans[0].isItalic, isFalse);
      expect(newDoc.spans[1].text, 'e ');
      expect(newDoc.spans[1].isItalic, isTrue);
      expect(newDoc.spans[2].text, 'Two ');
      expect(newDoc.spans[2].isItalic, isTrue);
      expect(newDoc.spans[3].text, 'Thre');
      expect(newDoc.spans[3].isItalic, isTrue);
      expect(newDoc.spans[4].text, 'e');
      expect(newDoc.spans[4].isItalic, isFalse);
    });
  });

  group('DocumentManipulator.insertText', () {
    test('inserts text into a styled span', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello ', isBold: true),
          TextSpanModel(text: 'World', isItalic: true),
        ],
      );

      final newDoc = DocumentManipulator.insertText(doc, 8, 'Cruel ');

      expect(newDoc.spans.length, 2);
      expect(newDoc.spans[1].text, 'WoCruel rld');
      expect(newDoc.spans[1].isItalic, isTrue);
      expect(newDoc.toPlainText(), 'Hello WoCruel rld');
    });
  });

  group('DocumentManipulator.deleteText', () {
    test('deletes text within a single span', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello World', isBold: true),
        ],
      );

      final newDoc = DocumentManipulator.deleteText(doc, 5, 6); // " World"

      expect(newDoc.spans.length, 1);
      expect(newDoc.spans[0].text, 'Hello');
      expect(newDoc.spans[0].isBold, isTrue);
    });

    test('deletes text across multiple spans', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'One ', isBold: true),
          TextSpanModel(text: 'Two ', isItalic: true),
          TextSpanModel(text: 'Three', isUnderline: true),
        ],
      );

      final newDoc = DocumentManipulator.deleteText(doc, 2, 8); // "e Two Th"

      expect(newDoc.spans.length, 2);
      expect(newDoc.spans[0].text, 'On');
      expect(newDoc.spans[0].isBold, isTrue);
      expect(newDoc.spans[1].text, 'ree');
      expect(newDoc.spans[1].isUnderline, isTrue);
    });
  });

  group('DocumentManipulator.applyColor', () {
    test('applies color to a selection', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello World'),
        ],
      );
      const selection = TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      ); // "Hello"

      final newDoc = DocumentManipulator.applyColor(doc, selection, Colors.red);

      expect(newDoc.spans.length, 2);
      expect(newDoc.spans[0].text, 'Hello');
      expect(newDoc.spans[0].color, Colors.red);
      expect(newDoc.spans[1].text, ' World');
      expect(newDoc.spans[1].color, isNull);
    });
  });

  group('DocumentManipulator.applyFontSize', () {
    test('applies font size to a selection', () {
      const doc = DocumentModel(
        spans: [
          TextSpanModel(text: 'Hello World'),
        ],
      );
      const selection = TextSelection(
        baseOffset: 6,
        extentOffset: 11,
      ); // "World"

      final newDoc = DocumentManipulator.applyFontSize(doc, selection, 24);

      expect(newDoc.spans.length, 2);
      expect(newDoc.spans[0].text, 'Hello ');
      expect(newDoc.spans[0].fontSize, isNull);
      expect(newDoc.spans[1].text, 'World');
      expect(newDoc.spans[1].fontSize, 24.0);
    });
  });
}
