import 'package:flutter/material.dart';

/// Calculates and caches the layout metrics of text lines.
class TextLayoutEngine {
  final TextPainter _painter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  final Map<String, double> _measurementCache = {};

  /// Measures the height of a single line of text given a specific style and width constraint.
  double measureLineHeight(String line, TextStyle style, double maxWidth) {
    final cacheKey = '${line.hashCode}_${style.hashCode}_$maxWidth';

    if (_measurementCache.containsKey(cacheKey)) {
      return _measurementCache[cacheKey]!;
    }

    _painter.text = TextSpan(text: line.isEmpty ? ' ' : line, style: style);
    _painter.layout(maxWidth: maxWidth);

    final height = _painter.height;
    _measurementCache[cacheKey] = height;

    return height;
  }
}
