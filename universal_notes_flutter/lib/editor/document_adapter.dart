import 'dart:convert';
import 'package:universal_notes_flutter/editor/document.dart';

/// A class to adapt a [DocumentModel] to and from a JSON string.
class DocumentAdapter {
  /// Converts a JSON string into a [DocumentModel].
  ///
  /// If the string is empty or invalid, returns a document with a single empty
  /// span.
  static DocumentModel fromJson(String jsonString) {
    if (jsonString.isEmpty) {
      return const DocumentModel(spans: [TextSpanModel(text: '')]);
    }
    try {
      final jsonList = json.decode(jsonString) as List<dynamic>;
      final spans = jsonList.map(
        (jsonItem) {
          final itemMap = jsonItem as Map<String, dynamic>;
          return TextSpanModel.fromJson(itemMap);
        },
      ).toList();
      return DocumentModel(spans: spans);
    } on FormatException catch (_) {
      // If parsing fails, return a document containing the original string as
      // plain text.
      return DocumentModel(spans: [TextSpanModel(text: jsonString)]);
    }
  }

  /// Converts a [DocumentModel] into a JSON string.
  static String toJson(DocumentModel document) {
    final jsonList = document.spans.map((span) => span.toJson()).toList();
    return json.encode(jsonList);
  }
}
