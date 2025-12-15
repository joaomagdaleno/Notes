import 'package:flutter/material.dart';

/// Represents a single continuous piece of text with a specific style.
class TextSpanModel {

  /// Creates a [TextSpanModel] from a JSON map.
  factory TextSpanModel.fromJson(Map<String, dynamic> json) {
    return TextSpanModel(
      text: json['text'] as String,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrikethrough: json['isStrikethrough'] as bool? ?? false,
      fontSize: json['fontSize'] as double?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
    );
  }
  /// Creates a text span model.
  const TextSpanModel({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.fontSize,
    this.color,
  });

  /// The text content.
  final String text;
  /// Whether the text is bold.
  final bool isBold;
  /// Whether the text is italic.
  final bool isItalic;
  /// Whether the text is underlined.
  final bool isUnderline;
  /// Whether the text has a strikethrough.
  final bool isStrikethrough;
  /// The font size for the text. If null, uses the default.
  final double? fontSize;
  /// The color of the text. If null, uses the default.
  final Color? color;

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'isStrikethrough': isStrikethrough,
      'fontSize': fontSize,
      'color': color?.value,
    };
  }

  /// Converts this model to a Flutter [TextSpan] for rendering.
  TextSpan toTextSpan() {
    final decorations = <TextDecoration>[];
    if (isUnderline) decorations.add(TextDecoration.underline);
    if (isStrikethrough) decorations.add(TextDecoration.lineThrough);

    return TextSpan(
      text: text,
      style: TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: TextDecoration.combine(decorations),
        fontSize: fontSize,
        color: color,
      ),
    );
  }

  /// Creates a copy of this model but with the given fields replaced.
  TextSpanModel copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    double? fontSize,
    Color? color,
  }) {
    return TextSpanModel(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
    );
  }

  /// Checks if this span has the same style attributes as another.
  bool hasSameStyle(TextSpanModel other) {
    return isBold == other.isBold &&
        isItalic == other.isItalic &&
        isUnderline == other.isUnderline &&
        isStrikethrough == other.isStrikethrough &&
        fontSize == other.fontSize &&
        color == other.color;
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
