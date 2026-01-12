import 'dart:convert';

/// Extracts preview text from JSON-formatted note content.
///
/// The content is expected to be a JSON array of text spans.
/// Returns the plain text representation of the content.
String getPreviewText(String content) {
  if (content.isEmpty) return '';

  try {
    final dynamic decoded = json.decode(content);
    if (decoded is List) {
      final buffer = StringBuffer();
      for (final span in decoded) {
        if (span is Map<String, dynamic> && span['text'] is String) {
          buffer.write(span['text'] as String);
        }
      }
      return buffer.toString();
    }
    return content;
  } on FormatException catch (_) {
    // If it's not valid JSON, return the content as-is
    return content;
  }
}
