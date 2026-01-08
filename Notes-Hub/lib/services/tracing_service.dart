import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:opentelemetry/api.dart';
import 'package:opentelemetry/sdk.dart' as sdk;

/// A service to manage OpenTelemetry tracing and Firebase Crashlytics.
class TracingService {
  /// Returns the singleton instance of [TracingService].
  factory TracingService() => _instance;
  TracingService._internal();
  static TracingService _instance = TracingService._internal();

  /// Visible for testing to inject a mock instance.
  @visibleForTesting
  static set instance(TracingService instance) => _instance = instance;

  /// Returns the singleton instance.
  static TracingService get instance => _instance;

  late sdk.TracerProviderBase _tracerProvider;
  late Tracer _tracer;

  bool _initialized = false;

  /// Initializes the OpenTelemetry SDK and Crashlytics.
  void init() {
    if (_initialized) return;

    // For now, we use a simple ConsoleExporter or Noop for testing
    // In a real app, this would export to Zipkin, Honeycomb, or a collector.
    _tracerProvider = sdk.TracerProviderBase(
      sampler: const sdk.AlwaysOnSampler(),
      processors: [
        // sdk.SimpleSpanProcessor(sdk.ConsoleExporter()),
      ],
    );

    try {
      registerGlobalTracerProvider(_tracerProvider);
    } on Exception catch (_) {
      // Global provider might already be registered
    }
    _tracer = _tracerProvider.getTracer('universal-notes-flutter');
    _initialized = true;

    // Log initialization to Crashlytics
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      unawaited(FirebaseCrashlytics.instance.log('TracingService initialized'));
    }
  }

  /// Gets the global tracer.
  Tracer get tracer => _tracer;

  /// Starts a new span.
  Span startSpan(String name, {SpanContext? parentContext}) {
    // Log span start to Crashlytics as a breadcrumb
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      unawaited(FirebaseCrashlytics.instance.log('Start Span: $name'));
    }
    return _tracer.startSpan(name);
  }

  /// Records an error to Crashlytics.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } else {
      debugPrint('Error recorded: $exception');
    }
  }
}
