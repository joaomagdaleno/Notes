import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/reading_settings.dart';

void main() {
  group('ReadingSettings', () {
    test('creates with default values', () {
      const settings = ReadingSettings();

      expect(settings.fontSize, 18.0);
      expect(settings.lineHeight, 1.6);
      expect(settings.letterSpacing, 0.0);
      expect(settings.textAlign, TextAlign.left);
      expect(settings.theme, ReadingTheme.light);
      expect(settings.fontFamily, 'Default');
      expect(settings.nightLightEnabled, false);
      expect(settings.nightLightIntensity, 0.3);
    });

    test('creates with custom values', () {
      const settings = ReadingSettings(
        fontSize: 24.0,
        lineHeight: 2.0,
        letterSpacing: 1.5,
        textAlign: TextAlign.justify,
        theme: ReadingTheme.sepia,
        fontFamily: 'Roboto',
        nightLightEnabled: true,
        nightLightIntensity: 0.6,
      );

      expect(settings.fontSize, 24.0);
      expect(settings.lineHeight, 2.0);
      expect(settings.letterSpacing, 1.5);
      expect(settings.textAlign, TextAlign.justify);
      expect(settings.theme, ReadingTheme.sepia);
      expect(settings.fontFamily, 'Roboto');
      expect(settings.nightLightEnabled, true);
      expect(settings.nightLightIntensity, 0.6);
    });

    test('defaults constant has correct values', () {
      expect(ReadingSettings.defaults.fontSize, 18.0);
      expect(ReadingSettings.defaults.lineHeight, 1.6);
      expect(ReadingSettings.defaults.theme, ReadingTheme.light);
    });

    group('JSON serialization', () {
      test('toJson converts to map', () {
        const settings = ReadingSettings(
          fontSize: 20.0,
          lineHeight: 1.8,
          letterSpacing: 0.5,
          textAlign: TextAlign.center,
          theme: ReadingTheme.dark,
          fontFamily: 'Georgia',
          nightLightEnabled: true,
          nightLightIntensity: 0.4,
        );

        final json = settings.toJson();

        expect(json['fontSize'], 20.0);
        expect(json['lineHeight'], 1.8);
        expect(json['letterSpacing'], 0.5);
        expect(json['textAlign'], 'center');
        expect(json['theme'], 'dark');
        expect(json['fontFamily'], 'Georgia');
        expect(json['nightLightEnabled'], true);
        expect(json['nightLightIntensity'], 0.4);
      });

      test('fromJson creates from map', () {
        final json = {
          'fontSize': 22.0,
          'lineHeight': 1.5,
          'letterSpacing': 0.2,
          'textAlign': 'justify',
          'theme': 'sepia',
          'fontFamily': 'Arial',
          'nightLightEnabled': false,
          'nightLightIntensity': 0.5,
        };

        final settings = ReadingSettings.fromJson(json);

        expect(settings.fontSize, 22.0);
        expect(settings.lineHeight, 1.5);
        expect(settings.letterSpacing, 0.2);
        expect(settings.textAlign, TextAlign.justify);
        expect(settings.theme, ReadingTheme.sepia);
        expect(settings.fontFamily, 'Arial');
        expect(settings.nightLightEnabled, false);
        expect(settings.nightLightIntensity, 0.5);
      });

      test('fromJson handles missing values with defaults', () {
        final json = <String, dynamic>{};

        final settings = ReadingSettings.fromJson(json);

        expect(settings.fontSize, 18.0);
        expect(settings.lineHeight, 1.6);
        expect(settings.letterSpacing, 0.0);
        expect(settings.theme, ReadingTheme.light);
        expect(settings.fontFamily, 'Default');
      });

      test('fromJson handles unknown enum values', () {
        final json = {
          'textAlign': 'unknown_align',
          'theme': 'unknown_theme',
        };

        final settings = ReadingSettings.fromJson(json);

        expect(settings.textAlign, TextAlign.left); // default
        expect(settings.theme, ReadingTheme.light); // default
      });

      test('roundtrip serialization', () {
        const original = ReadingSettings(
          fontSize: 16.0,
          lineHeight: 2.2,
          letterSpacing: 1.0,
          textAlign: TextAlign.right,
          theme: ReadingTheme.dark,
          fontFamily: 'Monospace',
          nightLightEnabled: true,
          nightLightIntensity: 0.8,
        );

        final json = original.toJson();
        final restored = ReadingSettings.fromJson(json);

        expect(restored, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        const original = ReadingSettings();

        final copied = original.copyWith(
          fontSize: 24.0,
          theme: ReadingTheme.dark,
        );

        expect(copied.fontSize, 24.0); // changed
        expect(copied.lineHeight, 1.6); // unchanged
        expect(copied.theme, ReadingTheme.dark); // changed
      });

      test('copies with all new values', () {
        const original = ReadingSettings();

        final copied = original.copyWith(
          fontSize: 14.0,
          lineHeight: 1.4,
          letterSpacing: 0.1,
          textAlign: TextAlign.right,
          theme: ReadingTheme.sepia,
          fontFamily: 'Times',
          nightLightEnabled: true,
          nightLightIntensity: 0.9,
        );

        expect(copied.fontSize, 14.0);
        expect(copied.lineHeight, 1.4);
        expect(copied.letterSpacing, 0.1);
        expect(copied.textAlign, TextAlign.right);
        expect(copied.theme, ReadingTheme.sepia);
        expect(copied.fontFamily, 'Times');
        expect(copied.nightLightEnabled, true);
        expect(copied.nightLightIntensity, 0.9);
      });
    });

    group('getTextStyle', () {
      testWidgets('returns correct text style', (tester) async {
        const settings = ReadingSettings(
          fontSize: 20.0,
          lineHeight: 1.8,
          letterSpacing: 0.5,
          theme: ReadingTheme.dark,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final style = settings.getTextStyle(context);

                expect(style.fontSize, 20.0);
                expect(style.height, 1.8);
                expect(style.letterSpacing, 0.5);
                expect(style.color, ReadingTheme.dark.textColor);

                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('uses null fontFamily for Default', (tester) async {
        const settings = ReadingSettings(fontFamily: 'Default');

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final style = settings.getTextStyle(context);
                expect(style.fontFamily, isNull);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('uses custom fontFamily', (tester) async {
        const settings = ReadingSettings(fontFamily: 'Roboto');

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final style = settings.getTextStyle(context);
                expect(style.fontFamily, 'Roboto');
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('equality', () {
      test('equals with same values', () {
        const settings1 = ReadingSettings(fontSize: 20.0);
        const settings2 = ReadingSettings(fontSize: 20.0);

        expect(settings1, equals(settings2));
        expect(settings1.hashCode, equals(settings2.hashCode));
      });

      test('not equals with different values', () {
        const settings1 = ReadingSettings(fontSize: 18.0);
        const settings2 = ReadingSettings(fontSize: 20.0);

        expect(settings1, isNot(equals(settings2)));
      });
    });
  });

  group('ReadingTheme', () {
    test('all themes have background color', () {
      for (final theme in ReadingTheme.values) {
        expect(theme.backgroundColor, isA<Color>());
      }
    });

    test('all themes have text color', () {
      for (final theme in ReadingTheme.values) {
        expect(theme.textColor, isA<Color>());
      }
    });

    test('all themes have accent color', () {
      for (final theme in ReadingTheme.values) {
        expect(theme.accentColor, isA<Color>());
      }
    });

    test('light theme colors', () {
      expect(ReadingTheme.light.backgroundColor, Colors.white);
      expect(ReadingTheme.light.textColor, Colors.black87);
      expect(ReadingTheme.light.accentColor, Colors.blue);
    });

    test('sepia theme colors', () {
      expect(ReadingTheme.sepia.backgroundColor, const Color(0xFFF5E6D3));
      expect(ReadingTheme.sepia.textColor, const Color(0xFF5D4037));
      expect(ReadingTheme.sepia.accentColor, const Color(0xFF8D6E63));
    });

    test('dark theme colors', () {
      expect(ReadingTheme.dark.backgroundColor, const Color(0xFF1A1A1A));
      expect(ReadingTheme.dark.textColor, const Color(0xFFE0E0E0));
      expect(ReadingTheme.dark.accentColor, Colors.tealAccent);
    });
  });
}
