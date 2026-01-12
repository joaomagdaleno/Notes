import 'dart:io';

void main(List<String> args) {
  print('--- 📦 Hermes Bundle Analyzer ---');

  final buildDir = Directory('Notes-Hub/build');
  if (!buildDir.existsSync()) {
    print('ℹ️  No build directory found. Run a build first.');
    return;
  }

  // Look for APKs and EXEs
  final artifacts = buildDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.apk') || f.path.endsWith('.exe'));

  if (artifacts.isEmpty) {
    print('ℹ️  No release artifacts found to analyze.');
    return;
  }

  for (final artifact in artifacts) {
    final size = artifact.lengthSync();
    final name = artifact.path.split(Platform.pathSeparator).last;
    print('\nAnalyzing $name...');
    print('  - Total Size: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB');

    if (name.endsWith('.apk')) {
      print('  - Type: Android Package');
      // In a real scenario, we'd list files inside the ZIP
    } else {
      print('  - Type: Windows Desktop Installer');
    }
  }

  print('\n✅ Bundle analysis complete.');
}
