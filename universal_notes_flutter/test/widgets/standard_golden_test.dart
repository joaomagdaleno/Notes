@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Standard Flutter Golden Test', () {
    goldenTest(
      'renders a container correctly',
      fileName: 'blue_box',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'blue box',
            child: Container(
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  });
}
