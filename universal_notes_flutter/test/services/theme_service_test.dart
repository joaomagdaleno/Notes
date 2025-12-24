@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial theme mode should be system', () async {
      final themeService = ThemeService();
      // Wait for _loadThemeMode to complete (it's unawaited in constructor)
      await Future<void>.delayed(Duration.zero);
      expect(themeService.themeMode, ThemeMode.system);
    });

    test('setThemeMode changes theme and saves to preferences', () async {
      final themeService = ThemeService();
      await themeService.setThemeMode(ThemeMode.dark);
      expect(themeService.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('toggleTheme switches between light and dark', () async {
      final themeService = ThemeService();
      await themeService.setThemeMode(ThemeMode.light);

      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.dark);

      await themeService.toggleTheme();
      expect(themeService.themeMode, ThemeMode.light);
    });

    test('loads saved theme from preferences', () async {
      SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
      final themeService = ThemeService();
      // Need to wait for the async load in constructor
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(themeService.themeMode, ThemeMode.light);
    });
  });
}
