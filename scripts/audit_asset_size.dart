import 'dart:io';

void main() {
  print('--- 📦 Hermes Asset Efficiency Auditor ---');

  final assetDir = Directory('Notes-Hub/assets');
  if (!assetDir.existsSync()) {
    print('ℹ️  assets directory not found.');
    exit(0);
  }

  // Read pubspec to find declared assets
  final pubspecFile = File('Notes-Hub/pubspec.yaml');
  final pubspecContent = pubspecFile.readAsStringSync();

  final files = assetDir.listSync(recursive: true).whereType<File>().toList();

  int largeAssets = 0;
  int undeclaredAssets = 0;
  const int sizeLimit = 1 * 1024 * 1024; // 1MB

  for (final file in files) {
    final path = file.path.replaceAll('\\', '/');
    final relativePath = path.substring(path.indexOf('assets/'));
    final size = file.lengthSync();

    // 1. Check Size
    if (size > sizeLimit) {
      print('\n🚩 Oversized Asset: $path');
      print('   Size: ${(size / (1024 * 1024)).toStringAsFixed(2)} MB');
      print('   💡 TIP: Consider compressing or converting to WebP/SVG.');
      largeAssets++;
    }

    // 2. Check Optimization (PNG to WebP hint)
    if (path.toLowerCase().endsWith('.png') && size > 200 * 1024) {
      print('\nℹ️  Optimization Hint: $path');
      print('   Large PNG detected. WebP could reduce size by ~30-50%.');
    }

    // 3. Check Declaration
    if (!pubspecContent.contains(relativePath)) {
      // Check if it's in a subdirectory that IS declared
      final parentDir = file.parent.path.replaceAll('\\', '/');
      final relParent = parentDir.substring(parentDir.indexOf('assets/')) + '/';

      if (!pubspecContent.contains(relParent)) {
        print('\n⚠️  Undeclared Asset: $path');
        print(
            '   File exists but is not found in pubspec.yaml (explicitly or by folder).');
        undeclaredAssets++;
      }
    }
  }

  print('\nSummary:');
  print('  - Oversized Assets (>1MB): $largeAssets');
  print('  - Undeclared Assets: $undeclaredAssets');

  if (largeAssets > 0 || undeclaredAssets > 0) {
    print(
        '\n💡 TIP: Run "hermes repair" to clean up or optimize assets (logic to be added).');
  } else {
    print('\n✅ Asset Efficiency Audit PASSED.');
  }
}
