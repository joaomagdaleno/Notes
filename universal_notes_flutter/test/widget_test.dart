// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // In the test environment, this will build the standard MyApp widget.
    await tester.pumpWidget(const MyApp());

    // Verify that the main NotesScreen is rendered.
    // This acts as a simple smoke test to ensure the app starts up.
    expect(find.byType(NotesScreen), findsOneWidget);
  });
}
