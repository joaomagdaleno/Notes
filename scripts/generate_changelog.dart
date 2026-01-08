import 'dart:io';

void main(List<String> args) async {
  print('--- Hermes Changelog Generator ---');

  // 1. Get last tag
  final lastTagResult = Process.runSync('git', [
    'describe',
    '--tags',
    '--abbrev=0',
    'HEAD^',
  ], runInShell: true);
  final lastTag = lastTagResult.exitCode == 0
      ? lastTagResult.stdout.toString().trim()
      : '';

  print(
    'Generating logs since: ${lastTag.isEmpty ? "Initial Commit" : lastTag}',
  );

  // 2. Get git logs
  final logArgs = lastTag.isEmpty
      ? ['log', '--pretty=format:* %s (%h)']
      : ['log', '$lastTag..HEAD', '--pretty=format:* %s (%h)'];

  final logResult = Process.runSync('git', logArgs, runInShell: true);

  if (logResult.exitCode != 0) {
    print('❌ Error gathering git logs: ${logResult.stderr}');
    exit(1);
  }

  final logs = logResult.stdout.toString().trim();
  final changelogHeader =
      '## Changelog (${DateTime.now().toIso8601String().split("T")[0]})\n\n';
  final fullChangelog =
      changelogHeader + (logs.isEmpty ? '_No changes detected._' : logs);

  // 3. Save to file
  File('changelog.md').writeAsStringSync(fullChangelog);
  print('✅ Changelog generated successfully.');

  // Also save to Notes-Hub for inclusion in artifacts if needed
  File('Notes-Hub/changelog.md').writeAsStringSync(fullChangelog);
}
