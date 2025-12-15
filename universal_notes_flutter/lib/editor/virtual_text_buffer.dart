import 'package:flutter/material.dart';

/// Represents a single line of text in the virtualized editor.
@immutable
class TextLine {
  const TextLine({required this.text, this.style = const TextStyle()});

  final String text;
  final TextStyle style;

  TextLine copyWith({String? text, TextStyle? style}) {
    return TextLine(
      text: text ?? this.text,
      style: style ?? this.style,
    );
  }
}

/// Manages the collection of text lines and their overall layout.
class VirtualTextBuffer {
  final List<TextLine> lines = [];
  final Map<int, double> _lineHeights = {};
  double _totalHeight = 0.0;

  double get totalHeight => _totalHeight;

  /// Inserts text at a specific position, handling line breaks.
  void insertText(int lineIndex, int charIndex, String text) {
    // Placeholder for complex text manipulation logic.
    // For now, let's assume simple line additions.
    lines.add(TextLine(text: text));
    // In a real implementation, we would mark layout as dirty from lineIndex.
  }

  /// Updates the height of a specific line and recalculates total height.
  void setLineHeight(int lineIndex, double height) {
    final oldHeight = _lineHeights[lineIndex] ?? 0.0;
    _lineHeights[lineIndex] = height;
    _totalHeight += (height - oldHeight);
  }

  /// Gets the y-offset of a specific line.
  double getLineOffset(int lineIndex) {
    double offset = 0.0;
    for (int i = 0; i < lineIndex; i++) {
      offset += _lineHeights[i] ?? 0.0; // Use a default/estimated height if not measured
    }
    return offset;
  }
}
