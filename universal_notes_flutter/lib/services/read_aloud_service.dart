import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Service for text-to-speech reading aloud functionality.
///
/// Provides play, pause, stop controls and text highlight sync.
class ReadAloudService {
  /// Creates a new [ReadAloudService].
  ReadAloudService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  /// Stream of currently highlighted word positions.
  Stream<ReadAloudPosition> get positionStream => _positionController.stream;

  /// Stream of playback state changes.
  Stream<ReadAloudState> get stateStream => _stateController.stream;

  /// Current playback state.
  ReadAloudState get currentState => _state;

  /// Current speech rate (0.0 to 2.0).
  double get currentSpeed => _speechRate;

  /// Stream of speed changes.
  Stream<double> get speedStream => _speedController.stream;

  final StreamController<ReadAloudPosition> _positionController =
      StreamController<ReadAloudPosition>.broadcast();

  final StreamController<ReadAloudState> _stateController =
      StreamController<ReadAloudState>.broadcast();

  final StreamController<double> _speedController =
      StreamController<double>.broadcast();

  ReadAloudState _state = ReadAloudState.stopped;
  double _speechRate = 1;
  String _currentText = '';
  int _currentWordIndex = 0;
  List<_Word> _words = [];
  bool _initialized = false;

  /// Initializes the TTS engine.
  Future<void> initialize() async {
    if (_initialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1);
    await _tts.setPitch(1);

    _tts.setProgressHandler(_handleProgress);

    _tts
      ..setCompletionHandler(() {
        _updateState(ReadAloudState.stopped);
        _currentWordIndex = 0;
      })
      ..setCancelHandler(() {
        _updateState(ReadAloudState.stopped);
      })
      ..setPauseHandler(() {
        _updateState(ReadAloudState.paused);
      })
      ..setContinueHandler(() {
        _updateState(ReadAloudState.playing);
      });

    _initialized = true;
  }

  /// Starts speaking the given text.
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();

    _currentText = text;
    _words = _parseWords(text);
    _currentWordIndex = 0;

    _updateState(ReadAloudState.playing);
    await _tts.speak(text);
  }

  /// Pauses the current speech.
  Future<void> pause() async {
    if (_state == ReadAloudState.playing) {
      await _tts.pause();
      _updateState(ReadAloudState.paused);
    }
  }

  /// Resumes paused speech.
  Future<void> resume() async {
    if (_state == ReadAloudState.paused) {
      // Flutter TTS doesn't have a true resume, so we restart from current
      // position in practice. For simplicity, we just continue.
      await _tts.speak(_currentText);
      _updateState(ReadAloudState.playing);
    }
  }

  /// Stops the current speech.
  Future<void> stop() async {
    await _tts.stop();
    _currentWordIndex = 0;
    _updateState(ReadAloudState.stopped);
  }

  /// Sets the speech rate (0.0 to 2.0).
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 2.0);
    _speedController.add(_speechRate);
    await _tts.setSpeechRate(_speechRate);
  }

  /// Sets the language for TTS.
  Future<void> setLanguage(String lang) async {
    await _tts.setLanguage(lang);
  }

  /// Gets available voices.
  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices as List<dynamic>;
  }

  /// Gets available languages.
  Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages as List<dynamic>;
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await stop();
    await _positionController.close();
    await _stateController.close();
    await _speedController.close();
  }

  void _handleProgress(String text, int start, int end, String word) {
    // Find the word index based on character position
    for (var i = 0; i < _words.length; i++) {
      if (_words[i].start <= start && _words[i].end >= end) {
        _currentWordIndex = i;
        break;
      }
    }

    _positionController.add(
      ReadAloudPosition(
        wordIndex: _currentWordIndex,
        startOffset: start,
        endOffset: end,
        word: word,
      ),
    );
  }

  List<_Word> _parseWords(String text) {
    final words = <_Word>[];
    final pattern = RegExp(r'\S+');
    for (final match in pattern.allMatches(text)) {
      words.add(_Word(match.start, match.end));
    }
    return words;
  }

  void _updateState(ReadAloudState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }
}

/// Position info for highlighting during read aloud.
class ReadAloudPosition {
  /// Creates a new [ReadAloudPosition].
  const ReadAloudPosition({
    required this.wordIndex,
    required this.startOffset,
    required this.endOffset,
    required this.word,
  });

  /// Index of the current word.
  final int wordIndex;

  /// Start character offset in the text.
  final int startOffset;

  /// End character offset in the text.
  final int endOffset;

  /// The word being spoken.
  final String word;
}

/// Playback state for read aloud.
enum ReadAloudState {
  /// Not playing.
  stopped,

  /// Currently playing.
  playing,

  /// Paused.
  paused,
}

class _Word {
  const _Word(this.start, this.end);
  final int start;
  final int end;
}
