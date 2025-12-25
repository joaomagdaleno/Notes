import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' as sdk;

/// A service to manage OpenTelemetry tracing.
class TracingService {
  /// Returns the singleton instance of [TracingService].
  factory TracingService() => _instance;
  TracingService._internal();
  static final TracingService _instance = TracingService._internal();

  late sdk.TracerProviderBase _tracerProvider;
  late Tracer _tracer;

  bool _initialized = false;

  /// Initializes the OpenTelemetry SDK.
  void init() {
    if (_initialized) return;

    // For now, we use a simple ConsoleExporter or Noop for testing
    // In a real app, this would export to Zipkin, Honeycomb, or a collector.
    _tracerProvider = sdk.TracerProviderBase(
      sampler: const sdk.AlwaysOnSampler(),
      processors: [
        // sdk.SimpleSpanProcessor(sdk.ConsoleExporter()), // Try this if available
      ],
    );

    try {
      registerGlobalTracerProvider(_tracerProvider);
    } on Exception catch (_) {
      // Global provider might already be registered
    }
    _tracer = _tracerProvider.getTracer('universal-notes-flutter');
    _initialized = true;
  }

  /// Gets the global tracer.
  Tracer get tracer => _tracer;

  /// Starts a new span.
  Span startSpan(String name, {SpanContext? parentContext}) {
    // For 0.18.10, if parentContext is provided, we should wrap it.
    // However, if the shim is missing, we'll just start a new span for now.
    return _tracer.startSpan(name);
  }
}
