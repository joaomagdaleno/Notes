import 'dart:io';

void main() {
  print('--- 🖼️ Hermes Asset Fidelity Guard ---');

  final assetPaths = ['assets', 'Notes-Hub/assets'];
  int lowFidelityCount = 0;

  for (final rootPath in assetPaths) {
    final dir = Directory(rootPath);
    if (!dir.existsSync()) continue;

    final files = dir.listSync(recursive: true).whereType<File>().where((f) =>
        f.path.toLowerCase().endsWith('.png') ||
        f.path.toLowerCase().endsWith('.jpg') ||
        f.path.toLowerCase().endsWith('.jpeg'));

    for (final file in files) {
      final path = file.path.replaceAll('\\', '/');

      // Skip files already in @2x or @3x folders
      if (path.contains('/2.0x/') || path.contains('/3.0x/')) continue;

      final fileName = path.split('/').last;
      final fileDir = file.parent.path.replaceAll('\\', '/');

      final x2Path = '$fileDir/2.0x/$fileName';
      final x3Path = '$fileDir/3.0x/$fileName';

      bool hasX2 = File(x2Path).existsSync();
      bool hasX3 = File(x3Path).existsSync();

      if (!hasX2 || !hasX3) {
        print('\n⚠️  Low Fidelity Asset: $path');
        if (!hasX2) print('  - Missing 2.0x variant');
        if (!hasX3) print('  - Missing 3.0x variant');
        lowFidelityCount++;
      }
    }
  }

  if (lowFidelityCount == 0) {
    print('\n✅ All visual assets have high-fidelity variants.');
  } else {
    print(
        '\n⚠️  Found $lowFidelityCount assets with missing resolution variants.');
    print(
        '💡 TIP: Provide @2x and @3x versions for a crisp UI on high-DPI screens.');
  }
}
