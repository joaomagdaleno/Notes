// test/utils/update_helper_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';

import 'update_helper_test.mocks.dart';

@GenerateMocks([UpdateService, http.Client])
void main() {
  group('UpdateHelper', () {
    late MockUpdateService mockUpdateService;
    final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

    setUp(() {
      mockUpdateService = MockUpdateService();
    });

    Widget createTestWidget({required VoidCallback onPressed}) {
      return MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: onPressed,
              child: const Text('Check for updates'),
            ),
          ),
        ),
      );
    }

    testWidgets('shows update dialog when update is available',
        (WidgetTester tester) async {
      final updateInfo = UpdateInfo(
        version: '1.0.1',
        downloadUrl: 'https://example.com/app.apk',
      );

      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.updateAvailable,
          updateInfo: updateInfo,
        ),
      );

      await tester.pumpWidget(createTestWidget(
        onPressed: () => UpdateHelper.checkForUpdate(
          tester.element(find.byType(ElevatedButton)),
          updateService: mockUpdateService,
          scaffoldMessengerKey: scaffoldMessengerKey,
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Atualização Disponível'), findsOneWidget);
      expect(
        find.text(
          'Uma nova versão (1.0.1) está disponível. Deseja baixar e instalar?',
        ),
        findsOneWidget,
      );
      expect(find.text('Agora não'), findsOneWidget);
      expect(find.text('Sim, atualizar'), findsOneWidget);
    });

    testWidgets('shows no update message when no update is available',
        (WidgetTester tester) async {
      // FIX: Removed 'const' keyword
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(UpdateCheckStatus.noUpdate),
      );

      await tester.pumpWidget(createTestWidget(
        onPressed: () => UpdateHelper.checkForUpdate(
          tester.element(find.byType(ElevatedButton)),
          isManual: true,
          updateService: mockUpdateService,
          scaffoldMessengerKey: scaffoldMessengerKey,
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Você já tem a versão mais recente.'), findsOneWidget);
    });

    testWidgets('shows error message when update check fails',
        (WidgetTester tester) async {
      // FIX: Removed 'const' keyword
      when(mockUpdateService.checkForUpdate()).thenAnswer(
        (_) async => UpdateCheckResult(
          UpdateCheckStatus.error,
          errorMessage: 'Network error',
        ),
      );

      await tester.pumpWidget(createTestWidget(
        onPressed: () => UpdateHelper.checkForUpdate(
          tester.element(find.byType(ElevatedButton)),
          isManual: true,
          updateService: mockUpdateService,
          scaffoldMessengerKey: scaffoldMessengerKey,
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Network error'), findsOneWidget);
    });

    group('Update Installation Flow', () {
      setUp(() {
        mockUpdateService = MockUpdateService();
      });

      testWidgets('shows permission denied message on Android',
          (WidgetTester tester) async {
        final updateInfo = UpdateInfo(
          version: '1.0.2',
          downloadUrl: 'https://example.com/app.apk',
        );
        when(mockUpdateService.checkForUpdate()).thenAnswer(
          (_) async => UpdateCheckResult(
            UpdateCheckStatus.updateAvailable,
            updateInfo: updateInfo,
          ),
        );

        const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'requestPermission') {
            return {Permission.requestInstallPackages.value: 0};
          }
          return {Permission.requestInstallPackages.value: 0};
        });

        try {
          await tester.pumpWidget(createTestWidget(
            onPressed: () => UpdateHelper.checkForUpdate(
              tester.element(find.byType(ElevatedButton)),
              updateService: mockUpdateService,
              isAndroidOverride: true,
              scaffoldMessengerKey: scaffoldMessengerKey,
            ),
          ));

          await tester.tap(find.byType(ElevatedButton));
          await tester.pumpAndSettle();
          expect(find.text('Atualização Disponível'), findsOneWidget);

          await tester.tap(find.text('Sim, atualizar'));
          await tester.pumpAndSettle();

          expect(
            find.text(
              'Permissão para instalar pacotes é necessária para a '
              'atualização.',
            ),
            findsOneWidget,
          );
        } finally {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
        }
      });

testWidgets('shows error message when download fails',
    (WidgetTester tester) async {
  final mockHttpClient = MockClient();

  // Mock any HTTP GET call to simulate a network failure.
  when(mockHttpClient.get(any))
      .thenThrow(Exception('Simulated network failure'));

  final updateInfo = UpdateInfo(
    version: '1.0.3',
    downloadUrl: 'https://any-url.com/app.apk',
  );
  when(mockUpdateService.checkForUpdate()).thenAnswer(
    (_) async => UpdateCheckResult(
      UpdateCheckStatus.updateAvailable,
      updateInfo: updateInfo,
    ),
  );

  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    if (methodCall.method == 'requestPermission') {
      return {Permission.requestInstallPackages.value: 1}; // Permission granted
    }
    return {Permission.requestInstallPackages.value: 1};
  });

  try {
    await tester.pumpWidget(createTestWidget(
      onPressed: () => UpdateHelper.checkForUpdate(
        tester.element(find.byType(ElevatedButton)),
        updateService: mockUpdateService,
        isAndroidOverride: true,
        httpClient: mockHttpClient,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    ));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(find.text('Atualização Disponível'), findsOneWidget);

    await tester.tap(find.text('Sim, atualizar'));
    await tester.pump(); // Show the download SnackBar.

    expect(find.text('Baixando atualização... Por favor, aguarde.'), findsOneWidget);

    // FIX: Force multiple render cycles to ensure the error is processed.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    // FIX: Check if the error SnackBar is visible.
    expect(find.byType(SnackBar), findsOneWidget);

    // FIX: Check the text within the SnackBar.
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final content = snackBar.content as Text;
    expect(content.data, contains('Erro na atualização:'));
  } finally {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
});
    });
  });
}
