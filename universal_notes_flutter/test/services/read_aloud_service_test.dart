import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/read_aloud_service.dart';

// Note: These tests use a simplified approach that doesn't require mocks
// for FlutterTts, focusing on the service's internal state management.

void main() {
  group('ReadAloudService', () {
    test('creates with default state', () {
      final service = ReadAloudService();

      expect(service.state, ReadAloudState.stopped);
      expect(service.speechRate, 1.0);
    });

    group('speech rate', () {
      test('setSpeechRate updates rate', () async {
        final service = ReadAloudService();

        await service.setSpeechRate(1.5);

        expect(service.speechRate, 1.5);
      });

      test('setSpeechRate clamps to max 2.0', () async {
        final service = ReadAloudService();

        await service.setSpeechRate(3.0);

        expect(service.speechRate, 2.0);
      });

      test('setSpeechRate clamps to min 0.0', () async {
        final service = ReadAloudService();

        await service.setSpeechRate(-1.0);

        expect(service.speechRate, 0.0);
      });
    });

    test('dispose closes streams', () async {
      final service = ReadAloudService();

      await service.dispose();

      // Streams should be closed after dispose
      expect(
        () => service.stateStream.listen((_) {}),
        throwsStateError,
      );
    });
  });

  group('ReadAloudPosition', () {
    test('creates with values', () {
      const position = ReadAloudPosition(
        wordIndex: 5,
        startOffset: 20,
        endOffset: 25,
        word: 'hello',
      );

      expect(position.wordIndex, 5);
      expect(position.startOffset, 20);
      expect(position.endOffset, 25);
      expect(position.word, 'hello');
    });
  });

  group('ReadAloudState', () {
    test('has all expected values', () {
      expect(
        ReadAloudState.values,
        containsAll([
          ReadAloudState.stopped,
          ReadAloudState.playing,
          ReadAloudState.paused,
        ]),
      );
    });
  });
}
