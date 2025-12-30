import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
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

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return widget.compact
          ? _buildFluentCompact(context)
          : _buildFluentFull(context);
    } else {
      return widget.compact
          ? _buildMaterialCompact(context)
          : _buildMaterialFull(context);
    }
  }

  Widget _buildFluentCompact(BuildContext context) {
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
              _state == ReadAloudState.playing
                  ? fluent.FluentIcons.pause
                  : fluent.FluentIcons.play,
            ),
            onPressed: () {
              if (_state == ReadAloudState.playing) {
                unawaited(widget.service.pause());
              } else {
                unawaited(widget.service.speak(widget.text));
              }
            },
          ),
          if (_state != ReadAloudState.stopped)
            fluent.IconButton(
              icon: const Icon(fluent.FluentIcons.stop),
              onPressed: () => unawaited(widget.service.stop()),
            ),
          _FluentSpeedButton(
            rate: _speed,
            onChanged: (val) => widget.service.setSpeechRate(val),
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFluentFull(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text('Read Aloud', style: theme.typography.bodyStrong),
              if (widget.onClose != null)
                fluent.IconButton(
                  icon: const Icon(fluent.FluentIcons.chrome_close),
                  onPressed: () {
                    unawaited(widget.service.stop());
                    widget.onClose?.call();
                  },
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
                onPressed: _state == ReadAloudState.stopped
                    ? null
                    : () => unawaited(widget.service.stop()),
                icon: const Icon(fluent.FluentIcons.stop, size: 24),
              ),
              const SizedBox(width: 16),
              fluent.FilledButton(
                onPressed: () {
                  if (_state == ReadAloudState.playing) {
                    unawaited(widget.service.pause());
                  } else {
                    unawaited(widget.service.speak(widget.text));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _state == ReadAloudState.playing
                        ? fluent.FluentIcons.pause
                        : fluent.FluentIcons.play,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _FluentSpeedButton(
                rate: _speed,
                onChanged: (val) => widget.service.setSpeechRate(val),
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
                  value: _speed,
                  min: 0.5,
                  max: 2,
                  divisions: 6,
                  label: '${_speed.toStringAsFixed(1)}x',
                  onChanged: (val) => widget.service.setSpeechRate(val),
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

  Widget _buildMaterialCompact(BuildContext context) {
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
                unawaited(widget.service.pause());
              } else {
                unawaited(widget.service.speak(widget.text));
              }
            },
          ),
          if (_state != ReadAloudState.stopped)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: () => unawaited(widget.service.stop()),
            ),
          _MaterialSpeedButton(
            rate: _speed,
            onChanged: (val) => widget.service.setSpeechRate(val),
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialFull(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text('Read Aloud', style: theme.textTheme.titleMedium),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    unawaited(widget.service.stop());
                    widget.onClose?.call();
                  },
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
                onPressed: _state == ReadAloudState.stopped
                    ? null
                    : () => unawaited(widget.service.stop()),
                icon: const Icon(Icons.stop),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: () {
                  if (_state == ReadAloudState.playing) {
                    unawaited(widget.service.pause());
                  } else {
                    unawaited(widget.service.speak(widget.text));
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
              _MaterialSpeedButton(
                rate: _speed,
                onChanged: (val) => widget.service.setSpeechRate(val),
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
        fluent.MenuFlyoutItem(text: const Text('0.5x'), onPressed: () => onChanged(0.5)),
        fluent.MenuFlyoutItem(text: const Text('0.75x'), onPressed: () => onChanged(0.75)),
        fluent.MenuFlyoutItem(text: const Text('1.0x (Normal)'), onPressed: () => onChanged(1.0)),
        fluent.MenuFlyoutItem(text: const Text('1.25x'), onPressed: () => onChanged(1.25)),
        fluent.MenuFlyoutItem(text: const Text('1.5x'), onPressed: () => onChanged(1.5)),
        fluent.MenuFlyoutItem(text: const Text('1.75x'), onPressed: () => onChanged(1.75)),
        fluent.MenuFlyoutItem(text: const Text('2.0x'), onPressed: () => onChanged(2.0)),
      ],
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
