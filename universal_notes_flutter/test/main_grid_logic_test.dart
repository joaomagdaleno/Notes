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

  group('NotesScreen Responsive Layout', () {
    testWidgets('calculates crossAxisCount correctly on Windows (gridMedium)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await pumpNotesScreen(tester);
      await tester.pump(const Duration(milliseconds: 200));

      // Default should be grid_medium (200.0)
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(
        grid.gridDelegate,
        isA<SliverGridDelegateWithMaxCrossAxisExtent>(),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
      expect(delegate.maxCrossAxisExtent, 200.0);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('cycles through view modes', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await pumpNotesScreen(tester);
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Large Grid button
      final largeGridBtn = find.byIcon(fluent.FluentIcons.grid_view_large);
      if (largeGridBtn.evaluate().isNotEmpty) {
        await tester.runAsync(() async {
          await tester.tap(largeGridBtn);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        final grid = tester.widget<GridView>(find.byType(GridView));
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithMaxCrossAxisExtent;
        expect(delegate.maxCrossAxisExtent, 300.0);
      }

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
