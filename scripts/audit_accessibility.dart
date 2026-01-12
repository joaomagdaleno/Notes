import 'dart:io';

void main() {
  print('--- ♿ Hermes Accessibility (A11y) Guard ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) {
    print('❌ Notes-Hub/lib not found.');
    exit(1);
  }

  int semanticIssues = 0;
  int heuristicContrastIssues = 0;

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  // Patterns to check
  // 1. Buttons without labels/child text (simplified check)
  // Look for IconButtons without semanticLabel
  final iconButtonPattern = RegExp(r'IconButton\s*\(');
  final semanticLabelPattern = RegExp(r'semanticLabel:');

  // 2. Hardcoded Colors (Heuristic for theming violation/contrast)
  // Looking for Colors.red, Color(0xFF...), etc. instead of Theme.of(context)
  final hardcodedColorPattern = RegExp(r'Colors\.[a-z]+|Color\(0x');

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Check for IconButton missing semanticLabel
      // This is a naive check; real AST analysis would be better but this catches low hanging fruit.
      if (line.contains(iconButtonPattern) &&
          !line.contains(semanticLabelPattern)) {
        // Warning for missing semanticLabel on IconButton
        print('⚠️ Potential A11y Issue in ${file.path}:L${i + 1}');
        print('   Code: ${line.trim()}');
        print(
            '   Tip: IconButton should have a semanticLabel for screen readers.');
        semanticIssues++;
      }

      // Check for hardcoded colors
      if (line.contains(hardcodedColorPattern) &&
          !line.contains('// @no-a11y')) {
        print(
            '⚠️ Potential Contrast/Theme Violation in ${file.path}:L${i + 1}');
        print('   Code: ${line.trim()}');
        print(
            '   Tip: Use Theme.of(context).colorScheme or add // @no-a11y to ignore.');
        heuristicContrastIssues++;
      }
    }
  }

  print('\n--- A11y Summary ---');
  print('Semantic/Label Warnings: $semanticIssues');
  print('Heuristic Contrast/Theme Warnings: $heuristicContrastIssues');

  if (heuristicContrastIssues > 0 || semanticIssues > 0) {
    print(
        '\n💡 Recommendation: Fix reported issues to ensure accessibility compliance.');
  } else {
    print('✅ No obvious A11y violations found.');
  }
}
