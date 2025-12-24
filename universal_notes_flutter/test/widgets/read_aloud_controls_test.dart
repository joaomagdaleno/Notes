import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/read_aloud_service.dart';
import 'package:universal_notes_flutter/widgets/read_aloud_controls.dart';

void main() {
  group('ReadAloudControls', () {
    group('compact mode', () {
      testWidgets('renders play button when stopped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
                compact: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      });

      testWidgets('renders pause button when playing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.playing,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
                compact: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.pause), findsOneWidget);
      });

      testWidgets('shows stop button when playing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.playing,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
                compact: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.stop), findsOneWidget);
      });

      testWidgets('hides stop button when stopped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
                compact: true,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.stop), findsNothing);
      });

      testWidgets('displays current speed', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.5,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
                compact: true,
              ),
            ),
          ),
        );

        expect(find.text('1.5x'), findsOneWidget);
      });
    });

    group('full mode', () {
      testWidgets('renders Read Aloud title', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Read Aloud'), findsOneWidget);
      });

      testWidgets('renders speed slider', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('calls onPlay when play pressed', (tester) async {
        var playCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () => playCalled = true,
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.play_arrow));
        expect(playCalled, true);
      });

      testWidgets('calls onPause when pause pressed', (tester) async {
        var pauseCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.playing,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () => pauseCalled = true,
                onStop: () {},
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.pause));
        expect(pauseCalled, true);
      });

      testWidgets('calls onStop when stop pressed', (tester) async {
        var stopCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.playing,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () => stopCalled = true,
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.stop));
        expect(stopCalled, true);
      });

      testWidgets('calls onSpeedChanged when slider moved', (tester) async {
        double? newSpeed;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (s) => newSpeed = s,
              ),
            ),
          ),
        );

        await tester.drag(find.byType(Slider), const Offset(50, 0));
        await tester.pump();

        expect(newSpeed, isNotNull);
      });

      testWidgets('disables stop when stopped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
              ),
            ),
          ),
        );

        final stopButtons = find.byIcon(Icons.stop);
        expect(stopButtons, findsOneWidget);

        // Stop button should be disabled (filledTonal with disabled state)
        final button = tester.widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.stop),
            matching: find.byType(IconButton),
          ),
        );
        expect(button.onPressed, isNull);
      });
    });

    group('speed popup', () {
      testWidgets('shows speed options when speed button tapped', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReadAloudControls(
                state: ReadAloudState.stopped,
                speechRate: 1.0,
                onPlay: () {},
                onPause: () {},
                onStop: () {},
                onSpeedChanged: (_) {},
                compact: true,
              ),
            ),
          ),
        );

        await tester.tap(find.text('1.0x'));
        await tester.pumpAndSettle();

        expect(find.text('0.5x'), findsOneWidget);
        expect(find.text('1.0x (Normal)'), findsOneWidget);
        expect(find.text('2.0x'), findsOneWidget);
      });
    });
  });
}
