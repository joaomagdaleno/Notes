import 'dart:io';

void main() {
  print('--- ⚡ Hermes Performance Auditor ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int totalWarnings = 0;

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    bool fileHasIssues = false;

    // 1. Detect large build methods (heuristic)
    bool inBuildMethod = false;
    int buildMethodStart = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Look for Widget build(...)
      if (line.contains('Widget build(')) {
        inBuildMethod = true;
        buildMethodStart = i;
      }

      // End of class or build method (rough heuristic: next override or long gap)
      if (inBuildMethod &&
          (line.contains('@override') || i == lines.length - 1)) {
        final length = i - buildMethodStart;
        if (length > 100) {
          if (!fileHasIssues) {
            print('\nFile: ${file.path}');
            fileHasIssues = true;
          }
          print(
              '  ⚠️ Large Build Method: Line ${buildMethodStart + 1} (~$length lines). Break it down into smaller widgets.');
          totalWarnings++;
        }
        inBuildMethod = false;
      }

      // 2. Detect excessive Opacity
      if (line.contains('Opacity(') && !line.contains('// @no-perf')) {
        if (!fileHasIssues) {
          print('\nFile: ${file.path}');
          fileHasIssues = true;
        }
        print(
            '  ⚠️ Opacity Widget: Line ${i + 1}. Consider using color alpha or Visibility for better performance.');
        totalWarnings++;
      }
    }
  }

  if (totalWarnings == 0) {
    print('\n✅ Performance Audit PASSED. No critical anti-patterns found.');
  } else {
    print('\n⚠️ Found $totalWarnings performance warnings.');
    print(
        '💡 TIP: Optimizing build methods and avoiding expensive widgets reduces frame drops.');
  }
}
