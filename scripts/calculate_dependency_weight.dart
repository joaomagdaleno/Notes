import 'dart:io';
import 'dart:convert';

void main() async {
  print('--- ⚖️ Hermes Dependency Weight Scorer ---');

  final pulseFile = File('project_pulse.json');
  if (!pulseFile.existsSync()) {
    print('ℹ️  No Pulse history found. Skipping analysis.');
    return;
  }

  final history = json.decode(pulseFile.readAsStringSync()) as List;
  if (history.length < 2) return;

  final current = history.last['metrics'];
  final previous = history[history.length - 2]['metrics'];

  final sizeDiffKB = ((current['apk_size_bytes'] as int) -
          (previous['apk_size_bytes'] as int)) /
      1024;

  if (sizeDiffKB > 500) {
    print(
        '⚠️ WARNING: Large size jump detected (+${sizeDiffKB.toStringAsFixed(1)} KB)');

    // Check for NEW dependencies in pubspec
    // Simplified: Just notifying about the jump
    print(
        '💡 Please ensure recent dependencies added are necessary and optimized.');
  } else {
    print(
        '✅ Binary size change is within healthy limits (+${sizeDiffKB.toStringAsFixed(1)} KB).');
  }
}
