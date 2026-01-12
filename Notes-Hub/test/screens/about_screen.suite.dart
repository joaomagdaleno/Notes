@Tags(['widget'])
library;

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:notes_hub/screens/about_screen.dart';
import 'package:notes_hub/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

// --- Mocks and Fakes ---

class MockHttpClient extends Mock implements http.Client {}

class FakePackageInfo implements PackageInfo {
  @override
  String get appName => 'Universal Notes';
  @override
  String get packageName => 'com.example.universal_notes';
  @override
  String get version => '1.0.0';
  @override
  String get buildNumber => '1';
  @override
  String get buildSignature => '';
  @override
  Map<String, dynamic> get data => {};
  @override
  DateTime? get installTime => DateTime.now();
  @override
  DateTime? get updateTime => DateTime.now();
  @override
  String? get installerStore => null;
}

/// A configurable UpdateService to control the result of [checkForUpdate].
class ConfigurableUpdateService extends UpdateService {
  ConfigurableUpdateService({
    required UpdateCheckResult result,
    Duration delay = Duration.zero,
  })  : _result = result,
        _delay = delay,
        super(client: MockHttpClient());

  final UpdateCheckResult _result;
  final Duration _delay;

  @override
  Future<UpdateCheckResult> checkForUpdate() async {
    if (_delay > Duration.zero) {
      await Future<void>.delayed(_delay);
    }
    return _result;
  }
}

void main() {
  final packageInfo = FakePackageInfo();

  group('AboutScreen - Material UI (Non-Windows)', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.android,
          ),
        ),
      );

      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
      expect(find.text('Verificar Atualizações'), findsOneWidget);
    });

    testWidgets('shows loading indicator during update check', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(UpdateCheckStatus.noUpdate),
        delay: const Duration(milliseconds: 100), // Small delay
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.android,
            updateService: service,
          ),
        ),
      );

      // Initial state
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Verificar Atualizações'), findsOneWidget);

      // Tap button
      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pump(); // Start animation

      // Should be loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Verificar Atualizações'), findsNothing);

      // Finish
      await tester.pump(const Duration(milliseconds: 100)); // Wait for future
      await tester.pump(); // Rebuild

      // Back to normal
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Verificar Atualizações'), findsOneWidget);
    });

    testWidgets('shows SnackBar when no update is available', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(UpdateCheckStatus.noUpdate),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AboutScreen(
              packageInfo: packageInfo,
              debugPlatform: TargetPlatform.android,
              updateService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Você já está na versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows SnackBar on error', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Falha na conexão',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AboutScreen(
              packageInfo: packageInfo,
              debugPlatform: TargetPlatform.android,
              updateService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Falha na conexão'), findsOneWidget);
    });

    testWidgets('shows AlertDialog when update is available', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: UpdateInfo(
            version: '2.0.0',
            downloadUrl: 'http://example.com/app.apk',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.android,
            updateService: service,
          ),
        ),
      );

      await tester.tap(find.text('Verificar Atualizações'));

      // We cannot use pumpAndSettle here because the underlying button
      // is still showing CircularProgressIndicator (checking=true) while the
      // dialog is open, creating an infinite animation that
      //causes pumpAndSettle
      // to timeout.
      await tester.pump(); // Start async work
      await tester.pump(); // Build dialog
      await tester.pump(); // Transitions

      expect(find.text('Atualização Disponível'), findsOneWidget);
      expect(
        find.textContaining('Uma nova versão (2.0.0) está disponível'),
        findsOneWidget,
      );
    });
  });

  group('AboutScreen - Fluent UI (Windows)', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.windows,
          ),
        ),
      );

      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Versão atual: 1.0.0'), findsOneWidget);
      expect(find.text('Verificar Atualizações'), findsOneWidget);
    });

    testWidgets('back button navigates back', (tester) async {
      await tester.pumpWidget(
        fluent.FluentApp(
          home: fluent.NavigationView(
            content: fluent.Navigator(
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  return fluent.FluentPageRoute<void>(
                    builder: (context) =>
                        const fluent.Center(child: fluent.Text('Home')),
                  );
                }
                return fluent.FluentPageRoute<void>(
                  builder: (context) => AboutScreen(
                    packageInfo: packageInfo,
                    debugPlatform: TargetPlatform.windows,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify Home
      expect(find.text('Home'), findsOneWidget);

      // Push AboutScreen
      final context = tester.element(find.text('Home'));
      unawaited(
        fluent.Navigator.push(
          context,
          fluent.FluentPageRoute<void>(
            builder: (context) => AboutScreen(
              packageInfo: packageInfo,
              debugPlatform: TargetPlatform.windows,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sobre'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(fluent.FluentIcons.back));
      await tester.pumpAndSettle();

      // After pop, should not show AboutScreen anymore
      expect(find.text('Sobre'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows loading indicator during update check', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(UpdateCheckStatus.noUpdate),
        delay: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.windows,
            updateService: service,
          ),
        ),
      );

      expect(find.byType(fluent.ProgressRing), findsNothing);

      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pump();

      expect(find.byType(fluent.ProgressRing), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.byType(fluent.ProgressRing), findsNothing);
    });

    testWidgets('updates status text when no update available', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(UpdateCheckStatus.noUpdate),
      );

      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.windows,
            updateService: service,
          ),
        ),
      );

      await tester.tap(find.text('Verificar Atualizações'));

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Você já está na versão mais recente.'), findsOneWidget);
    });

    testWidgets('updates status text on error', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Windows erro check',
        ),
      );

      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.windows,
            updateService: service,
          ),
        ),
      );

      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Windows erro check'), findsOneWidget);
    });

    testWidgets('updates status text when update available', (tester) async {
      final service = ConfigurableUpdateService(
        result: UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: UpdateInfo(
            version: '2.0.0',
            downloadUrl: 'http://fake.url/installer.exe',
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      await tester.pumpWidget(
        fluent.FluentApp(
          home: AboutScreen(
            packageInfo: packageInfo,
            debugPlatform: TargetPlatform.windows,
            updateService: service,
          ),
        ),
      );

      await tester.tap(find.text('Verificar Atualizações'));
      await tester.pump(); // start

      // It mimics "Verificando..." first
      expect(find.text('Verificando atualizações...'), findsOneWidget);

      // Complete the check
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Should now show "Found..."
      expect(find.text('Atualização encontrada. Baixando...'), findsOneWidget);
    });
  });
}
