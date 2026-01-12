@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_hub/editor/document.dart';
import 'package:notes_hub/editor/snippet_converter.dart';
import 'package:notes_hub/models/snippet.dart';
import 'package:notes_hub/repositories/note_repository.dart';

import '../test_helper.dart'; // For MockNoteRepository

void main() {
  late MockNoteRepository mockNoteRepository;

  setUp(() {
    mockNoteRepository = MockNoteRepository();
    // Inject mock into singleton
    NoteRepository.instance = mockNoteRepository;
  });

  group('SnippetConverter', () {
    test('checkAndApply should return null if no snippets cached', () async {
      when(
        () => mockNoteRepository.getAllSnippets(),
      ).thenAnswer((_) async => []);
      await SnippetConverter.precacheSnippets();

      final doc = DocumentModel.fromPlainText(';test ');
      const selection = TextSelection.collapsed(offset: 6);

      final result = SnippetConverter.checkAndApply(doc, selection);
      expect(result, isNull);
    });

    test(
      'checkAndApply should expand snippet when trigger + space is typed',
      () async {
        final snippets = [
          const Snippet(
            id: '1',
            trigger: ';gm',
            content: 'Good Morning!',
          ),
        ];
        when(
          () => mockNoteRepository.getAllSnippets(),
        ).thenAnswer((_) async => snippets);
        await SnippetConverter.precacheSnippets();

        final doc = DocumentModel.fromPlainText('Hello ;gm ');
        const selection = TextSelection.collapsed(offset: 10);

        final result = SnippetConverter.checkAndApply(doc, selection);

        expect(result, isNotNull);
        expect(result!.document.toPlainText(), 'Hello Good Morning!');
        expect(result.selection.baseOffset, 19);
      },
    );

    test('checkAndApply should not expand if no space at the end', () async {
      final snippets = <Snippet>[
        const Snippet(
          id: '1',
          trigger: ';gm',
          content: 'Good Morning!',
        ),
      ];
      when(
        () => mockNoteRepository.getAllSnippets(),
      ).thenAnswer((_) async => snippets);
      await SnippetConverter.precacheSnippets();

      final doc = DocumentModel.fromPlainText(';gm');
      const selection = TextSelection.collapsed(offset: 3);

      final result = SnippetConverter.checkAndApply(doc, selection);
      expect(result, isNull);
    });
  });
}
