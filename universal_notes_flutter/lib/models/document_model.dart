import 'package:flutter/material.dart';

/// Represents a single continuous piece of text with a specific style.
class TextSpanModel {
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

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      'isStrikethrough': isStrikethrough,
      'fontSize': fontSize,
      'color': color?.toARGB32(),
    };
  }
}

/// A base class for a block of content in a document.
abstract class DocumentBlock {}

/// A block of text content, composed of multiple styled spans.
class TextBlock extends DocumentBlock {
  /// Creates a text block.
  TextBlock({required this.spans});

  /// The list of styled text spans.
  final List<TextSpanModel> spans;
}

/// A block representing an image.
class ImageBlock extends DocumentBlock {
  /// Creates an image block.
  ImageBlock({required this.imagePath});

  /// The local file path to the image.
  final String imagePath;
}

/// Represents the entire document as a list of content blocks.
class DocumentModel {
  /// Creates a document model.
  const DocumentModel({required this.blocks});

  /// Creates an empty document model.
  factory DocumentModel.empty() => const DocumentModel(blocks: []);

  /// Creates a document model from JSON.
  factory DocumentModel.fromJson(dynamic json) {
    if (json is List) {
      // Legacy or list format
      return const DocumentModel(blocks: []);
    }
    if (json is Map<String, dynamic>) {
      // Parse blocks
      final blocksJson = json['blocks'] as List<dynamic>? ?? [];
      final blocks = blocksJson.map((b) {
        final bMap = b as Map<String, dynamic>;
        final type = bMap['type'];
        if (type == 'image') {
          return ImageBlock(imagePath: bMap['imagePath'] as String);
        } else {
          final spans =
              (bMap['spans'] as List<dynamic>?)
                  ?.map(
                    (s) => TextSpanModel.fromJson(s as Map<String, dynamic>),
                  )
                  .toList() ??
              [];
          return TextBlock(spans: spans);
        }
      }).toList();
      return DocumentModel(blocks: blocks);
    }
    return const DocumentModel(blocks: []);
  }

  /// The list of content blocks.
  final List<DocumentBlock> blocks;

  /// Converts the document to a text span.
  TextSpan toTextSpan() {
    final children = <TextSpan>[];
    for (final block in blocks) {
      if (block is TextBlock) {
        children.addAll(block.spans.map((span) => span.toTextSpan()));
      }
    }
    return TextSpan(children: children);
  }

  /// Converts the document to a plain text string.
  String toPlainText() {
    final buffer = StringBuffer();
    for (final block in blocks) {
      if (block is TextBlock) {
        for (final span in block.spans) {
          buffer.write(span.text);
        }
      }
    }
    return buffer.toString();
  }

  /// Converts the document to JSON.
  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((b) {
        if (b is ImageBlock) {
          return {'type': 'image', 'imagePath': b.imagePath};
        } else if (b is TextBlock) {
          return {
            'type': 'text',
            'spans': b.spans.map((s) => s.toJson()).toList(),
          };
        }
        return <String, dynamic>{};
      }).toList(),
    };
  }
}
