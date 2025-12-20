import 'package:test/test.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/tag.dart';
import 'package:universal_notes_flutter/services/tag_suggestion_service.dart';

// Note: This test might fail to run with 'dart test' if Flutter imports
// cannot be resolved. It is intended for 'flutter test' later.

void main() {
  group('TagSuggestionService', () {
    test('should suggest tags found in document text', () {
      final document = DocumentModel.fromPlainText(
        'This is a note about Flutter and Dart.',
      );
      final allTags = [
        const Tag(id: '1', name: 'Flutter'),
        const Tag(id: '2', name: 'Dart'),
        const Tag(id: '3', name: 'Firebase'),
      ];

      final suggestions = TagSuggestionService.getSuggestions(
        document: document,
        allTags: allTags,
        currentTags: [],
      );

      expect(suggestions.length, 2);
      expect(suggestions.map((t) => t.name), containsAll(['Flutter', 'Dart']));
    });

    test('should not suggest tags already in currentTags', () {
      final document = DocumentModel.fromPlainText('Flutter is awesome.');
      final allTags = [const Tag(id: '1', name: 'Flutter')];
      final currentTags = [const Tag(id: '1', name: 'Flutter')];

      final suggestions = TagSuggestionService.getSuggestions(
        document: document,
        allTags: allTags,
        currentTags: currentTags,
      );

      expect(suggestions, isEmpty);
    });

    test('should sort suggestions by frequency', () {
      final document = DocumentModel.fromPlainText('Flutter Flutter Dart');
      final allTags = [
        const Tag(id: '1', name: 'Flutter'),
        const Tag(id: '2', name: 'Dart'),
      ];

      final suggestions = TagSuggestionService.getSuggestions(
        document: document,
        allTags: allTags,
        currentTags: [],
      );

      expect(suggestions[0].name, 'Flutter');
      expect(suggestions[1].name, 'Dart');
    });

    test('should only match whole words', () {
      final document = DocumentModel.fromPlainText('Butter is not Flutter.');
      final allTags = [const Tag(id: '1', name: 'Utter')];

      final suggestions = TagSuggestionService.getSuggestions(
        document: document,
        allTags: allTags,
        currentTags: [],
      );

      expect(suggestions, isEmpty);
    });
  });
}
