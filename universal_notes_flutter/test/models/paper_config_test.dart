import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/models/paper_config.dart';

void main() {
  group('PaperConfig', () {
    group('PaperFormatExtension', () {
      test('a4 returns correct size and label', () {
        const cm = 72 / 2.54;
        expect(PaperFormat.a4.size, const Size(21.0 * cm, 29.7 * cm));
        expect(PaperFormat.a4.label, 'A4');
      });

      test('letter returns correct size and label', () {
        const inch = 72;
        expect(PaperFormat.letter.size, const Size(8.5 * inch, 11.0 * inch));
        expect(PaperFormat.letter.label, 'LETTER');
      });

      test('legal returns correct size and label', () {
        const inch = 72;
        expect(PaperFormat.legal.size, const Size(8.5 * inch, 14.0 * inch));
        expect(PaperFormat.legal.label, 'LEGAL');
      });
    });

    group('PaperMarginExtension', () {
      test('normal returns correct value and label', () {
        const cm = 72 / 2.54;
        expect(PaperMargin.normal.value, const EdgeInsets.all(2.54 * cm));
        expect(PaperMargin.normal.label, 'Normal');
      });

      test('narrow returns correct value and label', () {
        const cm = 72 / 2.54;
        expect(PaperMargin.narrow.value, const EdgeInsets.all(1.27 * cm));
        expect(PaperMargin.narrow.label, 'Narrow');
      });

      test('moderate returns correct value and label', () {
        const cm = 72 / 2.54;
        expect(PaperMargin.moderate.value,
            const EdgeInsets.symmetric(vertical: 2.54 * cm, horizontal: 1.91 * cm));
        expect(PaperMargin.moderate.label, 'Moderate');
      });

      test('wide returns correct value and label', () {
        const cm = 72 / 2.54;
        expect(PaperMargin.wide.value,
            const EdgeInsets.symmetric(vertical: 2.54 * cm, horizontal: 5.08 * cm));
        expect(PaperMargin.wide.label, 'Wide');
      });
    });
  });
}
