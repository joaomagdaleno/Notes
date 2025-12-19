import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Standard Flutter Golden Test', () {
    testGoldens('renders a container correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'blue box',
          Container(
            width: 100,
            height: 100,
            color: Colors.blue,
          ),
        );

      await tester.pumpWidgetBuilder(builder.build());
      await screenMatchesGolden(tester, 'blue_box');
    });
  });
}
