import 'package:test/test.dart';
import 'package:universal_notes_flutter/services/tracing_service.dart';
import 'package:opentelemetry/api.dart';

void main() {
  group('TracingService', () {
    late TracingService service;

    setUp(() {
      service = TracingService();
      service.init();
    });

    test('should provide a tracer after initialization', () {
      expect(service.tracer, isNotNull);
    });

    test('should start a span with the given name', () {
      final span = service.startSpan('test_span');
      expect(span, isNotNull);
      // We can't easily check the name without more complex OTel mocking,
      // but we verify it doesn't crash.
      span.end();
    });

    test('singleton instance should be shared', () {
      final instance1 = TracingService();
      final instance2 = TracingService();
      expect(instance1, same(instance2));
    });
  });
}
