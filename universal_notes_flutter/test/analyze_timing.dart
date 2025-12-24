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
  final tests = <Map<String, dynamic>>[];

  for (final line in lines) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      if (json['type'] == 'testDone' && json['result'] != 'skipped') {
        tests.add(json);
      }
    } catch (_) {
      // Skip invalid JSON lines
    }
  }

  if (tests.isEmpty) {
    print('No test results found in JSON output');
    return;
  }

  // Sort by time (longest first)
  tests.sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));

  print('\\n=== TOP 20 SLOWEST TESTS ===\\n');
  final top20 = tests.take(20).toList();
  for (var i = 0; i < top20.length; i++) {
    final test = top20[i];
    final timeMs = test['time'] as int;
    final seconds = (timeMs / 1000).toStringAsFixed(2);
    print('${i + 1}. ${seconds}s - Test ID: ${test['testID']}');
  }

  // Calculate statistics
  final totalTime = tests.fold<int>(0, (sum, t) => sum + (t['time'] as int));
  final avgTime = totalTime / tests.length;

  print('\\n=== STATISTICS ===');
  print('Total tests: ${tests.length}');
  print('Total time: ${(totalTime / 1000).toStringAsFixed(2)}s');
  print('Average per test: ${(avgTime / 1000).toStringAsFixed(2)}s');
  print(
    '\\nTop 5 tests account for: ${(tests.take(5).fold<int>(0, (s, t) => s + (t['time'] as int)) / 1000).toStringAsFixed(2)}s',
  );
}
