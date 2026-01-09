import 'dart:io';

void main() {
  print('--- 📱 Hermes Platform Parity Auditor ---');

  final pubspecFile = File('Notes-Hub/pubspec.yaml');
  if (!pubspecFile.existsSync()) exit(0);

  final content = pubspecFile.readAsStringSync();
  final versionRegex =
      RegExp(r'^version: (\d+)\.(\d+)\.(\d+)\+(\d+)', multiLine: true);
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    print('❌ Invalid version format in pubspec.yaml');
    exit(1);
  }

  final pubspecVersion =
      '${match.group(1)}.${match.group(2)}.${match.group(3)}';
  final pubspecBuild = match.group(4);

  print('Pubspec: $pubspecVersion+$pubspecBuild');

  bool hasErrors = false;

  // Audit Android
  final gradleFile = File('Notes-Hub/android/app/build.gradle');
  if (gradleFile.existsSync()) {
    final gradleContent = gradleFile.readAsStringSync();

    final vnMatch = RegExp(r'versionName "(.*)"').firstMatch(gradleContent);
    final vcMatch = RegExp(r'versionCode (\d+)').firstMatch(gradleContent);

    if (vnMatch != null) {
      final androidVersion = vnMatch.group(1);
      if (androidVersion != pubspecVersion) {
        print(
            '❌ Android versionName mismatch: $androidVersion vs $pubspecVersion');
        hasErrors = true;
      }
    }

    if (vcMatch != null) {
      final androidBuild = vcMatch.group(1);
      if (androidBuild != pubspecBuild) {
        print('❌ Android versionCode mismatch: $androidBuild vs $pubspecBuild');
        hasErrors = true;
      }
    }

    if (!hasErrors) print('✅ Android Parity OK');
  }

  if (hasErrors) {
    print('\n🚨 PARITY AUDIT FAILED: Platforms are out of sync.');
    exit(1);
  } else {
    print('\n✅ Platform Parity Audit PASSED.');
  }
}
