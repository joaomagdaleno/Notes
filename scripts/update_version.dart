import 'dart:io';

sealed class BuildEnvironment {
  final String name;
  const BuildEnvironment(this.name);
}

class Nightly extends BuildEnvironment {
  const Nightly() : super('nightly');
}

class Stable extends BuildEnvironment {
  const Stable() : super('stable');
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart update_version.dart <branch_name> <run_number>');
    exit(1);
  }

  final channel = args[0].toLowerCase();
  final runNumber = args.length > 1 ? args[1] : '0';

  final env = switch (channel) {
    'stable' || 'release' || 'production' => const Stable(),
    _ => const Nightly(),
  };

  print('[BUILD INFO] Channel: ${env.name.toUpperCase()}');
  print('[BUILD INFO] Run Number: $runNumber');

  final pubspecFile = File('Notes-Hub/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found at ${pubspecFile.path}');
    exit(1);
  }

  final content = pubspecFile.readAsLinesSync();
  final versionLineIndex = content.indexWhere(
    (line) => line.startsWith('version:'),
  );

  if (versionLineIndex == -1) {
    print('Error: version line not found in pubspec.yaml');
    exit(1);
  }

  final currentVersionMatch = RegExp(
    r'version: (.*)',
  ).firstMatch(content[versionLineIndex]);
  if (currentVersionMatch == null) {
    print('Error: Could not parse current version');
    exit(1);
  }

  final currentVersion = currentVersionMatch.group(1)!;
  final versionParts = currentVersion.split('+');
  final semver = versionParts[0];
  final buildNumber = versionParts.length > 1 ? versionParts[1] : '1';

  final (newVersion, newBuildNumber) = _calculateNewVersion(
    env,
    semver,
    buildNumber,
    runNumber,
  );

  print('[BUILD INFO] Current SEMVER: $semver');
  print('[BUILD INFO] Current Build Number: $buildNumber');

  final updatedVersion = '$newVersion+$newBuildNumber';
  content[versionLineIndex] = 'version: $updatedVersion';

  pubspecFile.writeAsStringSync(content.join('\n'));

  print('Successfully updated version to $updatedVersion');

  // Create version.txt for CI artifacts
  File('Notes-Hub/version.txt').writeAsStringSync(updatedVersion);

  // Output for GITHUB_OUTPUT if available
  final githubOutput = Platform.environment['GITHUB_OUTPUT'];
  if (githubOutput != null) {
    final file = File(githubOutput);
    file.writeAsStringSync(
      'full_version=$updatedVersion\n',
      mode: FileMode.append,
    );
  }
}

(String, String) _calculateNewVersion(
  BuildEnvironment env,
  String semver,
  String buildNumber,
  String runNumber,
) {
  final parts = semver.split('.');
  final major = parts[0];
  final minor = parts[1];
  final patch = parts.length > 2 ? parts[2].split('-')[0] : '0';

  return switch (env) {
    Stable() => (semver, buildNumber), // Stable uses fixed version from pubspec
    Nightly() => (
      '$major.$minor.${int.parse(patch)}-nightly.$runNumber',
      runNumber,
    ),
  };
}
