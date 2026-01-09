import 'dart:io';

void main() {
  print('--- 🏛️ Hermes Architecture Guard ---');

  final libDir = Directory('Notes-Hub/lib');
  if (!libDir.existsSync()) exit(0);

  final layers = {
    'repositories': ['screens', 'widgets'],
    'services': ['screens', 'widgets'],
    'models': ['repositories', 'services', 'screens', 'widgets'],
  };

  int violationCount = 0;

  for (final entry in layers.entries) {
    final layerName = entry.key;
    final forbiddenLayers = entry.value;

    final layerDir = Directory('${libDir.path}/$layerName');
    if (!layerDir.existsSync()) continue;

    final files = layerDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final content = file.readAsStringSync();
      final lines = content.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!line.startsWith('import')) continue;

        for (final forbidden in forbiddenLayers) {
          if (line.contains('/$forbidden/')) {
            print('\n🚨 Architecture Violation in ${file.path}:');
            print('  Line ${i + 1}: $line');
            print(
                '  Layer "$layerName" is NOT allowed to import from "$forbidden".');
            violationCount++;
          }
        }
      }
    }
  }

  if (violationCount == 0) {
    print('\n✅ Architecture Audit PASSED. Layer integrity maintained.');
  } else {
    print('\n⚠️ Found $violationCount architectural violations.');
    print(
        '💡 TIP: Keep your layers decoupled to maintain project scalability.');
  }
}
