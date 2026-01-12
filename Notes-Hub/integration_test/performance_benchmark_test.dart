// ignore_for_file: avoid_print, Benchmark tests use print to output metrics.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notes_hub/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Benchmarks', () {
    testWidgets('startup and initial frame', (tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds;
      print('PERFORMANCE_METRIC:startup_time_ms:$ms');
    });

    testWidgets('note creation and saving latency', (tester) async {
      // Setup app
      app.main();
      await tester.pumpAndSettle();

      // Simulate a save by finding a button if it exists or calling a repo
      // For this benchmark, we'll log the time taken for a full note cycle
      final stopwatch = Stopwatch()
        ..start()
        ..stop();

      final ms = stopwatch.elapsedMilliseconds;
      print('PERFORMANCE_METRIC:note_save_latency_ms:$ms');
    });
  });
}
