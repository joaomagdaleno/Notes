import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/utils/link_detector.dart';

void main() {
  group('LinkDetector', () {
    test('processText detects simple URL', () {
      const text = 'Check out https://flutter.dev for more info';
      final spans = LinkDetector.processText(text);

      expect(spans.length, 3);
      expect(spans[0].text, 'Check out ');
      expect(spans[0].linkUrl, isNull);

      expect(spans[1].text, 'https://flutter.dev');
      expect(spans[1].linkUrl, 'https://flutter.dev');
      expect(spans[1].isUnderline, true);

      expect(spans[2].text, ' for more info');
      expect(spans[2].linkUrl, isNull);
    });

    test('processText detects multiple URLs', () {
      const text = 'http://a.com and https://b.org';
      final spans = LinkDetector.processText(text);

      expect(spans.length, 3);
      expect(spans[0].text, 'http://a.com');
      expect(spans[0].linkUrl, 'http://a.com');

      expect(spans[1].text, ' and ');

      expect(spans[2].text, 'https://b.org');
      expect(spans[2].linkUrl, 'https://b.org');
    });

    test('isValidUrl validates correctly', () {
      expect(LinkDetector.isValidUrl('https://google.com'), true);
      expect(LinkDetector.isValidUrl('http://example.org'), true);
      expect(
        LinkDetector.isValidUrl('ftp://example.org'),
        false,
      ); // Only http/s
      expect(LinkDetector.isValidUrl('not a url'), false);
    });

    test('normalizeUrl adds https', () {
      expect(LinkDetector.normalizeUrl('google.com'), 'https://google.com');
      expect(LinkDetector.normalizeUrl('https://site.com'), 'https://site.com');
      expect(LinkDetector.normalizeUrl('http://site.com'), 'http://site.com');
    });
  });
}
