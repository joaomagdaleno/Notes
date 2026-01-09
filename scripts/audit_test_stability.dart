import 'dart:io';

void main() {
  print('--- ⚖️ Hermes Stability Sentinel ---');

  final testDir = Directory('Notes-Hub/test');
  if (!testDir.existsSync()) {
    print('ℹ️  test/ directory not found.');
    exit(0);
  }

  final testFiles = testDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_test.dart'));

  int fragilePatterns = 0;

  // Patterns for test flakiness
  final delayedPattern = RegExp(r'Future\.delayed');
  final sleepPattern = RegExp(r'sleep\(');
  final pumpDurationPattern = RegExp(r'tester\.pump\(Duration');

  for (final file in testFiles) {
    final lines = file.readAsLinesSync();
    bool fileHasIssues = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      bool hasDelayed = line.contains(delayedPattern);
      bool hasSleep = line.contains(sleepPattern);
      bool hasPumpDuration = line.contains(pumpDurationPattern);

      if (hasDelayed || hasSleep || hasPumpDuration) {
        if (!fileHasIssues) {
          print('\nFile: ${file.path}');
          fileHasIssues = true;
        }
        print('  Line ${i + 1}: ${line.trim()}');
        if (hasDelayed)
          print('    -> ⚠️ Usage of Future.delayed detected (Flaky risk)');
        if (hasSleep)
          print('    -> ⚠️ Usage of sleep() detected (Strict wait block)');
        if (hasPumpDuration)
          print(
              '    -> ⚠️ Manual tester.pump with Duration (Consider pumpAndSettle)');
        fragilePatterns++;
      }
    }
  }

  if (fragilePatterns == 0) {
    print('\n✅ Test Stability Audit PASSED. No fragile patterns detected.');
  } else {
    print('\n⚠️ Found $fragilePatterns potential flakiness risks in tests.');
    print(
        '💡 TIP: Prefer pumpAndSettle() or specific Microtasks over hardcoded delays.');
  }
}
