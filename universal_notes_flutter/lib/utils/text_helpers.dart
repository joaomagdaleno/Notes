import 'dart:convert';

/// Returns a plain text preview from a JSON string.
String getPreviewText(String jsonContent) {
  try {
    final delta = jsonDecode(jsonContent) as List;
    final text = delta
        .where((dynamic op) => op is Map && op.containsKey('insert'))
        .map((dynamic op) => (op as Map)['insert'].toString())
        .join();
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  } on Exception {
    return '...';
  }
}
