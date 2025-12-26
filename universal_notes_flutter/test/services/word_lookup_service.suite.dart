@Tags(['unit'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:universal_notes_flutter/services/word_lookup_service.dart';

void main() {
  group('WordLookupService', () {
    group('lookupDefinition', () {
      test('returns definition for valid word', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/api/v2/entries/en/hello')) {
            return http.Response.bytes(
              utf8.encode(
                json.encode([
                  {
                    'word': 'hello',
                    'phonetics': [
                      {
                        'text': '/həˈloʊ/',
                        'audio': 'https://audio.example/hello.mp3',
                      },
                    ],
                    'meanings': [
                      {
                        'partOfSpeech': 'interjection',
                        'definitions': [
                          {
                            'definition': 'An expression of greeting.',
                            'example': 'Hello, how are you?',
                          },
                        ],
                      },
                      {
                        'partOfSpeech': 'noun',
                        'definitions': [
                          {
                            'definition': 'A greeting.',
                          },
                        ],
                      },
                    ],
                  },
                ]),
              ),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupDefinition('hello');

        expect(result, isNotNull);
        expect(result!.word, 'hello');
        expect(result.phonetic, '/həˈloʊ/');
        expect(result.audioUrl, 'https://audio.example/hello.mp3');
        expect(result.definitions.length, 2);
        expect(result.definitions[0].partOfSpeech, 'interjection');
        expect(result.definitions[0].definition, 'An expression of greeting.');
        expect(result.definitions[0].example, 'Hello, how are you?');
        expect(result.definitions[1].partOfSpeech, 'noun');

        service.dispose();
      });

      test('returns null for non-existent word', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupDefinition('xyznonexistent');

        expect(result, isNull);

        service.dispose();
      });

      test('handles different language', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/api/v2/entries/es/hola')) {
            return http.Response(
              json.encode([
                {
                  'word': 'hola',
                  'meanings': [
                    {
                      'partOfSpeech': 'interjection',
                      'definitions': [
                        {'definition': 'hello'},
                      ],
                    },
                  ],
                },
              ]),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupDefinition('hola', language: 'es');

        expect(result, isNotNull);
        expect(result!.word, 'hola');

        service.dispose();
      });

      test('handles network error gracefully', () async {
        final mockClient = MockClient((request) async {
          throw Exception('Network error');
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupDefinition('test');

        expect(result, isNull);

        service.dispose();
      });

      test('handles empty response', () async {
        final mockClient = MockClient((request) async {
          return http.Response(json.encode([]), 200);
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupDefinition('empty');

        expect(result, isNull);

        service.dispose();
      });
    });

    group('lookupWikipedia', () {
      test('returns summary for valid term', () async {
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('/page/summary/')) {
            return http.Response(
              json.encode({
                'title': 'Flutter (software)',
                'extract':
                    'Flutter is an open-source UI software development kit.',
                'content_urls': {
                  'desktop': {
                    'page': 'https://en.wikipedia.org/wiki/Flutter_(software)',
                  },
                },
                'thumbnail': {
                  'source': 'https://upload.wikimedia.org/flutter.png',
                },
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupWikipedia('Flutter');

        expect(result, isNotNull);
        expect(result!.title, 'Flutter (software)');
        expect(result.extract, contains('open-source UI'));
        expect(result.pageUrl, contains('wikipedia.org'));
        expect(result.thumbnailUrl, contains('flutter.png'));

        service.dispose();
      });

      test('returns null for non-existent term', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupWikipedia('xyznonexistent12345');

        expect(result, isNull);

        service.dispose();
      });

      test('handles network error gracefully', () async {
        final mockClient = MockClient((request) async {
          throw Exception('Network error');
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupWikipedia('test');

        expect(result, isNull);

        service.dispose();
      });

      test('handles missing optional fields', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            json.encode({
              'title': 'Simple',
              'extract': 'A simple article.',
            }),
            200,
          );
        });

        final service = WordLookupService(client: mockClient);
        final result = await service.lookupWikipedia('simple');

        expect(result, isNotNull);
        expect(result!.pageUrl, isNull);
        expect(result.thumbnailUrl, isNull);

        service.dispose();
      });
    });
  });

  group('WordDefinition', () {
    test('creates with all fields', () {
      const definition = WordDefinition(
        word: 'test',
        phonetic: '/test/',
        audioUrl: 'https://audio.test',
        definitions: [
          DefinitionEntry(
            partOfSpeech: 'noun',
            definition: 'A procedure',
            example: 'We ran a test',
          ),
        ],
      );

      expect(definition.word, 'test');
      expect(definition.phonetic, '/test/');
      expect(definition.audioUrl, 'https://audio.test');
      expect(definition.definitions.length, 1);
    });
  });

  group('DefinitionEntry', () {
    test('creates with required fields', () {
      const entry = DefinitionEntry(
        partOfSpeech: 'verb',
        definition: 'To examine',
      );

      expect(entry.partOfSpeech, 'verb');
      expect(entry.definition, 'To examine');
      expect(entry.example, isNull);
    });

    test('creates with example', () {
      const entry = DefinitionEntry(
        partOfSpeech: 'verb',
        definition: 'To examine',
        example: 'Test the code',
      );

      expect(entry.example, 'Test the code');
    });
  });

  group('WikipediaSummary', () {
    test('creates with all fields', () {
      const summary = WikipediaSummary(
        title: 'Test',
        extract: 'A test article',
        pageUrl: 'https://wiki.test',
        thumbnailUrl: 'https://thumb.test',
      );

      expect(summary.title, 'Test');
      expect(summary.extract, 'A test article');
      expect(summary.pageUrl, 'https://wiki.test');
      expect(summary.thumbnailUrl, 'https://thumb.test');
    });
  });
}
