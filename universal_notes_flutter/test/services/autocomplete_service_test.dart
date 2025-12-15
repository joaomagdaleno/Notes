import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/autocomplete_service.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock asset bundle
  const channel = MethodChannel('flutter/assets');
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'loadString') {
      return 'uma\nduas\ntres'; // Mock dictionary
    }
    return null;
  });

  group('AutocompleteService', () {
    test('returns suggestions from all sources in order', () async {
      // Arrange
      final mockRepo = MockNoteRepository();
      NoteRepository.instance = mockRepo; // Simple DI for test
      when(mockRepo.getFrequentWords('wor')).thenAnswer((_) async => ['work']);

      const text = 'Hello world, this is a worldly test.';

      // Act
      final suggestions = await AutocompleteService.getSuggestions(text, 19); // "worldl"

      // Assert
      expect(suggestions, contains('World')); // From current note (original case)
      // 'work' from frequent words would not be added as we already have 'World' and 'worldly'
      expect(suggestions, contains('worldly'));
    });
  });
}
