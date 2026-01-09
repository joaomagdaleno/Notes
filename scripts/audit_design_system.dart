import 'dart:io';

void main() {
  print('--- 🎨 Hermes Design System Style Guard ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      // Skip the styles directory itself
      .where((f) => !f.path.contains('lib/styles'));

  int hardcodedStyles = 0;

  // Patterns for hardcoded styles
  final hexColorPattern = RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)');
  final flutterColorPattern =
      RegExp(r'Colors\.[a-z]+(\[[0-9]+\])?', caseSensitive: false);
  const suppressionComment = '@no-style-audit';

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    bool fileHasIssues = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains(suppressionComment)) continue;

      bool hasHex = line.contains(hexColorPattern);
      bool hasFlutterColor = line.contains(flutterColorPattern);

      // We allow Colors.transparent and Colors.white/black as exceptions usually,
      // but for strict audit let's flag all.

      if (hasHex || hasFlutterColor) {
        if (!fileHasIssues) {
          print('\nFile: ${file.path}');
          fileHasIssues = true;
        }
        print('  Line ${i + 1}: ${line.trim()}');
        if (hasHex) print('    -> 🔴 Hardcoded Hex Color found.');
        if (hasFlutterColor) print('    -> 🟡 Standard Flutter Color found.');
        hardcodedStyles++;
      }
    }
  }

  if (hardcodedStyles == 0) {
    print('\n✅ Design System Audit PASSED. UI is using consistent tokens.');
  } else {
    print('\n⚠️ Found $hardcodedStyles potential style violations.');
    print(
        '💡 TIP: Use your project\'s design system tokens in lib/styles/ instead of raw colors.');
  }
}
