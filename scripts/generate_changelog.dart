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

  final logs = logResult.stdout
      .toString()
      .trim()
      .split('\n')
      .where((l) => l.isNotEmpty);

  final categories = {
    '🚀 Features': <String>[],
    '🐛 Bug Fixes': <String>[],
    '📝 Documentation': <String>[],
    '⚙️ Maintenance / Other': <String>[],
  };

  for (final log in logs) {
    if (log.contains('feat:')) {
      categories['🚀 Features']!.add(log);
    } else if (log.contains('fix:')) {
      categories['🐛 Bug Fixes']!.add(log);
    } else if (log.contains('docs:')) {
      categories['📝 Documentation']!.add(log);
    } else {
      categories['⚙️ Maintenance / Other']!.add(log);
    }
  }

  final sb = StringBuffer();
  sb.writeln(
    '## Changelog (${DateTime.now().toIso8601String().split("T")[0]})\n',
  );

  categories.forEach((title, items) {
    if (items.isNotEmpty) {
      sb.writeln('### $title');
      for (final item in items) {
        sb.writeln(item);
      }
      sb.writeln('');
    }
  });

  if (logs.isEmpty) {
    sb.writeln('_No changes detected._');
  }

  final fullChangelog = sb.toString();

  // 3. Save to file
  File('changelog.md').writeAsStringSync(fullChangelog);
  print('✅ Categorized changelog generated successfully.');

  // Also save to Notes-Hub for inclusion in artifacts if needed
  File('Notes-Hub/changelog.md').writeAsStringSync(fullChangelog);
}
