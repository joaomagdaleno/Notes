import 'dart:io';

void main() {
  print('--- 📊 Hermes Dependency Graph Generator ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final subDirs = libDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .toList();
  final dependencies = <String, Set<String>>{};

  for (final sourceLayer in subDirs) {
    dependencies[sourceLayer] = <String>{};
    final dir = Directory('${libDir.path}/$sourceLayer');
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final content = file.readAsStringSync();
      for (final targetLayer in subDirs) {
        if (sourceLayer == targetLayer) continue;
        if (content.contains('/$targetLayer/')) {
          dependencies[sourceLayer]!.add(targetLayer);
        }
      }
    }
  }

  final sb = StringBuffer();
  sb.writeln('# 🗺️ Notes Hub Dependency Graph');
  sb.writeln('\n```mermaid');
  sb.writeln('graph TD');

  for (final source in dependencies.keys) {
    for (final target in dependencies[source]!) {
      sb.writeln('    $source --> $target');
    }
  }

  sb.writeln('```');

  File('PROJECT_STRUCTURE.md').writeAsStringSync(sb.toString());
  print('✅ Dependency graph generated: PROJECT_STRUCTURE.md');
}
