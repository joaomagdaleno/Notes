import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    // Verify that the "About" list tile is present.
    expect(find.text('Sobre'), findsOneWidget);
  });
}
