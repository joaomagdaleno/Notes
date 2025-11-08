import 'package:flutter/widgets.dart';

// NOTE: The size values here are based on common screen pixel densities (approx 96 DPI),
// not the precise measurements needed for PDF printing.
// For PDF, the logic in pdf_exporter.dart uses more accurate calculations.

enum PaperFormat { a4, letter, legal }

extension PaperFormatExtension on PaperFormat {
  Size get size {
    const double cm = 72 / 2.54;
    const double inch = 72;
    switch (this) {
      case PaperFormat.a4:
        return const Size(21.0 * cm, 29.7 * cm);
      case PaperFormat.letter:
        return const Size(8.5 * inch, 11.0 * inch);
      case PaperFormat.legal:
        return const Size(8.5 * inch, 14.0 * inch);
    }
  }
  String get label => name.toUpperCase();
}

enum PaperMargin { normal, narrow, moderate, wide }

extension PaperMarginExtension on PaperMargin {
  EdgeInsets get value {
    const double cm = 72 / 2.54;
    switch (this) {
      case PaperMargin.normal:
        return const EdgeInsets.all(2.54 * cm);
      case PaperMargin.narrow:
        return const EdgeInsets.all(1.27 * cm);
      case PaperMargin.moderate:
        return EdgeInsets.symmetric(
            vertical: 2.54 * cm, horizontal: 1.91 * cm);
      case PaperMargin.wide:
        return EdgeInsets.symmetric(
            vertical: 2.54 * cm, horizontal: 5.08 * cm);
    }
  }
  String get label => name[0].toUpperCase() + name.substring(1);
}
