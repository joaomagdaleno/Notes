import 'dart:io';

void main() {
  print('--- Hermes Dependency Audit ---');
  final pubspec = File('Notes-Hub/pubspec.yaml');
  if (!pubspec.existsSync()) {
    print('❌ pubspec.yaml not found.');
    exit(1);
  }

  final lines = pubspec.readAsLinesSync();
  int errors = 0;

  bool inDependencies = false;
  bool inDevDependencies = false;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.startsWith('dependencies:')) {
      inDependencies = true;
      inDevDependencies = false;
      continue;
    }
    if (trimmed.startsWith('dev_dependencies:')) {
      inDependencies = false;
      inDevDependencies = true;
      continue;
    }
    if (trimmed.startsWith('flutter:')) {
      inDependencies = false;
      inDevDependencies = false;
      continue;
    }

    if ((inDependencies || inDevDependencies) &&
        trimmed.isNotEmpty &&
        trimmed.contains(':')) {
      final parts = trimmed.split(':');
      if (parts.length < 2) continue;
      final version = parts[1].trim();

      // Check for 'any'
      if (version == 'any') {
        print('❌ ERROR: Dependency "${parts[0].trim()}" uses "any" version.');
        errors++;
      }

      // Check for extremely loose versions or outdated patterns
      if (version.startsWith('^0.0.')) {
        print(
          '⚠️ WARNING: Dependency "${parts[0].trim()}" is using an early version: $version',
        );
      }
    }
  }

  // Check for redundant lints
  if (lines.any((l) => l.contains('flutter_lints')) &&
      lines.any((l) => l.contains('very_good_analysis'))) {
    print(
      '⚠️ WARNING: Both "flutter_lints" and "very_good_analysis" found. Consider unifying.',
    );
  }

  if (errors > 0) {
    print('\n❌ Dependency audit failed with $errors errors.');
    exit(1);
  } else {
    print('\n✅ Dependency audit passed.');
  }
}
