import 'package:flutter/widgets.dart';

// NOTE: The size values here are based on common screen pixel densities
// (approx 96 DPI), not the precise measurements needed for PDF printing.
// For PDF, the logic in pdf_exporter.dart uses more accurate calculations.

/// The format of the paper.
enum PaperFormat {
  /// A4 format.
  a4,
  /// Letter format.
  letter,
  /// Legal format.
  legal
}

/// Extension on [PaperFormat] to get the size and label.
extension PaperFormatExtension on PaperFormat {
  /// The size of the paper.
  Size get size {
    const cm = 72 / 2.54;
    const inch = 72;
    switch (this) {
      case PaperFormat.a4:
        return const Size(21.0 * cm, 29.7 * cm);
      case PaperFormat.letter:
        return const Size(8.5 * inch, 11.0 * inch);
      case PaperFormat.legal:
        return const Size(8.5 * inch, 14.0 * inch);
    }
  }
  /// The label of the paper format.
  String get label => name.toUpperCase();
}

/// The margin of the paper.
enum PaperMargin {
  /// Normal margin.
  normal,
  /// Narrow margin.
  narrow,
  /// Moderate margin.
  moderate,
  /// Wide margin.
  wide
}

/// Extension on [PaperMargin] to get the value and label.
extension PaperMarginExtension on PaperMargin {
  /// The value of the margin.
  EdgeInsets get value {
    const cm = 72 / 2.54;
    switch (this) {
      case PaperMargin.normal:
        return const EdgeInsets.all(2.54 * cm);
      case PaperMargin.narrow:
        return const EdgeInsets.all(1.27 * cm);
      case PaperMargin.moderate:
        return const EdgeInsets.symmetric(
            vertical: 2.54 * cm, horizontal: 1.91 * cm);
      case PaperMargin.wide:
        return const EdgeInsets.symmetric(
            vertical: 2.54 * cm, horizontal: 5.08 * cm);
    }
  }
  /// The label of the paper margin.
  String get label => name[0].toUpperCase() + name.substring(1);
}
