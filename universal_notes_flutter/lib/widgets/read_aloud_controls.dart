import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/read_aloud_service.dart';

/// Widget for controlling text-to-speech read aloud functionality.
///
/// Provides play/pause/stop controls and speed adjustment.
class ReadAloudControls extends StatelessWidget {
  /// Creates a new [ReadAloudControls].
  const ReadAloudControls({
    required this.state,
    required this.speechRate,
    required this.onPlay,
    required this.onPause,
    required this.onStop,
    required this.onSpeedChanged,
    this.compact = false,
    super.key,
  });

  /// Current playback state.
  final ReadAloudState state;

  /// Current speech rate.
  final double speechRate;

  /// Callback when play is pressed.
  final VoidCallback onPlay;

  /// Callback when pause is pressed.
  final VoidCallback onPause;

  /// Callback when stop is pressed.
  final VoidCallback onStop;

  /// Callback when speed is changed.
  final ValueChanged<double> onSpeedChanged;

  /// Whether to show compact version.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
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
              state == ReadAloudState.playing ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: state == ReadAloudState.playing ? onPause : onPlay,
          ),
          if (state != ReadAloudState.stopped)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: onStop,
            ),
          _SpeedButton(
            rate: speechRate,
            onChanged: onSpeedChanged,
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
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            'Read Aloud',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop
              IconButton.filled(
                onPressed: state == ReadAloudState.stopped ? null : onStop,
                icon: const Icon(Icons.stop),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),

              // Play/Pause (larger)
              IconButton.filled(
                onPressed: state == ReadAloudState.playing ? onPause : onPlay,
                icon: Icon(
                  state == ReadAloudState.playing
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
                rate: speechRate,
                onChanged: onSpeedChanged,
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
                  value: speechRate,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  label: '${speechRate.toStringAsFixed(1)}x',
                  onChanged: onSpeedChanged,
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
        const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
        const PopupMenuItem(value: 1.25, child: Text('1.25x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 1.75, child: Text('1.75x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
    );
  }
}
