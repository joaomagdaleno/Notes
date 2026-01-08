@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notes_hub/services/read_aloud_service.dart';
import 'package:notes_hub/widgets/read_aloud_controls.dart';

class MockReadAloudService extends Mock implements ReadAloudService {}

void main() {
  late MockReadAloudService mockService;
  late StreamController<ReadAloudState> stateController;
  late StreamController<double> speedController;

  setUp(() {
    mockService = MockReadAloudService();
    stateController = StreamController<ReadAloudState>.broadcast();
    speedController = StreamController<double>.broadcast();

    when(() => mockService.currentState).thenReturn(ReadAloudState.stopped);
    when(() => mockService.currentSpeed).thenReturn(1);
    when(
      () => mockService.stateStream,
    ).thenAnswer((_) => stateController.stream);
    when(
      () => mockService.speedStream,
    ).thenAnswer((_) => speedController.stream);
  });

  tearDown(() async {
    await stateController.close();
    await speedController.close();
  });

  Widget createWidget({bool compact = false, VoidCallback? onClose}) {
    return MaterialApp(
      home: Scaffold(
        body: ReadAloudControls(
          service: mockService,
          text: 'Test text',
          compact: compact,
          onClose: onClose,
        ),
      ),
    );
  }

  group('ReadAloudControls', () {
    testWidgets('renders correctly in full mode', (tester) async {
      await tester.pumpWidget(createWidget());
      expect(find.text('Read Aloud'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders correctly in compact mode', (tester) async {
      await tester.pumpWidget(createWidget(compact: true));
      expect(find.text('Read Aloud'), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('toggles play/pause when button pressed', (tester) async {
      when(() => mockService.speak(any())).thenAnswer((_) async {});
      when(() => mockService.pause()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      // Initial state: stopped
      await tester.tap(find.byIcon(Icons.play_arrow));
      verify(() => mockService.speak('Test text')).called(1);

      // Change state to playing
      when(() => mockService.currentState).thenReturn(ReadAloudState.playing);
      stateController.add(ReadAloudState.playing);
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause));
      verify(() => mockService.pause()).called(1);
    });

    testWidgets('calls stop when stop button pressed', (tester) async {
      when(() => mockService.currentState).thenReturn(ReadAloudState.playing);
      when(() => mockService.stop()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      await tester.tap(find.byIcon(Icons.stop));
      verify(() => mockService.stop()).called(1);
    });

    testWidgets('calls setSpeechRate when slider moved', (tester) async {
      when(() => mockService.setSpeechRate(any())).thenAnswer((_) async {});
      await tester.pumpWidget(createWidget());

      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pump();

      verify(() => mockService.setSpeechRate(any())).called(greaterThan(0));
    });

    testWidgets('calls onClose when close button pressed', (tester) async {
      when(() => mockService.stop()).thenAnswer((_) async {});
      var closed = false;
      await tester.pumpWidget(createWidget(onClose: () => closed = true));

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, true);
      verify(() => mockService.stop()).called(1);
    });
  });
}
