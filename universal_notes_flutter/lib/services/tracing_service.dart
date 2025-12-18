import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' as sdk;

/// A service to manage OpenTelemetry tracing.
class TracingService {
  static final TracingService _instance = TracingService._internal();
  factory TracingService() => _instance;
  TracingService._internal();

  late sdk.TracerProvider _tracerProvider;
  late Tracer _tracer;

  /// Initializes the OpenTelemetry SDK.
  void init() {
    // For now, we use a simple ConsoleExporter or Noop for testing
    // In a real app, this would export to Zipkin, Honeycomb, or a collector.
    _tracerProvider = sdk.TracerProviderBase(
      processors: [
        sdk.SimpleSpanProcessor(sdk.ConsoleSpanExporter()),
      ],
    );

    registerGlobalTracerProvider(_tracerProvider);
    _tracer = _tracerProvider.getTracer('universal-notes-flutter');
  }

  /// Gets the global tracer.
  Tracer get tracer => _tracer;

  /// Starts a new span.
  Span startSpan(String name, {SpanContext? parentContext}) {
    return _tracer.startSpan(
      name,
      context: parentContext != null
          ? Context.current.withSpan(nonRecordingSpan(parentContext))
          : null,
    );
  }
}
