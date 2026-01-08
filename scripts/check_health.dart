import 'dart:io';

const int maxSizeInBytes = 100 * 1024 * 1024; // 100MB

void main(List<String> args) {
  print('--- Hermes Health Audit ---');

  final exitCode = _runAudit();

  if (exitCode != 0) {
    print('\n⚠️ Health audit found issues.');
  } else {
    print('\n✅ Health audit passed.');
  }

  exit(exitCode);
}

int _runAudit() {
  int errors = 0;

  // 1. Audit Build Artifact Sizes
  errors += _auditSize('Notes-Hub/build/app/outputs/flutter-apk', '.apk');
  errors += _auditSize('Output', '.exe');

  // 2. Audit for Secrets Leak in code (basic check)
  errors += _auditSecrets('Notes-Hub/lib');

  // 3. Audit for Documentation
  errors += _auditDocs();

  return errors > 0 ? 1 : 0;
}

int _auditSize(String directoryPath, String extension) {
  final dir = Directory(directoryPath);
  if (!dir.existsSync()) {
    print('ℹ️ Skipping size audit for $directoryPath (not found)');
    return 0;
  }

  int localErrors = 0;
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith(extension));

  for (final file in files) {
    final size = file.lengthSync();
    final sizeMb = (size / (1024 * 1024)).toStringAsFixed(2);

    if (size > maxSizeInBytes) {
      print(
        '❌ ERROR: File ${file.path} is too large: ${sizeMb}MB (Max: 100MB)',
      );
      localErrors++;
    } else {
      print('✅ Artifact Size: ${file.path} is ${sizeMb}MB');
    }
  }
  return localErrors;
}

int _auditSecrets(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) return 0;

  final secretPatterns = [
    RegExp(r'AIza[0-9A-Za-z-_]{35}'), // Firebase/Google API Key
    RegExp(r'sk_live_[0-9a-zA-Z]{24}'), // Stripe Secret Key
  ];

  int localErrors = 0;
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('firebase_options.dart'))
      continue; // Skip known stubs for now

    final content = file.readAsStringSync();
    for (final pattern in secretPatterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        print('❌ ERROR: Potential secret leak in ${file.path}');
        print('   - Match: ${match.group(0)!.substring(0, 10)}...');
        localErrors++;
        break;
      }
    }
  }
  return localErrors;
}

int _auditDocs() {
  final readme = File('README.md');
  if (!readme.existsSync() || readme.lengthSync() < 10) {
    print('⚠️ WARNING: README.md is missing or too short.');
  }
  return 0; // Warnings don't fail the build
}
