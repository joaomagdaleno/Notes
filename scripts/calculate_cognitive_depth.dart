import 'dart:io';

void main() {
  print('--- 🧠 Hermes Cognitive Depth Scorer ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int highDepthIssues = 0;
  const depthThreshold = 7;

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    int maxDepthInFile = 0;
    int currentDepth = 0;
    int lineOfMaxDepth = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // Basic brace counting for depth
      for (int charIndex = 0; charIndex < line.length; charIndex++) {
        final char = line[charIndex];
        if (char == '{') currentDepth++;
        if (char == '}') currentDepth--;

        if (currentDepth > maxDepthInFile) {
          maxDepthInFile = currentDepth;
          lineOfMaxDepth = i + 1;
        }
      }
    }

    if (maxDepthInFile > depthThreshold) {
      print('\nFile: ${file.path}');
      print(
          '  ⚠️ High Cognitive Depth ($maxDepthInFile levels) at line $lineOfMaxDepth.');
      print(
          '  💡 Recommendation: Extract nested logic or widgets into separate components.');
      highDepthIssues++;
    }
  }

  if (highDepthIssues == 0) {
    print(
        '\n✅ Cognitive Depth Audit PASSED. All files within healthy mental load limits.');
  } else {
    print('\n⚠️ Found $highDepthIssues files with excessive nesting.');
  }
}
