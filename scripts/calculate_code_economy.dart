import 'dart:io';

void main() {
  print('--- 📉 Hermes Code Economy Auditor ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  int totalLines = 0;
  final codeBlocks = <String, String>{}; // Block content -> sample file path
  int duplicatedBlocks = 0;

  for (final file in dartFiles) {
    final lines = file.readAsLinesSync();
    totalLines += lines.length;

    // Basic duplication check: 10 consecutive lines
    for (int i = 0; i <= lines.length - 10; i++) {
      final block = lines.sublist(i, i + 10).map((l) => l.trim()).join('\n');
      if (block.length < 50) continue; // Skip small/empty blocks

      if (codeBlocks.containsKey(block)) {
        if (codeBlocks[block] != file.path) {
          duplicatedBlocks++;
          // Only print the first few duplications to avoid spam
          if (duplicatedBlocks < 5) {
            print('⚠️ Duplicate block found (~10 lines):');
            print('  File A: ${codeBlocks[block]}');
            print('  File B: ${file.path}');
          }
        }
      } else {
        codeBlocks[block] = file.path;
      }
    }

    // Check for "God Files"
    if (lines.length > 500) {
      print(
          '🚩 God File detected (>500 lines): ${file.path} (${lines.length} lines)');
    }
  }

  print('\nSummary:');
  print('  - Total Codebase Lines: $totalLines');
  print('  - Potential Duplicate Code Sections: $duplicatedBlocks');

  if (duplicatedBlocks > 0) {
    print(
        '\n💡 TIP: High duplication detected. Consider extracting common logic into services or mixins.');
  } else {
    print(
        '\n✅ Code Economy Audit PASSED. No significant duplication detected.');
  }
}
