import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'universal_notes',
      packageName: 'com.example.universal_notes',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: '',
    );
  });

  testWidgets('AboutScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));

    // Verify that the screen shows the version number.
    expect(find.text('Versão atual: 1.0.0'), findsOneWidget);

    // Verify that the "Check for Updates" button is present.
    expect(find.text('Verificar Atualizações'), findsOneWidget);
  });
}
