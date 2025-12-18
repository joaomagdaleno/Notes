import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Simple Fluent Golden Test', () {
    testGoldens('renders a button correctly', (tester) async {
      final builder = GoldenBuilder.column()
        ..addScenario(
          'default button',
          Directionality(
            textDirection: TextDirection.ltr,
            child: FluentTheme(
              data: FluentThemeData(
                brightness: Brightness.light,
                accentColor: Colors.blue,
              ),
              child: Center(
                child: Button(
                  child: const Text('Click Me'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

      await tester.pumpWidgetBuilder(builder.build());
      await screenMatchesGolden(tester, 'simple_button');
    });
  });
}
