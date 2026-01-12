import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/widgets.dart';

import 'package:notes_hub/services/read_aloud_service.dart';

/// A Windows-specific view for Read Aloud (TTS) controls.
class FluentReadAloudView extends StatelessWidget {
  /// Creates a [FluentReadAloudView].
  const FluentReadAloudView({
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
    final theme = fluent.FluentTheme.of(context);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.resources.subtleFillColorSecondary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          fluent.IconButton(
            icon: Icon(
              state == ReadAloudState.playing
                  ? fluent.FluentIcons.pause
                  : fluent.FluentIcons.play,
            ),
            onPressed: onTogglePlayPause,
          ),
          if (state != ReadAloudState.stopped)
            fluent.IconButton(
              icon: const Icon(fluent.FluentIcons.stop),
              onPressed: onStop,
            ),
          _FluentSpeedButton(
            rate: speed,
            onChanged: onSpeedChanged,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
              Text('Read Aloud', style: theme.typography.bodyStrong),
              if (onClose != null)
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.chrome_close),
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
              fluent.IconButton(
                onPressed: state == ReadAloudState.stopped ? null : onStop,
                icon: const Icon(fluent.FluentIcons.stop, size: 24),
              ),
              const SizedBox(width: 16),
              fluent.FilledButton(
                onPressed: onTogglePlayPause,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    state == ReadAloudState.playing
                        ? fluent.FluentIcons.pause
                        : fluent.FluentIcons.play,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _FluentSpeedButton(
                rate: speed,
                onChanged: onSpeedChanged,
                compact: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(fluent.FluentIcons.play, size: 16),
              Expanded(
                child: fluent.Slider(
                  value: speed,
                  min: 0.5,
                  max: 2,
                  divisions: 6,
                  label: '${speed.toStringAsFixed(1)}x',
                  onChanged: onSpeedChanged,
                ),
              ),
              const Icon(fluent.FluentIcons.fast_forward, size: 16),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FluentSpeedButton extends StatelessWidget {
  const _FluentSpeedButton({
    required this.rate,
    required this.onChanged,
    required this.compact,
  });

  final double rate;
  final ValueChanged<double> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return fluent.DropDownButton(
      title: Text(
        '${rate.toStringAsFixed(1)}x',
        style: theme.typography.bodyStrong,
      ),
      items: [
        fluent.MenuFlyoutItem(
          text: const Text('0.5x'),
          onPressed: () => onChanged(0.5),
        ),
        fluent.MenuFlyoutItem(
          text: const Text('0.75x'),
          onPressed: () => onChanged(0.75),
        ),
        fluent.MenuFlyoutItem(
          text: const Text('1.0x (Normal)'),
          onPressed: () => onChanged(1),
        ),
        fluent.MenuFlyoutItem(
          text: const Text('1.25x'),
          onPressed: () => onChanged(1.25),
        ),
        fluent.MenuFlyoutItem(
          text: const Text('1.5x'),
          onPressed: () => onChanged(1.5),
        ),
        fluent.MenuFlyoutItem(
          text: const Text('1.75x'),
          onPressed: () => onChanged(1.75),
        ),
        fluent.MenuFlyoutItem(
          text: const Text('2.0x'),
          onPressed: () => onChanged(2),
        ),
      ],
    );
  }
}
