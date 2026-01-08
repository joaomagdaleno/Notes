import 'dart:async';

/// Service for text-to-speech reading aloud functionality.
///
/// Provides play, pause, stop controls.
/// Currently stubbed out as text_to_speech dependency has been removed.
class ReadAloudService {
  /// Creates a new [ReadAloudService].
  ReadAloudService();

  /// Stream of currently highlighted word positions
  /// (empty in this implementation).

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

  /// Initializes the TTS engine.
  Future<void> initialize() async {
    // Stubbed: initialization
  }

  /// Starts speaking the given text.
  Future<void> speak(String text) async {
    _updateState(ReadAloudState.playing);
    // Stubbed: speak
    // debugPrint('ReadAloudService (Stub): Speaking "$text"');

    // Simulate completion after a short delay or just stop immediately for now
    await Future<void>.delayed(const Duration(seconds: 1));

    _updateState(ReadAloudState.stopped);
  }

  /// Pauses the current speech.
  Future<void> pause() async {
    if (_state == ReadAloudState.playing) {
      // Stubbed: pause
      _updateState(ReadAloudState.paused);
    }
  }

  /// Resumes paused speech.
  Future<void> resume() async {
    if (_state == ReadAloudState.paused) {
      // Stubbed: resume
      _updateState(ReadAloudState.playing);
    }
  }

  /// Stops the current speech.
  Future<void> stop() async {
    // Stubbed: stop
    _updateState(ReadAloudState.stopped);
  }

  /// Sets the speech rate (0.0 to 2.0).
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 2.0);
    _speedController.add(_speechRate);
    // Stubbed: setRate
  }

  /// Sets the language for TTS.
  Future<void> setLanguage(String lang) async {
    // Stubbed: setLanguage
  }

  /// Gets available languages.
  Future<List<String>> getLanguages() async {
    // Stubbed: getLanguages
    return ['en-US', 'pt-BR']; // Return dummy languages
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await stop();
    await _positionController.close();
    await _stateController.close();
    await _speedController.close();
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
