import 'dart:io';

void main() {
  print('--- 🔮 Hermes Semantic Predictor ---');

  // get the last tag
  final tagResult =
      Process.runSync('git', ['describe', '--tags', '--abbrev=0']);
  String lastTag = '0.0.0';
  if (tagResult.exitCode == 0) {
    lastTag = tagResult.stdout.toString().trim();
  }
  print('Last Tag: $lastTag');

  // get commits since last tag
  final logResult = Process.runSync(
      'git', ['log', '$lastTag..HEAD', '--pretty=format:%s%n%b']);
  if (logResult.exitCode != 0) {
    print('ℹ️  No new commits since last tag or tag not found.');
    return;
  }

  final logs = logResult.stdout.toString();
  final major = logs.contains('BREAKING CHANGE:') || logs.contains('!');
  final minor = logs.contains('feat:') || logs.contains('feat(');
  final patch = logs.contains('fix:') ||
      logs.contains('fix(') ||
      logs.contains('chore:') ||
      logs.contains('refactor:');

  final versionParts = lastTag.replaceAll(RegExp(r'[^0-9.]'), '').split('.');
  int vMajor = int.parse(versionParts.length > 0 ? versionParts[0] : '0');
  int vMinor = int.parse(versionParts.length > 1 ? versionParts[1] : '0');
  int vPatch = int.parse(versionParts.length > 2 ? versionParts[2] : '0');

  String prediction = 'No Change';
  String nextVersion = lastTag;

  if (major) {
    prediction = 'MAJOR';
    nextVersion = '${vMajor + 1}.0.0';
  } else if (minor) {
    prediction = 'MINOR';
    nextVersion = '$vMajor.${vMinor + 1}.0';
  } else if (patch) {
    prediction = 'PATCH';
    nextVersion = '$vMajor.$vMinor.${vPatch + 1}';
  }

  print('\nCommit Analysis:');
  print('  - Breaking Changes: ${major ? 'YES 🚨' : 'no'}');
  print('  - New Features: ${minor ? 'YES ✨' : 'no'}');
  print('  - Fixes/Maintenance: ${patch ? 'YES 🛠️' : 'no'}');

  print('\nPrediction: **$prediction BUMP**');
  print('Recommended Next Version: **$nextVersion**');
}
