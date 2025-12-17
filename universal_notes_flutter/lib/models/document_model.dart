import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/stroke.dart';

/// Represents a single continuous piece of text with a specific style.
class TextSpanModel {
  /// Creates a text span model.
  const TextSpanModel({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.isCode = false,
    this.fontSize,
    this.color,
    this.backgroundColor,
    this.fontFamily,
    this.linkUrl,
  });

  /// Creates a [TextSpanModel] from a JSON map.
  factory TextSpanModel.fromJson(Map<String, dynamic> json) {
    return TextSpanModel(
      text: json['text'] as String,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      isStrikethrough: json['isStrikethrough'] as bool? ?? false,
      isCode: json['isCode'] as bool? ?? false,
      fontSize: json['fontSize'] as double?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      fontFamily: json['fontFamily'] as String?,
      linkUrl: json['linkUrl'] as String?,
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

  /// Whether the text is inline code.
  final bool isCode;

  /// The font size for the text. If null, uses the default.
  final double? fontSize;

  /// The color of the text. If null, uses the default.
  final Color? color;

  /// The background color of the text.
  final Color? backgroundColor;

  /// The font family (e.g., 'monospace').
  final String? fontFamily;

  /// The URL if this span is a link.
  final String? linkUrl;

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
        color: linkUrl != null ? Colors.blue : color,
        backgroundColor: backgroundColor,
        fontFamily: isCode ? 'monospace' : fontFamily,
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
    bool? isCode,
    double? fontSize,
    Color? color,
    Color? backgroundColor,
    String? fontFamily,
    String? linkUrl,
  }) {
    return TextSpanModel(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      isCode: isCode ?? this.isCode,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      linkUrl: linkUrl ?? this.linkUrl,
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
      'isCode': isCode,
      'fontSize': fontSize,
      'color': color?.toARGB32(),
      'backgroundColor': backgroundColor?.toARGB32(),
      'fontFamily': fontFamily,
      'linkUrl': linkUrl,
    };
  }
}

/// A base class for a block of content in a document.
abstract class DocumentBlock {
  Map<String, dynamic> get attributes;
}

/// A block of text content, composed of multiple styled spans.
class TextBlock extends DocumentBlock {
  /// Creates a text block.
  TextBlock({required this.spans, this.attributes = const {}});

  /// The list of styled text spans.
  final List<TextSpanModel> spans;

  @override
  final Map<String, dynamic> attributes;

  /// Converts the text block to plain text.
  String toPlainText() {
    return spans.map((s) => s.text).join();
  }
}

/// A block representing an image.
class ImageBlock extends DocumentBlock {
  /// Creates an image block.
  ImageBlock({required this.imagePath, this.attributes = const {}});

  /// The local file path to the image.
  final String imagePath;

  @override
  final Map<String, dynamic> attributes;
}

/// Represents the entire document as a list of content blocks.
class DocumentModel {
  /// Creates a document model.
  const DocumentModel({required this.blocks});

  /// Creates an empty document model.
  factory DocumentModel.empty() => const DocumentModel(blocks: []);

  /// Creates a document model from a plain text string.
  factory DocumentModel.fromPlainText(String text) {
    return DocumentModel(
      blocks: [
        TextBlock(spans: [TextSpanModel(text: text)]),
      ],
    );
  }

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
        final attributes = bMap['attributes'] as Map<String, dynamic>? ?? {};

        if (type == 'image') {
          return ImageBlock(
            imagePath: bMap['imagePath'] as String,
            attributes: attributes,
          );
        } else if (type == 'drawing') {
          return DrawingBlock(
            strokes:
                (bMap['strokes'] as List<dynamic>?)
                    ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
                    .toList() ??
                [],
            height: (bMap['height'] as num?)?.toDouble() ?? 200.0,
            attributes: attributes,
          );
        } else {
          final spans =
              (bMap['spans'] as List<dynamic>?)
                  ?.map(
                    (s) => TextSpanModel.fromJson(s as Map<String, dynamic>),
                  )
                  .toList() ??
              [];
          return TextBlock(spans: spans, attributes: attributes);
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
        // Implicit newline between blocks, or handled by lines?
        // Usually plain text representation assumes blocks are paragraphs.
        // We might want to add a newline if it's not the last block?
        // For now keeping matching behavior with existing logic (dense).
      }
    }
    return buffer.toString();
  }

  /// Converts the document to JSON.
  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((b) {
        if (b is ImageBlock) {
          return {
            'type': 'image',
            'imagePath': b.imagePath,
            'attributes': b.attributes,
          };
        } else if (b is DrawingBlock) {
          return {
            'type': 'drawing',
            'strokes': b.strokes.map((s) => s.toJson()).toList(),
            'height': b.height,
            'attributes': b.attributes,
          };
        } else if (b is TextBlock) {
          return {
            'type': 'text',
            'spans': b.spans.map((s) => s.toJson()).toList(),
            'attributes': b.attributes,
          };
        }
        return <String, dynamic>{};
      }).toList(),
    };
  }
}

/// A block representing a drawing.
class DrawingBlock extends DocumentBlock {

  /// Creates a drawing block.
  DrawingBlock({
    required this.strokes,
    this.height = 200.0,
    this.attributes = const {},
  });
  /// The list of strokes in this drawing.
  final List<Stroke> strokes;

  /// The height of the drawing canvas area.
  final double height;

  @override
  final Map<String, dynamic> attributes;
}
