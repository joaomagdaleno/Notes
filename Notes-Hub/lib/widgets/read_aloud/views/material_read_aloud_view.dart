import 'package:flutter/material.dart';
import 'package:notes_hub/services/read_aloud_service.dart';

/// A Material Design view for Read Aloud (TTS) controls.
class MaterialReadAloudView extends StatelessWidget {
  /// Creates a [MaterialReadAloudView].
  const MaterialReadAloudView({
    required this.state,
    required this.speed,
    required this.compact,
    required this.text,
    required this.onTogglePlayPause,
    required this.onStop,
    required this.onSpeedChanged,
    required this.onClose,
    super.key,
  });

  /// The current state of the TTS engine.
  final ReadAloudState state;

  /// The current playback speed.
  final double speed;

  /// Whether to display a compact or full UI.
  final bool compact;

  /// The text content being read aloud.
  final String text;

  /// Callback to play or pause playback.
  final VoidCallback onTogglePlayPause;

  /// Callback to stop playback completely.
  final VoidCallback onStop;

  /// Callback when the playback speed is changed.
  final ValueChanged<double> onSpeedChanged;

  /// Optional callback to close the controls.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFull(context);
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
            onPressed: onTogglePlayPause,
          ),
          if (state != ReadAloudState.stopped)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: onStop,
            ),
          _MaterialSpeedButton(
            rate: speed,
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
            color: const Color(0xff000000).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text('Read Aloud', style: theme.textTheme.titleMedium),
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filled(
                onPressed: state == ReadAloudState.stopped ? null : onStop,
                icon: const Icon(Icons.stop),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: onTogglePlayPause,
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
              _MaterialSpeedButton(
                rate: speed,
                onChanged: onSpeedChanged,
                compact: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.slow_motion_video, size: 20),
              Expanded(
                child: Slider(
                  value: speed,
                  min: 0.5,
                  max: 2,
                  divisions: 6,
                  label: '${speed.toStringAsFixed(1)}x',
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

class _MaterialSpeedButton extends StatelessWidget {
  const _MaterialSpeedButton({
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
