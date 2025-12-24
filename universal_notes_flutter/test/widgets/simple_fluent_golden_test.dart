@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Simple Fluent Golden Test', () {
    goldenTest(
      'renders a button correctly',
      fileName: 'simple_button',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default button',
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
        ],
      ),
    );
  });
}
