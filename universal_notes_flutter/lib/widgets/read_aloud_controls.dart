import 'dart:async';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/read_aloud_service.dart';

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
  double _speed = 1.0;

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
    _stateSub.cancel();
    _speedSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _state == ReadAloudState.playing ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
              if (_state == ReadAloudState.playing) {
                widget.service.pause();
              } else {
                widget.service.speak(widget.text);
              }
            },
          ),
          if (_state != ReadAloudState.stopped)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => widget.service.stop(),
            ),
          _SpeedButton(
            rate: _speed,
            onChanged: (val) => widget.service.setSpeechRate(val),
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48), // Spacer
              Text(
                'Read Aloud',
                style: theme.textTheme.titleMedium,
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    widget.service.stop();
                    widget.onClose?.call();
                  },
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop
              IconButton.filled(
                onPressed: _state == ReadAloudState.stopped
                    ? null
                    : () => widget.service.stop(),
                icon: const Icon(Icons.stop),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),

              // Play/Pause (larger)
              IconButton.filled(
                onPressed: () {
                  if (_state == ReadAloudState.playing) {
                    widget.service.pause();
                  } else {
                    widget.service.speak(widget.text);
                  }
                },
                icon: Icon(
                  _state == ReadAloudState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                  size: 32,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(64, 64),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 16),

              // Speed
              _SpeedButton(
                rate: _speed,
                onChanged: (val) => widget.service.setSpeechRate(val),
                compact: false,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Speed slider
          Row(
            children: [
              const Icon(Icons.slow_motion_video, size: 20),
              Expanded(
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 2,
                  divisions: 6,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: (val) => widget.service.setSpeechRate(val),
                ),
              ),
              const Icon(Icons.speed, size: 20),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.rate,
    required this.onChanged,
    required this.compact,
  });

  final double rate;
  final ValueChanged<double> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<double>(
      initialValue: rate,
      onSelected: onChanged,
      tooltip: 'Speed',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(compact ? 12 : 8),
        ),
        child: Text(
          '${rate.toStringAsFixed(1)}x',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 0.75, child: Text('0.75x')),
        const PopupMenuItem(value: 1, child: Text('1.0x (Normal)')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 1.75, child: Text('1.75x')),
        const PopupMenuItem(value: 2, child: Text('2.0x')),
      ],
    );
  }
}
