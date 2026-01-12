import 'dart:io';

void main() {
  print('--- 🧹 Hermes Dependency Usage Auditor ---');

  final pubspecFile = File('Notes-Hub/pubspec.yaml');
  if (!pubspecFile.existsSync()) return;

  final content = pubspecFile.readAsStringSync();
  final dependencies = _extractDependencies(content);

  print('Checking usage for ${dependencies.length} dependencies...\n');

  final unused = <String>[];
  final libDir = Directory('Notes-Hub/lib');
  final testDir = Directory('Notes-Hub/test');

  for (final dep in dependencies) {
    if (dep == 'flutter' || dep == 'fluent_ui' || dep == 'firebase_core')
      continue;

    bool used = _isUsed(dep, libDir) || _isUsed(dep, testDir);
    if (!used) {
      unused.add(dep);
    }
  }

  if (unused.isEmpty) {
    print('✅ All dependencies seem to be in use.');
  } else {
    print('⚠️ WARNING: Potentially unused dependencies found:');
    for (final dep in unused) {
      print('   - $dep');
    }
    print(
      '\n> Recommendation: Verify if they can be removed from pubspec.yaml.',
    );
  }
}

List<String> _extractDependencies(String content) {
  final deps = <String>[];
  bool inDeps = false;
  for (final line in content.split('\n')) {
    if (line.startsWith('dependencies:')) {
      inDeps = true;
      continue;
    }
    if (line.startsWith('dev_dependencies:') || line.startsWith('flutter:')) {
      inDeps = false;
    }
    if (inDeps && line.startsWith('  ') && !line.startsWith('    ')) {
      final dep = line.split(':').first.trim();
      if (dep.isNotEmpty) deps.add(dep);
    }
  }
  return deps;
}

bool _isUsed(String dep, Directory dir) {
  if (!dir.existsSync()) return false;
  final normalizedDep = dep.replaceAll(
    '-',
    '_',
  ); // Dart packages use underscores in code

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    if (file.readAsStringSync().contains("import 'package:$normalizedDep/")) {
      return true;
    }
  }
  return false;
}
