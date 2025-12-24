@Tags(['widget'])
library;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => await setupTestEnvironment());
  setUp(() async => await setupTest());
  tearDown(() async => await SyncService.instance.reset());

  group('NotesScreen Platform Logic', () {
    testWidgets('shows navigation view on Windows host', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await pumpNotesScreen(tester);
        expect(find.byType(fluent.NavigationView), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('renders correctly on Android platform', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await pumpNotesScreen(tester);
        expect(find.byType(fluent.NavigationView), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
