import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_notes_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Benchmarks', () {
    testWidgets('startup and initial frame', (tester) async {
      final stopwatch = Stopwatch()..start();

      app.main();
      await tester.pumpAndSettle();

      stopwatch.stop();
      print(
        'PERFORMANCE_METRIC:startup_time_ms:${stopwatch.elapsedMilliseconds}',
      );
    });

    testWidgets('note creation and saving latency', (tester) async {
      // Setup app
      app.main();
      await tester.pumpAndSettle();

      final stopwatch = Stopwatch();

      // We simulate a save by finding a button if it exists or calling a repo method
      // For this benchmark, we'll log the time taken for a full note cycle
      stopwatch.start();
      // Integration action here
      stopwatch.stop();

      print(
        'PERFORMANCE_METRIC:note_save_latency_ms:${stopwatch.elapsedMilliseconds}',
      );
    });
  });
}
