import 'dart:io';

void main() {
  print('--- Hermes Asset Auditor ---');

  final pubspecFile = File('Notes-Hub/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ pubspec.yaml not found in Notes-Hub/');
    exit(1);
  }

  final lines = pubspecFile.readAsLinesSync();
  bool inAssets = false;
  final declaredAssets = <String>[];

  for (final line in lines) {
    if (line.trim().startsWith('assets:')) {
      inAssets = true;
      continue;
    }
    if (inAssets) {
      if (line.startsWith('  ') && line.trim().startsWith('-')) {
        declaredAssets.add(line.trim().substring(1).trim());
      } else if (line.trim().isNotEmpty && !line.startsWith('    ')) {
        inAssets = false;
      }
    }
  }

  if (declaredAssets.isEmpty) {
    print('ℹ️ No assets declared in pubspec.yaml.');
    return;
  }

  print('🔍 Verifying ${declaredAssets.length} asset entries...');
  bool hasErrors = false;

  for (final asset in declaredAssets) {
    final assetPath = 'Notes-Hub/$asset';
    if (asset.endsWith('/')) {
      // It's a directory
      final dir = Directory(assetPath);
      if (!dir.existsSync()) {
        print('❌ Missing Directory: $asset');
        hasErrors = true;
      } else {
        print('✅ Folder OK: $asset');
      }
    } else {
      // It's a file
      final file = File(assetPath);
      if (!file.existsSync()) {
        print('❌ Missing File: $asset');
        hasErrors = true;
      } else {
        print('✅ File OK: $asset');
      }
    }
  }

  if (hasErrors) {
    print('\n❌ Asset Audit FAILED: Some declared assets are missing.');
    exit(1);
  } else {
    print('\n✅ Asset Audit PASSED: All declared assets found.');
  }
}
