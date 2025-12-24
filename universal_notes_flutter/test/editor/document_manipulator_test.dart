@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/models/document_model.dart';

void main() {
  group('DocumentManipulator', () {
    test('insertText should add text to an empty document', () {
      final doc = DocumentModel.fromPlainText('');
      final result = DocumentManipulator.insertText(doc, 0, 'Hello');

      expect(result.document.toPlainText(), 'Hello');
      expect(result.eventPayload, isNotEmpty);
    });

    test('insertText should add text in the middle of existing text', () {
      final doc = DocumentModel.fromPlainText('Hlo');
      final result = DocumentManipulator.insertText(doc, 1, 'el');

      expect(result.document.toPlainText(), 'Hello');
    });

    test('deleteText should remove text correctly', () {
      final doc = DocumentModel.fromPlainText('Hello World');
      final result = DocumentManipulator.deleteText(doc, 5, 6);

      expect(result.document.toPlainText(), 'Hello');
    });

    test('toggleStyle should apply bold to selected text', () {
      final doc = DocumentModel.fromPlainText('Hello');
      const selection = TextSelection(baseOffset: 0, extentOffset: 5);
      final result = DocumentManipulator.toggleStyle(
        doc,
        selection,
        StyleAttribute.bold,
      );

      final textBlock = result.document.blocks.first as TextBlock;
      expect(textBlock.spans.first.isBold, true);
    });

    test('changeBlockIndent should update block attributes', () {
      final doc = DocumentModel.fromPlainText('List item');
      final result = DocumentManipulator.changeBlockIndent(doc, 0, 1);

      expect(result.document.blocks.first.attributes['indent'], 1);
    });

    test('insertImage should add an image block', () {
      final doc = DocumentModel.fromPlainText('Text');
      final result = DocumentManipulator.insertImage(doc, 1, 'path/to/img.png');

      expect(result.document.blocks.length, 3);
      expect(result.document.blocks[1], isA<ImageBlock>());
      expect(
        (result.document.blocks[1] as ImageBlock).imagePath,
        'path/to/img.png',
      );
    });

    test('convertBlockToCallout should transform block type', () {
      final doc = DocumentModel.fromPlainText('Warning text');
      final result = DocumentManipulator.convertBlockToCallout(
        doc,
        0,
        CalloutType.warning,
      );

      expect(result.document.blocks.first, isA<CalloutBlock>());
      expect(
        (result.document.blocks.first as CalloutBlock).type,
        CalloutType.warning,
      );
    });

    test('toggleList should apply list attribute', () {
      final doc = DocumentModel.fromPlainText('Item');
      final result = DocumentManipulator.toggleList(doc, 0, 'bullet');

      expect(result.document.blocks.first.attributes['list'], 'bullet');
    });
  });
}
