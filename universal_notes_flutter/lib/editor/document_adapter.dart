import 'dart:convert';
import 'package:universal_notes_flutter/editor/document.dart';

/// A class to adapt a [DocumentModel] to and from a JSON string.
class DocumentAdapter {
  /// Converts a JSON string into a [DocumentModel].
  static DocumentModel fromJson(String jsonString) {
    if (jsonString.isEmpty) {
      return DocumentModel(
        blocks: [
          TextBlock(spans: const [TextSpanModel(text: '')]),
        ],
      );
    }
    try {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      final blocks = jsonList.map((jsonItem) {
        final itemMap = jsonItem as Map<String, dynamic>;
        final type = itemMap['type'];
        if (type == 'image') {
          return ImageBlock(imagePath: itemMap['imagePath'] as String);
        } else {
          final spans = (itemMap['spans'] as List<dynamic>)
              .map((s) => TextSpanModel.fromJson(s as Map<String, dynamic>))
              .toList();
          return TextBlock(spans: spans);
        }
      }).toList();
      return DocumentModel(blocks: blocks);
    } on Exception catch (_) {
      // Fallback for old plain text content or malformed JSON
      return DocumentModel(
        blocks: [
          TextBlock(spans: [TextSpanModel(text: jsonString)]),
        ],
      );
    }
  }

  /// Converts a [DocumentModel] into a JSON string.
  static String toJson(DocumentModel document) {
    final jsonList = document.blocks.map((block) {
      if (block is ImageBlock) {
        return {'type': 'image', 'imagePath': block.imagePath};
      } else if (block is TextBlock) {
        return {
          'type': 'text',
          'spans': block.spans.map((s) => s.toJson()).toList(),
        };
      }
      return <String, dynamic>{};
    }).toList();
    return json.encode(jsonList);
  }
}
