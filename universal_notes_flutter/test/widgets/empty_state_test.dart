import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/widgets/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('should display the provided message', (
      WidgetTester tester,
    ) async {
      const message = 'No items found';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(message: message),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
    });

    testWidgets('should display the provided icon', (
      WidgetTester tester,
    ) async {
      const icon = Icons.search;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(message: 'Test', icon: icon),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
    });

    testWidgets('should default to inbox icon if none provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(message: 'Test'),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });
  });
}
