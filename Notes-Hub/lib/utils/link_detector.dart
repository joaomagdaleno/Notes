import 'package:notes_hub/models/document_model.dart';

/// A utility for detecting and processing URLs in text.
class LinkDetector {
  LinkDetector._();

  /// Regular expression to match HTTP/HTTPS URLs.
  static final RegExp urlRegex = RegExp(
    r'https?://[^\s<>\[\]{}|\\^`"]+',
    caseSensitive: false,
  );

  /// Regular expression to match email addresses.
  static final RegExp emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    caseSensitive: false,
  );

  /// Detects URLs in the given text and returns a list of spans with
  /// linkUrl filled for detected URLs.
  ///
  /// This splits the text into segments where URLs are marked with the
  /// `linkUrl` property set.
  static List<TextSpanModel> processText(String text) {
    if (text.isEmpty) return [];

    final spans = <TextSpanModel>[];
    var lastEnd = 0;

    // Find all URL matches
    final matches = urlRegex.allMatches(text).toList();

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastEnd) {
        spans.add(TextSpanModel(text: text.substring(lastEnd, match.start)));
      }

      // Add the URL with linkUrl set
      final url = match.group(0)!;
      spans.add(
        TextSpanModel(
          text: url,
          linkUrl: url,
          isUnderline: true,
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastEnd < text.length) {
      spans.add(TextSpanModel(text: text.substring(lastEnd)));
    }

    // If no URLs were found, return the original text as a single span
    if (spans.isEmpty) {
      return [TextSpanModel(text: text)];
    }

    return spans;
  }

  /// Checks if the given text contains a URL.
  static bool containsUrl(String text) {
    return urlRegex.hasMatch(text);
  }

  /// Extracts all URLs from the given text.
  static List<String> extractUrls(String text) {
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  /// Checks if the given string is a valid URL.
  static bool isValidUrl(String text) {
    try {
      final uri = Uri.parse(text);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } on FormatException {
      return false;
    }
  }

  /// Normalizes a URL by adding https:// if no scheme is present.
  static String normalizeUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }
}
