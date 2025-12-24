@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/reading_settings.dart';
import 'package:universal_notes_flutter/widgets/reading_mode_settings.dart';

void main() {
  group('ReadingModeSettings', () {
    testWidgets('renders all controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Reading Settings'), findsOneWidget);
      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Line Height'), findsOneWidget);
      expect(find.text('Letter Spacing'), findsOneWidget);
      expect(find.text('Text Alignment'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Night Light'), findsOneWidget);
    });

    testWidgets('shows reset button when callback provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(),
              onSettingsChanged: (_) {},
              onReset: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('hides reset button when callback null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('calls onReset when reset pressed', (tester) async {
      var resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(),
              onSettingsChanged: (_) {},
              onReset: () => resetCalled = true,
            ),
          ),
        ),
      );

      final resetBtn = find.text('Reset');
      await tester.ensureVisible(resetBtn);
      await tester.tap(resetBtn);
      expect(resetCalled, true);
    });

    testWidgets('displays current font size value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(fontSize: 22),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('22'), findsOneWidget);
    });

    testWidgets('calls onSettingsChanged when font size changed', (
      tester,
    ) async {
      ReadingSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(fontSize: 18),
              onSettingsChanged: (s) => changedSettings = s,
            ),
          ),
        ),
      );

      // Find font size slider and drag
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      await tester.ensureVisible(sliders.first);
      await tester.drag(sliders.first, const Offset(50, 0));
      await tester.pump();

      expect(changedSettings, isNotNull);
    });

    testWidgets('shows night light intensity when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(nightLightEnabled: true),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Intensity'), findsOneWidget);
    });

    testWidgets('hides night light intensity when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(nightLightEnabled: false),
              onSettingsChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Intensity'), findsNothing);
    });

    testWidgets('toggles night light calls onSettingsChanged', (tester) async {
      ReadingSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(nightLightEnabled: false),
              onSettingsChanged: (s) => changedSettings = s,
            ),
          ),
        ),
      );

      final switchFinder = find.byType(Switch);
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pump();

      expect(changedSettings?.nightLightEnabled, true);
    });

    testWidgets('renders all theme options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingModeSettings(
                settings: const ReadingSettings(),
                onSettingsChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Sepia'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('selecting theme calls onSettingsChanged', (tester) async {
      ReadingSettings? changedSettings;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingModeSettings(
              settings: const ReadingSettings(theme: ReadingTheme.light),
              onSettingsChanged: (s) => changedSettings = s,
            ),
          ),
        ),
      );

      final sepiaFinder = find.text('Sepia');
      await tester.ensureVisible(sepiaFinder);
      await tester.tap(sepiaFinder);
      await tester.pump();

      expect(changedSettings?.theme, ReadingTheme.sepia);
    });

    testWidgets('renders alignment buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingModeSettings(
                settings: const ReadingSettings(),
                onSettingsChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_align_left), findsOneWidget);
      expect(find.byIcon(Icons.format_align_center), findsOneWidget);
      expect(find.byIcon(Icons.format_align_right), findsOneWidget);
      expect(find.byIcon(Icons.format_align_justify), findsOneWidget);
    });
  });
}
