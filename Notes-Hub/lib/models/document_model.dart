import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/models/stroke.dart';

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
  TextSpan toTextSpan({ValueChanged<String>? onLinkTap}) {
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
      recognizer: (linkUrl != null && onLinkTap != null)
          ? (TapGestureRecognizer()..onTap = () => onLinkTap(linkUrl!))
          : null,
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
  /// The attributes associated with this block (e.g., indent, alignment).
  Map<String, dynamic> get attributes;

  /// Layout metadata (for Brainstorm mode, like x, y, size).
  Map<String, dynamic> get layoutMetadata;
}

/// A block of text content, composed of multiple styled spans.
class TextBlock extends DocumentBlock {
  /// Creates a text block.
  TextBlock({
    required this.spans,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The list of styled text spans.
  final List<TextSpanModel> spans;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;

  /// Converts the text block to plain text.
  String toPlainText() {
    return spans.map((s) => s.text).join();
  }
}

/// A block representing an image.
class ImageBlock extends DocumentBlock {
  /// Creates an image block.
  ImageBlock({
    required this.imagePath,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The local file path to the image.
  final String imagePath;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;
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
        final layoutMetadata =
            bMap['layoutMetadata'] as Map<String, dynamic>? ?? {};

        if (type == 'image') {
          return ImageBlock(
            imagePath: bMap['imagePath'] as String,
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
        } else if (type == 'drawing') {
          return DrawingBlock(
            strokes: (bMap['strokes'] as List<dynamic>?)
                    ?.map((s) => Stroke.fromJson(s as Map<String, dynamic>))
                    .toList() ??
                [],
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
        } else if (type == 'callout') {
          final calloutTypeStr = bMap['calloutType'] as String? ?? 'note';
          final calloutType = CalloutType.values.firstWhere(
            (e) => e.name == calloutTypeStr,
            orElse: () => CalloutType.note,
          );
          final spans = (bMap['spans'] as List<dynamic>?)
                  ?.map(
                    (s) => TextSpanModel.fromJson(s as Map<String, dynamic>),
                  )
                  .toList() ??
              [];
          return CalloutBlock(
            type: calloutType,
            spans: spans,
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
        } else if (type == 'table') {
          return TableBlock(
            rows: (bMap['rows'] as List<dynamic>?)
                    ?.map(
                      (r) => (r as List<dynamic>)
                          .map(
                            (c) => TableCellModel.fromJson(
                              c as Map<String, dynamic>,
                            ),
                          )
                          .toList(),
                    )
                    .toList() ??
                [],
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
        } else if (type == 'math') {
          return MathBlock(
            tex: bMap['tex'] as String? ?? '',
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
        } else if (type == 'transclusion') {
          return TransclusionBlock(
            noteTitle: bMap['noteTitle'] as String? ?? '',
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
        } else {
          // Default to text block for unknown or 'text' type
          final spans = (bMap['spans'] as List<dynamic>?)
                  ?.map(
                    (s) => TextSpanModel.fromJson(s as Map<String, dynamic>),
                  )
                  .toList() ??
              [];
          return TextBlock(
            spans: spans,
            attributes: attributes,
            layoutMetadata: layoutMetadata,
          );
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
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (block is TextBlock) {
        for (final span in block.spans) {
          buffer.write(span.text);
        }
      } else if (block is ImageBlock ||
          block is DrawingBlock ||
          block is MathBlock ||
          block is TransclusionBlock) {
        buffer.write(' '); // Placeholder character for non-text blocks
      } else if (block is CalloutBlock) {
        buffer.write(block.toPlainText());
      } else if (block is TableBlock) {
        // Simple representation
        buffer.write('[Table]');
      }

      if (i < blocks.length - 1) {
        buffer.write('\n');
      }
    }
    return buffer.toString();
  }

  /// Converts the document to JSON.
  Map<String, dynamic> toJson() {
    return {
      'blocks': blocks.map((b) {
        final Map<String, dynamic> data;
        if (b is ImageBlock) {
          data = {
            'type': 'image',
            'imagePath': b.imagePath,
          };
        } else if (b is DrawingBlock) {
          data = {
            'type': 'drawing',
            'strokes': b.strokes.map((s) => s.toJson()).toList(),
            'height': b.height,
          };
        } else if (b is CalloutBlock) {
          data = {
            'type': 'callout',
            'calloutType': b.type.name,
            'spans': b.spans.map((s) => s.toJson()).toList(),
          };
        } else if (b is TableBlock) {
          data = {
            'type': 'table',
            'rows': b.rows
                .map((row) => row.map((cell) => cell.toJson()).toList())
                .toList(),
          };
        } else if (b is MathBlock) {
          data = {
            'type': 'math',
            'tex': b.tex,
          };
        } else if (b is TransclusionBlock) {
          data = {
            'type': 'transclusion',
            'noteTitle': b.noteTitle,
          };
        } else if (b is TextBlock) {
          data = {
            'type': 'text',
            'spans': b.spans.map((s) => s.toJson()).toList(),
          };
        } else {
          data = <String, dynamic>{};
        }

        if (data.isNotEmpty) {
          data['attributes'] = b.attributes;
          data['layoutMetadata'] = b.layoutMetadata;
        }
        return data;
      }).toList(),
    };
  }
}

/// The type of callout/admonition.
enum CalloutType {
  /// A general note.
  note,

  /// A helpful tip.
  tip,

  /// A warning message.
  warning,

  /// A dangerous situation or error.
  danger,

  /// Informational message.
  info,

  /// Success message.
  success,
}

/// A block representing a callout (admonition).
class CalloutBlock extends DocumentBlock {
  /// Creates a callout block.
  CalloutBlock({
    required this.type,
    required this.spans,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The type of callout.
  final CalloutType type;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;

  /// The content of the callout.
  final List<TextSpanModel> spans;

  /// Converts the callout block to plain text.
  String toPlainText() {
    return spans.map((s) => s.text).join();
  }
}

/// A model representing a cell in a table.
class TableCellModel {
  /// Creates a table cell.
  const TableCellModel({
    required this.content,
    this.isHeader = false,
    this.attributes = const {},
  });

  /// Creates from JSON.
  factory TableCellModel.fromJson(Map<String, dynamic> json) {
    return TableCellModel(
      content: (json['content'] as List?)
              ?.map((e) => TextSpanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isHeader: json['isHeader'] as bool? ?? false,
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  /// The content of the cell.
  final List<TextSpanModel> content;

  /// Whether this cell is a header.
  final bool isHeader;

  /// Attributes like alignment.
  final Map<String, dynamic> attributes;

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'content': content.map((s) => s.toJson()).toList(),
        'isHeader': isHeader,
        'attributes': attributes,
      };
}

/// A block representing a table.
class TableBlock extends DocumentBlock {
  /// Creates a table block.
  TableBlock({
    required this.rows,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The rows of the table, each containing a list of cells.
  final List<List<TableCellModel>> rows;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;
}

/// A block representing a drawing.
class DrawingBlock extends DocumentBlock {
  /// Creates a drawing block.
  DrawingBlock({
    required this.strokes,
    this.height = 200.0,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The list of strokes in this drawing.
  final List<Stroke> strokes;

  /// The height of the drawing canvas area.
  final double height;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;
}

/// A block representing a math equation.
class MathBlock extends DocumentBlock {
  /// Creates a math block.
  MathBlock({
    required this.tex,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The LaTeX content.
  final String tex;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;
}

/// A block representing a transclusion (embedding another note).
class TransclusionBlock extends DocumentBlock {
  /// Creates a transclusion block.
  TransclusionBlock({
    required this.noteTitle,
    this.attributes = const {},
    this.layoutMetadata = const {},
  });

  /// The title of the note to transclude.
  final String noteTitle;

  @override
  final Map<String, dynamic> attributes;

  @override
  final Map<String, dynamic> layoutMetadata;
}
