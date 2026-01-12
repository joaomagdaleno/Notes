import 'dart:io';

void main(List<String> args) {
  print('--- 🚀 Hermes Version Bumper ---');

  if (args.isEmpty || !['major', 'minor', 'patch', 'build'].contains(args[0])) {
    print('Usage: dart bump_version.dart <major|minor|patch|build>');
    exit(1);
  }

  final type = args[0];
  final pubspecFile = File('Notes-Hub/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('❌ Notes-Hub/pubspec.yaml not found.');
    exit(1);
  }

  final content = pubspecFile.readAsStringSync();
  final versionRegex =
      RegExp(r'^version: (\d+)\.(\d+)\.(\d+)\+(\d+)', multiLine: true);
  final match = versionRegex.firstMatch(content);

  if (match == null) {
    print('❌ Could not find version in pubspec.yaml.');
    exit(1);
  }

  int major = int.parse(match.group(1)!);
  int minor = int.parse(match.group(2)!);
  int patch = int.parse(match.group(3)!);
  int build = int.parse(match.group(4)!);

  switch (type) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      break;
    case 'minor':
      minor++;
      patch = 0;
      break;
    case 'patch':
      patch++;
      break;
    case 'build':
      build++;
      break;
  }

  final newVersion = '$major.$minor.$patch+$build';
  final newContent = content.replaceFirst(versionRegex, 'version: $newVersion');
  pubspecFile.writeAsStringSync(newContent);
  print('✅ Updated pubspec.yaml: $newVersion');

  // Update Android build.gradle
  final gradleFile = File('Notes-Hub/android/app/build.gradle');
  if (gradleFile.existsSync()) {
    var gradleContent = gradleFile.readAsStringSync();

    // Update versionName
    gradleContent = gradleContent.replaceFirst(
      RegExp(r'versionName ".*"'),
      'versionName "$major.$minor.$patch"',
    );
    // Update versionCode
    gradleContent = gradleContent.replaceFirst(
      RegExp(r'versionCode \d+'),
      'versionCode $build',
    );

    gradleFile.writeAsStringSync(gradleContent);
    print('✅ Updated Android build.gradle');
  }

  print('\n🚀 SUCCESS: Hermes version bumped to $newVersion');
}
