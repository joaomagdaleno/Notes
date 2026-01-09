import 'dart:io';

void main() {
  print('--- 🔍 Hermes Dead Code Auditor ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.path.replaceAll('\\', '/'))
      .toList();

  final entryPoints = ['Notes-Hub/lib/main.dart'];
  final importedFiles = <String>{};

  for (final file in dartFiles) {
    final content = File(file).readAsStringSync();
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.startsWith('import') || line.startsWith('export')) {
        final match =
            RegExp(r'''['"]package:[^/]+/(.*)['"]''').firstMatch(line);
        if (match != null) {
          final relativePath = match.group(1);
          if (relativePath != null) {
            importedFiles.add('Notes-Hub/lib/$relativePath');
          }
        }

        // Handle relative imports
        final relativeMatch =
            RegExp(r'''['"](\.?\./.*\.dart)['"]''').firstMatch(line);
        if (relativeMatch != null) {
          // This is a simplified check for relative imports
          // To be fully accurate we would need to resolve the path relative to the current file
          // But for a rough CI audit, package imports are the primary markers.
        }
      }
    }
  }

  final deadFiles = dartFiles
      .where((f) => !importedFiles.contains(f) && !entryPoints.contains(f))
      .toList();

  if (deadFiles.isEmpty) {
    print('\n✅ No dead code (unused files) detected in lib/.');
  } else {
    print('\n⚠️ Found ${deadFiles.length} potentially unused files:');
    for (final f in deadFiles) {
      print('  - $f');
    }
    print(
        '\n💡 TIP: If these are unused, delete them to keep the project lean.');
  }
}
