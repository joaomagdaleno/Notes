import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/reading_settings.dart';

class FluentReadingSettingsView extends StatelessWidget {
  const FluentReadingSettingsView({
    required this.settings,
    required this.onSettingsChanged,
    required this.currentGoalMinutes,
    this.onReset,
    this.onReadAloudToggle,
    this.onGoalChanged,
    super.key,
  });

  final ReadingSettings settings;
  final ValueChanged<ReadingSettings> onSettingsChanged;
  final int currentGoalMinutes;
  final VoidCallback? onReset;
  final VoidCallback? onReadAloudToggle;
  final ValueChanged<int>? onGoalChanged;

  @override
  Widget build(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reading Settings', style: theme.typography.subtitle),
                if (onReset != null)
                  fluent.HyperlinkButton(
                    onPressed: onReset,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(fluent.FluentIcons.refresh, size: 14),
                        const SizedBox(width: 4),
                        const Text('Reset'),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Font Size
            _SettingRow(
              label: 'Font Size',
              value: '${settings.fontSize.toInt()}',
              child: fluent.Slider(
                value: settings.fontSize,
                min: 14,
                max: 28,
                divisions: 14,
                onChanged: (value) {
                  onSettingsChanged(settings.copyWith(fontSize: value));
                },
              ),
            ),

            // Line Height
            _SettingRow(
              label: 'Line Height',
              value: settings.lineHeight.toStringAsFixed(1),
              child: fluent.Slider(
                value: settings.lineHeight,
                min: 1.2,
                max: 2.5,
                divisions: 13,
                onChanged: (value) {
                  onSettingsChanged(settings.copyWith(lineHeight: value));
                },
              ),
            ),

            // Letter Spacing
            _SettingRow(
              label: 'Letter Spacing',
              value: settings.letterSpacing.toStringAsFixed(1),
              child: fluent.Slider(
                value: settings.letterSpacing,
                min: -1,
                max: 3,
                divisions: 8,
                onChanged: (value) {
                  onSettingsChanged(settings.copyWith(letterSpacing: value));
                },
              ),
            ),

            // Font Family
            _SettingRow(
              label: 'Font Family',
              value: settings.fontFamily,
              child: fluent.ComboBox<String>(
                value: settings.fontFamily,
                isExpanded: true,
                items: [
                  'Default',
                  'Serif',
                  'Sans-Serif',
                  'Monospace',
                  'Roboto',
                  'Lora',
                  'Merriweather',
                ].map((f) => fluent.ComboBoxItem(value: f, child: Text(f))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onSettingsChanged(settings.copyWith(fontFamily: value));
                  }
                },
              ),
            ),

            // Paragraph Spacing
            _SettingRow(
              label: 'Paragraph Spacing',
              value: '${settings.paragraphSpacing.toInt()}',
              child: fluent.Slider(
                value: settings.paragraphSpacing,
                max: 48,
                divisions: 12,
                onChanged: (value) {
                  onSettingsChanged(settings.copyWith(paragraphSpacing: value));
                },
              ),
            ),

            const SizedBox(height: 16),

            // Theme Selection
            Text('Theme', style: theme.typography.bodyStrong),
            const SizedBox(height: 8),
            _ThemeSelector(
              selected: settings.theme,
              onChanged: (newTheme) {
                onSettingsChanged(settings.copyWith(theme: newTheme));
              },
              primaryColor: theme.accentColor,
            ),

            const SizedBox(height: 20),

            // Night Light
            fluent.ToggleSwitch(
              checked: settings.nightLightEnabled,
              content: const Text('Night Light'),
              onChanged: (value) {
                onSettingsChanged(settings.copyWith(nightLightEnabled: value));
              },
            ),

            if (settings.nightLightEnabled)
              _SettingRow(
                label: 'Intensity',
                value: '${(settings.nightLightIntensity * 100).toInt()}%',
                child: fluent.Slider(
                  value: settings.nightLightIntensity,
                  min: 0.1,
                  max: 0.8,
                  divisions: 7,
                  onChanged: (value) {
                    onSettingsChanged(settings.copyWith(nightLightIntensity: value));
                  },
                ),
              ),

            const SizedBox(height: 16),

            if (onReadAloudToggle != null)
              fluent.ListTile.selectable(
                title: const Text('Read Aloud'),
                subtitle: const Text('Text-to-Speech controls'),
                leading: const Icon(fluent.FluentIcons.microphone),
                trailing: const Icon(fluent.FluentIcons.chevron_right),
                onPressed: onReadAloudToggle,
              ),

            const Divider(height: 32),

            // Reading Goal
            _SettingRow(
              label: 'Daily Goal',
              value: '$currentGoalMinutes min',
              child: fluent.Slider(
                value: currentGoalMinutes.toDouble(),
                max: 120,
                divisions: 12,
                onChanged: onGoalChanged != null
                    ? (value) => onGoalChanged!(value.toInt())
                    : null,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.child,
  });

  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: fluent.FluentTheme.of(context).typography.caption),
          ],
        ),
        child,
      ],
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.selected,
    required this.onChanged,
    required this.primaryColor,
  });

  final ReadingTheme selected;
  final ValueChanged<ReadingTheme> onChanged;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ReadingTheme.values.map((theme) {
        final isSelected = theme == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => onChanged(theme),
            child: Container(
              width: 60,
              height: 80,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Aa',
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.name.capitalize(),
                    style: TextStyle(
                      color: theme.textColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
