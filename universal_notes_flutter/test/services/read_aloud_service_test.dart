import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:universal_notes_flutter/services/read_aloud_service.dart';

@GenerateMocks([FlutterTts])
import 'read_aloud_service_test.mocks.dart';

void main() {
  group('ReadAloudService', () {
    late MockFlutterTts mockTts;
    late ReadAloudService service;

    setUp(() {
      mockTts = MockFlutterTts();

      // Setup default mock behaviors
      when(mockTts.setLanguage(any)).thenAnswer((_) async => 1);
      when(mockTts.setSpeechRate(any)).thenAnswer((_) async => 1);
      when(mockTts.setVolume(any)).thenAnswer((_) async => 1);
      when(mockTts.setPitch(any)).thenAnswer((_) async => 1);
      when(mockTts.setProgressHandler(any)).thenReturn(null);
      when(mockTts.setCompletionHandler(any)).thenReturn(null);
      when(mockTts.setCancelHandler(any)).thenReturn(null);
      when(mockTts.setPauseHandler(any)).thenReturn(null);
      when(mockTts.setContinueHandler(any)).thenReturn(null);
      when(mockTts.speak(any)).thenAnswer((_) async => 1);
      when(mockTts.pause()).thenAnswer((_) async => 1);
      when(mockTts.stop()).thenAnswer((_) async => 1);
      when(mockTts.getVoices).thenAnswer((_) async => <dynamic>[]);
      when(mockTts.getLanguages).thenAnswer((_) async => <dynamic>[]);

      service = ReadAloudService(tts: mockTts);
    });

    tearDown(() async {
      await service.dispose();
    });

    test('creates with default state', () {
      expect(service.state, ReadAloudState.stopped);
      expect(service.speechRate, 1.0);
    });

    group('initialization', () {
      test('initialize sets up TTS engine', () async {
        await service.initialize();

        verify(mockTts.setLanguage('en-US')).called(1);
        verify(mockTts.setSpeechRate(1.0)).called(1);
        verify(mockTts.setVolume(1.0)).called(1);
        verify(mockTts.setPitch(1.0)).called(1);
        verify(mockTts.setProgressHandler(any)).called(1);
        verify(mockTts.setCompletionHandler(any)).called(1);
      });

      test('initialize only runs once', () async {
        await service.initialize();
        await service.initialize();

        verify(mockTts.setLanguage(any)).called(1);
      });
    });

    group('speak', () {
      test('speak initializes and starts playing', () async {
        await service.speak('Hello world');

        verify(mockTts.speak('Hello world')).called(1);
      });

      test('speak updates state to playing', () async {
        final states = <ReadAloudState>[];
        service.stateStream.listen(states.add);

        await service.speak('Test text');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states, contains(ReadAloudState.playing));
      });
    });

    group('pause', () {
      test('pause calls tts pause when playing', () async {
        await service.speak('Hello');
        await service.pause();

        verify(mockTts.pause()).called(1);
      });

      test('pause does nothing when not playing', () async {
        await service.pause();

        verifyNever(mockTts.pause());
      });
    });

    group('stop', () {
      test('stop calls tts stop', () async {
        await service.speak('Hello');
        await service.stop();

        verify(mockTts.stop()).called(1);
      });

      test('stop updates state to stopped', () async {
        final states = <ReadAloudState>[];
        service.stateStream.listen(states.add);

        await service.speak('Test');
        await service.stop();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states.last, ReadAloudState.stopped);
      });
    });

    group('speech rate', () {
      test('setSpeechRate updates rate', () async {
        await service.setSpeechRate(1.5);

        expect(service.speechRate, 1.5);
        verify(mockTts.setSpeechRate(1.5)).called(1);
      });

      test('setSpeechRate clamps to valid range', () async {
        await service.setSpeechRate(3.0);
        expect(service.speechRate, 2.0);

        await service.setSpeechRate(-1.0);
        expect(service.speechRate, 0.0);
      });
    });

    group('language', () {
      test('setLanguage updates TTS language', () async {
        await service.setLanguage('pt-BR');

        verify(mockTts.setLanguage('pt-BR')).called(1);
      });
    });

    group('voices and languages', () {
      test('getVoices returns available voices', () async {
        when(mockTts.getVoices).thenAnswer(
          (_) async => [
            {'name': 'Voice1', 'locale': 'en-US'},
          ],
        );

        final voices = await service.getVoices();

        expect(voices, isNotEmpty);
      });

      test('getLanguages returns available languages', () async {
        when(mockTts.getLanguages).thenAnswer(
          (_) async => ['en-US', 'pt-BR'],
        );

        final languages = await service.getLanguages();

        expect(languages, contains('en-US'));
      });
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
