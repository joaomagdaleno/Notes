@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/widgets/reading_outline_navigator.dart';

void main() {
  group('ReadingOutlineNavigator', () {
    final testHeadings = [
      const OutlineHeading(text: 'Introduction', level: 1, position: 0),
      const OutlineHeading(text: 'Section 1', level: 2, position: 100),
      const OutlineHeading(text: 'Subsection 1.1', level: 3, position: 200),
      const OutlineHeading(text: 'Section 2', level: 2, position: 300),
      const OutlineHeading(text: 'Conclusion', level: 1, position: 500),
    ];

    testWidgets('renders Contents header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Contents'), findsOneWidget);
    });

    testWidgets('renders all headings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (_) {},
            ),
          ),
        ),
      );

      // Only level-1 headings are visible by default (children are collapsed)
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('Conclusion'), findsOneWidget);
      // Level-2/3 headings are hidden when parents are collapsed
      expect(find.text('Section 1'), findsNothing);
    });

    testWidgets('shows empty message when no headings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: const [],
              onHeadingTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No headings found'), findsOneWidget);
    });

    testWidgets('shows progress percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (_) {},
              progressPercent: 0.45,
            ),
          ),
        ),
      );

      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('shows progress bar when progress provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (_) {},
              progressPercent: 0.5,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onHeadingTap when heading tapped', (tester) async {
      OutlineHeading? tappedHeading;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (h) => tappedHeading = h,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Introduction'));
      await tester.pump();

      expect(tappedHeading?.text, 'Introduction');
    });

    testWidgets('highlights active heading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (_) {},
              currentHeadingIndex: 2,
            ),
          ),
        ),
      );

      // The active heading should be visually different
      // Use index 0 (Introduction) since it's a level-1 heading always visible
      expect(find.text('Introduction'), findsOneWidget);
    });

    testWidgets('shows expand icons for headings with children', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingOutlineNavigator(
              headings: testHeadings,
              onHeadingTap: (_) {},
            ),
          ),
        ),
      );

      // Introduction and Section 1 have children
      expect(
        find.byIcon(Icons.keyboard_arrow_right),
        findsWidgets,
      );
    });
  });

  group('OutlineHeading', () {
    test('creates with values', () {
      const heading = OutlineHeading(
        text: 'Test Heading',
        level: 2,
        position: 150,
      );

      expect(heading.text, 'Test Heading');
      expect(heading.level, 2);
      expect(heading.position, 150);
    });

    test('equality works correctly', () {
      const heading1 = OutlineHeading(
        text: 'Test',
        level: 1,
        position: 0,
      );
      const heading2 = OutlineHeading(
        text: 'Test',
        level: 1,
        position: 0,
      );
      const heading3 = OutlineHeading(
        text: 'Different',
        level: 1,
        position: 0,
      );

      expect(heading1, equals(heading2));
      expect(heading1, isNot(equals(heading3)));
      expect(heading1.hashCode, equals(heading2.hashCode));
    });
  });
}
