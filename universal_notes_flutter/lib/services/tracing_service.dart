import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' as sdk;

/// A service to manage OpenTelemetry tracing.
class TracingService {
  static final TracingService _instance = TracingService._internal();
  factory TracingService() => _instance;
  TracingService._internal();

  late sdk.TracerProviderBase _tracerProvider;
  late Tracer _tracer;

  /// Initializes the OpenTelemetry SDK.
  void init() {
    // For now, we use a simple ConsoleExporter or Noop for testing
    // In a real app, this would export to Zipkin, Honeycomb, or a collector.
    _tracerProvider = sdk.TracerProviderBase(
      sampler: sdk.AlwaysOnSampler(),
      processors: [
        // sdk.SimpleSpanProcessor(sdk.ConsoleExporter()), // Try this if available
      ],
    );

    registerGlobalTracerProvider(_tracerProvider);
    _tracer = _tracerProvider.getTracer('universal-notes-flutter');
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
