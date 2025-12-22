import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/autocomplete_service.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNoteRepository mockRepo;

  setUp(() {
    mockRepo = MockNoteRepository();
    NoteRepository.instance = mockRepo;
    AutocompleteService.resetCache();

    // Mock asset loading for dictionaries
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
          final Uint8List encoded = message!.buffer.asUint8List();
          final String key = utf8.decode(encoded);
          if (key == 'assets/dictionaries/pt_br_common.txt') {
            return utf8.encoder
                .convert('trabalho\ntraducao\ntreinar')
                .buffer
                .asByteData();
          }
          return null;
        });
  });

  group('AutocompleteService', () {
    test('isWordBoundary should correctly identify boundaries', () {
      expect(AutocompleteService.isWordBoundary(' '), isTrue);
      expect(AutocompleteService.isWordBoundary('\n'), isTrue);
      expect(AutocompleteService.isWordBoundary('.'), isTrue);
      expect(AutocompleteService.isWordBoundary('a'), isFalse);
    });

    test('getSuggestions extracts words from current note', () async {
      when(mockRepo.getLearnedWords(any)).thenAnswer((_) async => []);

      const text = 'Flutter is amazing and Flutters strongly.';
      // Cursor at the end of "Flutt" (index 28)
      final suggestions = await AutocompleteService.getSuggestions(text, 28);

      expect(suggestions, contains('Flutter'));
      expect(suggestions, contains('Flutters'));
    });

    test('getSuggestions uses learned words', () async {
      when(
        mockRepo.getLearnedWords('wor'),
      ).thenAnswer((_) async => ['Workplace']);

      const text = 'Hello wor';
      final suggestions = await AutocompleteService.getSuggestions(text, 9);

      expect(suggestions, contains('Workplace'));
    });

    test('getSuggestions falls back to dictionary', () async {
      when(mockRepo.getLearnedWords('tra')).thenAnswer((_) async => []);

      const text = 'Eu tra';
      final suggestions = await AutocompleteService.getSuggestions(text, 6);

      expect(suggestions, contains('trabalho'));
      expect(suggestions, contains('traducao'));
    });
  });
}
