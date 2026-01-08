import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/reading_settings.dart';
import 'package:notes_hub/widgets/reading/fluent_reading_settings_view.dart';
import 'package:notes_hub/widgets/reading/material_reading_settings_view.dart';

/// Widget for customizing reading mode settings.
///
/// Provides sliders for font size, line height, letter spacing,
/// text alignment, theme selection, and night light toggle.
/// 
/// This widget acts as a platform-adaptive wrapper that selects
/// the appropriate view based on the current platform.
class ReadingModeSettings extends StatelessWidget {
  /// Creates a new [ReadingModeSettings].
  const ReadingModeSettings({
    required this.settings,
    required this.onSettingsChanged,
    this.onReset,
    this.onReadAloudToggle,
    this.currentGoalMinutes = 0,
    this.onGoalChanged,
    super.key,
  });

  /// Current reading settings.
  final ReadingSettings settings;

  /// Callback when settings are changed.
  final ValueChanged<ReadingSettings> onSettingsChanged;

  /// Callback when reset is pressed.
  final VoidCallback? onReset;

  /// Callback when Read Aloud is toggled.
  final VoidCallback? onReadAloudToggle;

  /// Current reading goal in minutes.
  final int currentGoalMinutes;

  /// Callback when the reading goal is changed.
  final ValueChanged<int>? onGoalChanged;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentReadingSettingsView(
        settings: settings,
        onSettingsChanged: onSettingsChanged,
        currentGoalMinutes: currentGoalMinutes,
        onReset: onReset,
        onReadAloudToggle: onReadAloudToggle,
        onGoalChanged: onGoalChanged,
      );
    } else {
      return MaterialReadingSettingsView(
        settings: settings,
        onSettingsChanged: onSettingsChanged,
        currentGoalMinutes: currentGoalMinutes,
        onReset: onReset,
        onReadAloudToggle: onReadAloudToggle,
        onGoalChanged: onGoalChanged,
      );
    }
  }
}
