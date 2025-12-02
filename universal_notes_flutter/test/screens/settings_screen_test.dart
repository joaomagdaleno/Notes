import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('builds Material UI on Android', (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    // --- TESTE MODIFICADO PARA ANDROID ---
    testWidgets('navigates to AboutScreen on Android',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      try {
        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.tap(find.text('Sobre'));
        await tester.pumpAndSettle();

        // MUDANÇA AQUI: Verifica se alguma exceção foi lançada
        final exception = tester.takeException();
        if (exception != null) {
          // Se houver uma exceção, o teste falha com uma mensagem mais clara
          fail('Uma exceção foi lançada durante a navegação para AboutScreen no Android: $exception');
        }

        expect(find.byType(AboutScreen), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    testWidgets('builds Fluent UI on Windows', (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(fluent.ScaffoldPage), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });

    // --- TESTE MODIFICADO PARA WINDOWS ---
    testWidgets('navigates to AboutScreen on Windows',
        (WidgetTester tester) async {
      final original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      try {
        await tester.pumpWidget(const fluent.FluentApp(home: SettingsScreen()));
        await tester.tap(find.text('Sobre'));
        await tester.pumpAndSettle();

        // MUDANÇA AQUI: Verifica se alguma exceção foi lançada
        final exception = tester.takeException();
        if (exception != null) {
          // Se houver uma exceção, o teste falha com uma mensagem mais clara
          fail('Uma exceção foi lançada durante a navegação para AboutScreen no Windows: $exception');
        }

        expect(find.byType(AboutScreen), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = original;
      }
    });
  });
}
