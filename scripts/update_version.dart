import 'dart:io';

sealed class BuildEnvironment {
  final String name;
  const BuildEnvironment(this.name);
}

class Development extends BuildEnvironment {
  const Development() : super('dev');
}

class Beta extends BuildEnvironment {
  const Beta() : super('beta');
}

class Production extends BuildEnvironment {
  const Production() : super('main');
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart update_version.dart <branch_name> <run_number>');
    exit(1);
  }

  final branchName = args[0];
  final runNumber = args.length > 1 ? args[1] : '0';

  final env = switch (branchName) {
    'main' || 'refs/heads/main' => const Production(),
    'beta' || 'refs/heads/beta' => const Beta(),
    _ => const Development(),
  };

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
    Production() => (semver, buildNumber), // Release uses fixed version
    Beta() => (
      '$major.$minor.${int.parse(patch) + 1}-beta.$runNumber',
      runNumber,
    ),
    Development() => (
      '$major.${int.parse(minor) + 1}.0-dev.$runNumber',
      runNumber,
    ),
  };
}
