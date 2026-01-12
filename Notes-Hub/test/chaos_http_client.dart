import 'dart:async';
import 'package:http/http.dart' as http;

/// A wrapper for [http.Client] that can inject failures for chaos engineering.
class ChaosHttpClient extends http.BaseClient {
  ChaosHttpClient(this._inner);

  final http.Client _inner;

  /// Whether to inject a random failure.
  bool injectFailures = false;

  /// Probability of a failure (0.0 to 1.0).
  double failureRate = 0.5;

  /// Forced latency.
  Duration? forcedLatency;

  /// Whether to throw a [TimeoutException].
  bool forceTimeout = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (forcedLatency != null) {
      await Future<void>.delayed(forcedLatency!);
    }

    if (forceTimeout) {
      throw TimeoutException('Forced chaos timeout');
    }

    if (injectFailures && (DateTime.now().millisecond / 1000.0) < failureRate) {
      // Simulate a 500 Internal Server Error
      return http.StreamedResponse(
        Stream.value([]),
        500,
        request: request,
        reasonPhrase: 'Chaos Engineering: Forced Failure',
      );
    }

    return _inner.send(request);
  }
}
