import 'dart:io';

void main() {
  print('--- 🌐 Hermes I18n Guard ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int hardcodedCount = 0;
  // Look for Text('...') or Text("...")
  final hardcodedPattern = RegExp(r'''Text\(\s*['"].*['"]\s*\)''');
  final suppressionComment = '@no-i18n';

  for (final file in dartFiles) {
    try {
      final lines = file.readAsLinesSync();
      bool fileHasIssues = false;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(hardcodedPattern) &&
            !line.contains(suppressionComment)) {
          if (!fileHasIssues) {
            print('\nFile: ${file.path}');
            fileHasIssues = true;
          }
          print('  Line ${i + 1}: ${line.trim()}');
          hardcodedCount++;
        }
      }
    } catch (_) {}
  }

  if (hardcodedCount == 0) {
    print('\n✅ I18n Audit PASSED. No hardcoded strings found.');
  } else {
    print('\n⚠️ Found $hardcodedCount hardcoded strings.');
    print(
        '💡 TIP: Use your localization tool or add // $suppressionComment to ignore.');
  }
}
