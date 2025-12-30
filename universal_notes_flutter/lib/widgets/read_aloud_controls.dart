import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/read_aloud_service.dart';
import 'package:universal_notes_flutter/widgets/read_aloud/views/fluent_read_aloud_view.dart';
import 'package:universal_notes_flutter/widgets/read_aloud/views/material_read_aloud_view.dart';

/// Widget for controlling text-to-speech read aloud functionality.
///
/// Provides play/pause/stop controls and speed adjustment.
class ReadAloudControls extends StatefulWidget {
  /// Creates a new [ReadAloudControls].
  const ReadAloudControls({
    required this.service,
    required this.text,
    this.onClose,
    this.compact = false,
    super.key,
  });

  /// The TTS service to use.
  final ReadAloudService service;

  /// The text to read.
  final String text;

  /// Callback when the controls are closed.
  final VoidCallback? onClose;

  /// Whether to show compact version.
  final bool compact;

  @override
  State<ReadAloudControls> createState() => _ReadAloudControlsState();
}

class _ReadAloudControlsState extends State<ReadAloudControls> {
  late StreamSubscription<ReadAloudState> _stateSub;
  late StreamSubscription<double> _speedSub;

  ReadAloudState _state = ReadAloudState.stopped;
  double _speed = 1;

  @override
  void initState() {
    super.initState();
    _state = widget.service.currentState;
    _speed = widget.service.currentSpeed;

    _stateSub = widget.service.stateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    _speedSub = widget.service.speedStream.listen((speed) {
      if (mounted) setState(() => _speed = speed);
    });
  }

  @override
  void dispose() {
    unawaited(_stateSub.cancel());
    unawaited(_speedSub.cancel());
    super.dispose();
  }

  void _handleTogglePlayPause() {
    if (_state == ReadAloudState.playing) {
      unawaited(widget.service.pause());
    } else {
      unawaited(widget.service.speak(widget.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentReadAloudView(
        state: _state,
        speed: _speed,
        compact: widget.compact,
        text: widget.text,
        onTogglePlayPause: _handleTogglePlayPause,
        onStop: () => unawaited(widget.service.stop()),
        onSpeedChanged: (val) => widget.service.setSpeechRate(val),
        onClose: widget.onClose != null
            ? () {
                unawaited(widget.service.stop());
                widget.onClose?.call();
              }
            : null,
      );
    } else {
      return MaterialReadAloudView(
        state: _state,
        speed: _speed,
        compact: widget.compact,
        text: widget.text,
        onTogglePlayPause: _handleTogglePlayPause,
        onStop: () => unawaited(widget.service.stop()),
        onSpeedChanged: (val) => widget.service.setSpeechRate(val),
        onClose: widget.onClose != null
            ? () {
                unawaited(widget.service.stop());
                widget.onClose?.call();
              }
            : null,
      );
    }
  }
}
