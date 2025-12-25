@Tags(['widget'])
library;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => setupTestEnvironment());
  setUp(() async => setupTest());
  tearDown(() async => tearDownTest());

  group('NotesScreen Platform Logic', () {
    testWidgets('shows navigation view on Windows host', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await pumpNotesScreen(tester);
      expect(find.byType(fluent.NavigationView), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('renders correctly on Android platform', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await pumpNotesScreen(tester);
      expect(find.byType(Scaffold), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
