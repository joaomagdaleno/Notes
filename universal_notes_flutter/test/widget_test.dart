// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:universal_notes_flutter/main.dart';

void main() {
  testWidgets('Initial UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial UI elements are present.
    expect(find.text('Versão atual do aplicativo:'), findsOneWidget);
    expect(find.text('...'), findsOneWidget); // Initial version text

    // Find the ElevatedButton and check its child for the correct text.
    final buttonFinder = find.byType(ElevatedButton);
    expect(buttonFinder, findsOneWidget);

    final button = tester.widget<ElevatedButton>(buttonFinder);
    final buttonChild = button.child as Text;
    expect(buttonChild.data, 'Buscar Atualizações');
  });
}
