@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/services/read_aloud_service.dart';

// Note: The ReadAloudService uses FlutterTts which is a native plugin.
// Full integration tests would require a real device or emulator.
// These unit tests focus on the data classes and enums only.

void main() {
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

    test('creates with zero values', () {
      const position = ReadAloudPosition(
        wordIndex: 0,
        startOffset: 0,
        endOffset: 0,
        word: '',
      );

      expect(position.wordIndex, 0);
      expect(position.startOffset, 0);
      expect(position.endOffset, 0);
      expect(position.word, '');
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

    test('has exactly 3 states', () {
      expect(ReadAloudState.values.length, 3);
    });

    test('stopped is the first state', () {
      expect(ReadAloudState.values.first, ReadAloudState.stopped);
    });
  });
}
