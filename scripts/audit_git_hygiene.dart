import 'dart:io';

void main() async {
  print('--- 📂 Hermes Git Hygiene Auditor ---');

  // 1. Branch Naming Policy
  final branchResult =
      Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (branchResult.exitCode == 0) {
    final branchName = branchResult.stdout.toString().trim();
    final allowedPrefixes = [
      'feature/',
      'bugfix/',
      'hotfix/',
      'chore/',
      'refactor/',
      'docs/'
    ];

    bool isValid =
        allowedPrefixes.any((prefix) => branchName.startsWith(prefix)) ||
            branchName == 'main' ||
            branchName == 'develop';

    if (!isValid) {
      print(
          '⚠️  WARNING: Branch name "$branchName" does not follow naming policy.');
      print('💡 TIP: Use prefixes like feature/, bugfix/, or chore/.');
    } else {
      print('✅ Branch name ($branchName) follows policy.');
    }
  }

  // 2. Commit Message Audit (Last 5 commits or PR history)
  print('\nAuditing recent commit history...');
  final logResult =
      Process.runSync('git', ['log', '-n', '5', '--pretty=format:%s']);
  if (logResult.exitCode == 0) {
    final commits = logResult.stdout.toString().split('\n');
    final conventionalPattern = RegExp(
        r'^(feat|fix|chore|docs|style|refactor|perf|test)(\(.*\))?!?: .+',
        caseSensitive: false);

    int invalidCommits = 0;
    for (final commit in commits) {
      if (!conventionalPattern.hasMatch(commit)) {
        print('  ❌ Non-Conventional: "$commit"');
        invalidCommits++;
      } else {
        print('  ✅ Conventional: "$commit"');
      }
    }

    if (invalidCommits > 0) {
      print(
          '\n⚠️  Found $invalidCommits commits that do not follow Conventional Commits standard.');
    }
  }

  print('\n✅ Git hygiene audit complete.');
}
