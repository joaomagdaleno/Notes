import 'dart:io';

void main() {
  print('--- 📝 Hermes Debt Watcher (TODO Audit) ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int todoCount = 0;
  int fixmeCount = 0;
  final debtPattern =
      RegExp(r'//\s*(TODO|FIXME):?\s*(.*)', caseSensitive: false);

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    bool fileHasIssues = false;

    for (int i = 0; i < lines.length; i++) {
      final match = debtPattern.firstMatch(lines[i]);
      if (match != null) {
        if (!fileHasIssues) {
          print('\nFile: ${file.path}');
          fileHasIssues = true;
        }
        final type = match.group(1)?.toUpperCase();
        final msg = match.group(2)?.trim();
        print('  Line ${i + 1} [$type]: $msg');

        if (type == 'TODO') todoCount++;
        if (type == 'FIXME') fixmeCount++;
      }
    }
  }

  print('\n--- Debt Summary ---');
  print('⏳ TODOs: $todoCount');
  print('🚨 FIXMEs: $fixmeCount');

  if (todoCount + fixmeCount > 20) {
    print(
        '\n⚠️ WARNING: Technical debt is accumulating. Consider a refactoring sprint.');
  } else {
    print('\n✅ Technical debt is within healthy limits.');
  }
}
