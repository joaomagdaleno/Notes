import 'dart:io';

void main(List<String> args) {
  print('--- 📦 Hermes Bundle Integrity Guard ---');

  if (args.isEmpty) {
    print('Usage: dart verify_bundle_integrity.dart <artifact_path>');
    exit(1);
  }

  final path = args[0];
  final file = File(path);

  if (!file.existsSync()) {
    print('❌ Artifact not found at $path');
    exit(1);
  }

  final size = file.lengthSync();
  final sizeMB = (size / (1024 * 1024)).toStringAsFixed(2);

  print('Artifact: ${file.path.split(Platform.pathSeparator).last}');
  print('Size: $sizeMB MB');

  if (size < 1024 * 1024) {
    print('❌ ERROR: Bundle too small (< 1MB). Potential corrupted build.');
    exit(1);
  }

  // Future: Extract manifest and verify version strings
  print('✅ Integrity check passed for $path');
}
