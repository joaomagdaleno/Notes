import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

import 'about_screen_test.mocks.dart';

void main() {
  group('AboutScreen Material UI Tests', () {
    testWidgets('renders Material UI components correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(),
        ),
      );

      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Universal Notes'), findsOneWidget);
      expect(find.text('Versão'), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when checking for update',
        (WidgetTester tester) async {
      // Mock do UpdateService
      final mockUpdateService = MockUpdateService();
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 1));
          return const UpdateCheckResult(UpdateCheckStatus.noUpdate);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(updateService: mockUpdateService),
        ),
      );

      final updateButton = find.byType(ElevatedButton);
      expect(updateButton, findsOneWidget);

      await tester.tap(updateButton);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(updateButton);
      expect(button.onPressed, isNull);

      await tester.pumpAndSettle();

      final buttonAfter = tester.widget<ElevatedButton>(updateButton);
      expect(buttonAfter.onPressed, isNotNull);
    });
  });

  group('AboutScreen Fluent UI (Windows) Tests', () {
    testWidgets('renders Fluent UI components correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(isWindows: true),
        ),
      );

      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Universal Notes'), findsOneWidget);
      expect(find.text('Versão'), findsOneWidget);
    });

    testWidgets('shows ProgressRing when checking for update on Windows',
        (WidgetTester tester) async {
      final mockUpdateService = MockUpdateService();
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async {
          await Future.delayed(const Duration(seconds: 1));
          return const UpdateCheckResult(UpdateCheckStatus.noUpdate);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            updateService: mockUpdateService,
            isWindows: true,
          ),
        ),
      );

      final updateButton = find.byType(FilledButton);
      expect(updateButton, findsOneWidget);

      await tester.tap(updateButton);
      await tester.pump();

      expect(find.byType(ProgressRing), findsOneWidget);

      final button = tester.widget<FilledButton>(updateButton);
      expect(button.onPressed, isNull);

      await tester.pumpAndSettle();

      final buttonAfter = tester.widget<FilledButton>(updateButton);
      expect(buttonAfter.onPressed, isNotNull);
    });
  });
}
