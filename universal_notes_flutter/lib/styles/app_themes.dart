import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// Defines the light and dark themes for the application.
class AppThemes {
  /// The light theme configuration.
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black,
    ),
    cardTheme: const CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  /// The dark theme configuration.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: Colors.grey[900],
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: Colors.grey[850],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  /// fluent UI light theme
  static final fluent.FluentThemeData fluentLightTheme =
      fluent.FluentThemeData.light().copyWith(
    accentColor: fluent.AccentColor.swatch(const {
      'darkest': fluent.Color(0xff004a83),
      'darker': fluent.Color(0xff005a9e),
      'dark': fluent.Color(0xff0067b0),
      'normal': fluent.Color(0xff0078d4),
      'light': fluent.Color(0xff2b88d8),
      'lighter': fluent.Color(0xffc7e0f4),
      'lightest': fluent.Color(0xffeff6fc),
    }),
    visualDensity: fluent.VisualDensity.standard,
    focusTheme: fluent.FocusThemeData(
      glowColor: const fluent.Color(0xff0078d4).withValues(alpha: 0.1),
    ),
  );

  /// fluent UI dark theme
  static final fluent.FluentThemeData fluentDarkTheme =
      fluent.FluentThemeData.dark().copyWith(
    accentColor: fluent.AccentColor.swatch(const {
      'darkest': fluent.Color(0xff004a83),
      'darker': fluent.Color(0xff005a9e),
      'dark': fluent.Color(0xff0067b0),
      'normal': fluent.Color(0xff0078d4),
      'light': fluent.Color(0xff2b88d8),
      'lighter': fluent.Color(0xffc7e0f4),
      'lightest': fluent.Color(0xffeff6fc),
    }),
    visualDensity: fluent.VisualDensity.standard,
    scaffoldBackgroundColor: const fluent.Color(0xFF202020),
    focusTheme: fluent.FocusThemeData(
      glowColor: const fluent.Color(0xff0078d4).withValues(alpha: 0.1),
    ),
  );
}
