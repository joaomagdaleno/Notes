import 'dart:io';

void main() {
  print('--- 🧠 Hermes Complexity Scorer ---');
  print('Scanning lib/ for code complexity debt...\n');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) return;

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  final complexFiles = <String, int>{};
  int totalScore = 0;
  int fileCount = 0;

  for (final file in files) {
    if (file.path.contains('.g.dart') || file.path.contains('.freezed.dart'))
      continue;

    final content = file.readAsStringSync();
    final complexity = _calculateComplexity(content);

    totalScore += complexity;
    fileCount++;

    if (complexity > 15) {
      complexFiles[file.path] = complexity;
    }
  }

  if (complexFiles.isEmpty) {
    print('✅ All files are within complexity limits.');
  } else {
    print('⚠️ WARNING: High complexity files found (Threshold > 15):');
    complexFiles.forEach((path, score) {
      print('   - $path: $score');
    });
    print(
        '\n> Recommendation: Consider refactoring these files into smaller components.');
  }

  final avg = fileCount > 0 ? totalScore / fileCount : 0;
  print('\n📊 Average Project Complexity: ${avg.toStringAsFixed(1)}');

  // Save for CI
  File('complexity_report.json').writeAsStringSync(
      '{"average": $avg, "high_complexity_count": ${complexFiles.length}}');
}

int _calculateComplexity(String content) {
  // Simple heuristic: count keywords that increase cyclomatic complexity
  final pattern = RegExp(r'\b(if|for|while|switch|catch|\|\||&&)\b');
  return pattern.allMatches(content).length + 1; // Base complexity is 1
}
