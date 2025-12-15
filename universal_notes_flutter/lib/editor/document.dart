import 'package:flutter/material.dart';

/// Represents a single continuous piece of text with a specific style.
class TextSpanModel {
  /// Creates a text span model.
  const TextSpanModel({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  /// The text content.
  final String text;
  /// Whether the text is bold.
  final bool isBold;
  /// Whether the text is italic.
  final bool isItalic;
  /// Whether the text is underlined.
  final bool isUnderline;

  /// Converts this model to a Flutter [TextSpan] for rendering.
  TextSpan toTextSpan() {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        decoration:
            isUnderline ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }

  /// Creates a copy of this model but with the given fields replaced.
  TextSpanModel copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
  }) {
    return TextSpanModel(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
    );
  }

  /// Checks if this span has the same style attributes as another.
  bool hasSameStyle(TextSpanModel other) {
    return isBold == other.isBold &&
        isItalic == other.isItalic &&
        isUnderline == other.isUnderline;
  }
}

/// Represents the entire document as a list of styled text spans.
class DocumentModel {
  /// Creates a document model.
  const DocumentModel({required this.spans});

  /// The list of text spans.
  final List<TextSpanModel> spans;

  /// Converts the entire document to a single Flutter [TextSpan] for [RichText].
  TextSpan toTextSpan() {
    return TextSpan(
      children: spans.map((span) => span.toTextSpan()).toList(),
    );
  }

  /// Converts the document to a plain text string.
  String toPlainText() {
    return spans.map((span) => span.text).join();
  }
}
