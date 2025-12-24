/// Script to analyze test timing from JSON reporter output
/// Identifies the slowest tests for optimization
import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('test_timing.json');
  if (!file.existsSync()) {
    print(
      'No test_timing.json found. Run: flutter test --reporter json > test_timing.json',
    );
    return;
  }

  final lines = await file.readAsLines();
  final testDurations = <Map<String, dynamic>>[];
  final startTimes = <int, int>{};
  final testNames = <int, String>{};

  for (final line in lines) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      if (json['type'] == 'testStart') {
        final test = json['test'] as Map<String, dynamic>;
        final testId = test['id'] as int;
        startTimes[testId] = json['time'] as int;
        testNames[testId] = test['name'] as String;
      } else if (json['type'] == 'testDone' && json['result'] != 'skipped') {
        final testId = json['testID'] as int;
        if (startTimes.containsKey(testId)) {
          final duration = (json['time'] as int) - startTimes[testId]!;
          testDurations.add({
            'name': testNames[testId] ?? 'Unknown',
            'duration': duration,
            'id': testId,
          });
        }
      }
    } catch (_) {}
  }

  if (testDurations.isEmpty) {
    print('No test results found in JSON output');
    return;
  }

  // Sort by duration (longest first)
  testDurations.sort(
    (a, b) => (b['duration'] as int).compareTo(a['duration'] as int),
  );

  print('\n=== TOP 20 SLOWEST TESTS (TRUE DURATION) ===\n');
  final top20 = testDurations.take(20).toList();
  for (var i = 0; i < top20.length; i++) {
    final test = top20[i];
    final durationMs = test['duration'] as int;
    final seconds = (durationMs / 1000).toStringAsFixed(2);
    print('${i + 1}. ${seconds}s - ${test['name']} (ID ${test['id']})');
  }

  // Calculate statistics
  final totalDuration = testDurations.fold<int>(
    0,
    (sum, t) => sum + (t['duration'] as int),
  );
  final avgDuration = totalDuration / testDurations.length;

  print('\n=== STATISTICS ===');
  print('Total tests: ${testDurations.length}');
  print(
    'Total cumulative duration: ${(totalDuration / 1000).toStringAsFixed(2)}s',
  );
  print('Average duration: ${(avgDuration / 1000).toStringAsFixed(2)}s');
}
