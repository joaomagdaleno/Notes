@Tags(['unit'])
library;

import 'package:test/test.dart';
import 'package:universal_notes_flutter/utils/link_detector.dart';

void main() {
  group('LinkDetector', () {
    test('containsUrl should return true for valid URLs', () {
      expect(
        LinkDetector.containsUrl('Check this out: https://flutter.dev'),
        isTrue,
      );
      expect(
        LinkDetector.containsUrl('Visit http://google.com for more info'),
        isTrue,
      );
    });

    test('containsUrl should return false for text without URLs', () {
      expect(LinkDetector.containsUrl('No links here'), isFalse);
      expect(LinkDetector.containsUrl('email@example.com'), isFalse);
    });

    test('extractUrls should return all URLs found in text', () {
      const text = 'Check https://flutter.dev and http://dart.dev';
      final urls = LinkDetector.extractUrls(text);
      expect(urls, containsAll(['https://flutter.dev', 'http://dart.dev']));
      expect(urls.length, 2);
    });

    test('isValidUrl should validate standard URLs', () {
      expect(LinkDetector.isValidUrl('https://example.com'), isTrue);
      expect(LinkDetector.isValidUrl('http://test.org/path?q=1'), isTrue);
      expect(LinkDetector.isValidUrl('not-a-url'), isFalse);
      expect(LinkDetector.isValidUrl('ftp://invalid-scheme.com'), isFalse);
    });

    test('normalizeUrl should add https:// if missing', () {
      expect(LinkDetector.normalizeUrl('google.com'), 'https://google.com');
      expect(
        LinkDetector.normalizeUrl('http://insecure.com'),
        'http://insecure.com',
      );
      expect(
        LinkDetector.normalizeUrl('https://secure.com'),
        'https://secure.com',
      );
    });

    test(
      'processText should split text into segments with linkUrl (logic check)',
      () {
        final spans = LinkDetector.processText('Link: https://test.com end');
        expect(spans.length, 3);
        expect(spans[0].text, 'Link: ');
        expect(spans[0].linkUrl, isNull);
        expect(spans[1].text, 'https://test.com');
        expect(spans[1].linkUrl, 'https://test.com');
        expect(spans[2].text, ' end');
        expect(spans[2].linkUrl, isNull);
      },
    );
  });
}
