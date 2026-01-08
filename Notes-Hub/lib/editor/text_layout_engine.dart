import 'dart:collection';
import 'package:flutter/material.dart';

/// Calculates and caches the layout metrics of text lines.
class TextLayoutEngine {
  final TextPainter _painter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  final LinkedHashMap<String, double> _measurementCache = LinkedHashMap();
  static const int _maxCacheSize = 1000;

  /// Measures the height of a single line of text given a specific style and
  /// width constraint.
  double measureLineHeight(String line, TextStyle style, double maxWidth) {
    final cacheKey = '${line.hashCode}_${style.hashCode}_$maxWidth';

    if (_measurementCache.containsKey(cacheKey)) {
      // Move to end (most recently used)
      final value = _measurementCache.remove(cacheKey)!;
      _measurementCache[cacheKey] = value;
      return value;
    }

    _painter.text = TextSpan(text: line.isEmpty ? ' ' : line, style: style);
    _painter.layout(maxWidth: maxWidth);

    final height = _painter.height;

    if (_measurementCache.length >= _maxCacheSize) {
      _measurementCache.remove(_measurementCache.keys.first);
    }
    _measurementCache[cacheKey] = height;

    return height;
  }

  /// Clears the measurement cache.
  void clearCache() {
    _measurementCache.clear();
  }

  /// Measures the size of the given text with the specified style.
  Size measureText(
    String text,
    TextStyle style, {
    double maxWidth = double.infinity,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
    return (textPainter..layout(maxWidth: maxWidth)).size;
  }
}
