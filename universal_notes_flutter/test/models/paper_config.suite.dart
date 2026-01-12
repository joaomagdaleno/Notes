@Tags(['unit'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/paper_config.dart';

void main() {
  group('PaperFormat', () {
    test('size should return correct dimensions for A4', () {
      const cm = 72 / 2.54;
      expect(PaperFormat.a4.size, const Size(21.0 * cm, 29.7 * cm));
    });

    test('size should return correct dimensions for Letter', () {
      const inch = 72.0;
      expect(PaperFormat.letter.size, const Size(8.5 * inch, 11.0 * inch));
    });

    test('label should be uppercase of name', () {
      expect(PaperFormat.a4.label, 'A4');
      expect(PaperFormat.letter.label, 'LETTER');
      expect(PaperFormat.legal.label, 'LEGAL');
    });
  });

  group('PaperMargin', () {
    test('value should return correct EdgeInsets for Normal', () {
      const cm = 72 / 2.54;
      expect(PaperMargin.normal.value, const EdgeInsets.all(2.54 * cm));
    });

    test('value should return correct EdgeInsets for Narrow', () {
      const cm = 72 / 2.54;
      expect(PaperMargin.narrow.value, const EdgeInsets.all(1.27 * cm));
    });

    test('label should be capitalized', () {
      expect(PaperMargin.normal.label, 'Normal');
      expect(PaperMargin.narrow.label, 'Narrow');
      expect(PaperMargin.moderate.label, 'Moderate');
      expect(PaperMargin.wide.label, 'Wide');
    });
  });
}
