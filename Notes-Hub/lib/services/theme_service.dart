import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service that manages the theme mode of the application.
class ThemeService with ChangeNotifier {
  /// Creates a new [ThemeService] and loads the saved theme mode.
  ThemeService() {
    unawaited(_loadThemeMode());
  }
  static const _themeModeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeModeKey);
    _themeMode = _stringToThemeMode(themeModeString ?? 'system');
    notifyListeners();
  }

  /// Sets the theme mode.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (themeMode == _themeMode) return;
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(themeMode));
    notifyListeners();
  }

  /// Toggles between light and dark mode.
  Future<void> toggleTheme() async {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  ThemeMode _stringToThemeMode(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
