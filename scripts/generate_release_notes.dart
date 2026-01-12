import 'dart:io';

void main() {
  print('--- 📄 Generating Automated Release Notes ---');

  // get the last tag
  final tagResult =
      Process.runSync('git', ['describe', '--tags', '--abbrev=0']);
  String lastTag = '';
  if (tagResult.exitCode == 0) {
    lastTag = tagResult.stdout.toString().trim();
  } else {
    print('ℹ️  No previous tag found. Using all commits.');
  }

  // get commits since last tag
  final logArgs = lastTag.isEmpty
      ? ['log', '--pretty=format:%s']
      : ['log', '$lastTag..HEAD', '--pretty=format:%s'];
  final logResult = Process.runSync('git', logArgs);

  if (logResult.exitCode != 0 || logResult.stdout.toString().isEmpty) {
    print('ℹ️  No new commits to summarize.');
    return;
  }

  final commits = logResult.stdout.toString().split('\n');
  final features = <String>[];
  final fixes = <String>[];
  final maint = <String>[];
  final breaking = <String>[];

  for (final commit in commits) {
    if (commit.contains('BREAKING CHANGE') || commit.contains('!')) {
      breaking.add(commit);
    } else if (commit.startsWith('feat')) {
      features.add(commit);
    } else if (commit.startsWith('fix')) {
      fixes.add(commit);
    } else {
      maint.add(commit);
    }
  }

  final sb = StringBuffer();
  final now = DateTime.now().toLocal().toString().substring(0, 10);
  sb.writeln('# 🗒️ Release Notes ($now)');

  if (breaking.isNotEmpty) {
    sb.writeln('\n### 🚨 BREAKING CHANGES');
    for (var c in breaking) sb.writeln('- $c');
  }

  if (features.isNotEmpty) {
    sb.writeln('\n### ✨ New Features');
    for (var c in features) sb.writeln('- $c');
  }

  if (fixes.isNotEmpty) {
    sb.writeln('\n### 🛠️ Bug Fixes');
    for (var c in fixes) sb.writeln('- $c');
  }

  if (maint.isNotEmpty) {
    sb.writeln('\n### 🧹 Maintenance & Chore');
    for (var c in maint) sb.writeln('- $c');
  }

  File('RELEASE_NOTES.md').writeAsStringSync(sb.toString());
  print('✅ Release notes generated: RELEASE_NOTES.md');
}
