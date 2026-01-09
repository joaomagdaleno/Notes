import 'dart:io';

void main() {
  print('--- 🛡️ Hermes Local Secret Guard ---');
  print('Scanning for potential accidental secret leaks...\n');

  final secretPatterns = {
    'Firebase/Google API Key': RegExp(r'AIza[0-9A-Za-z-_]{35}'),
    'GitHub Personal Access Token': RegExp(r'ghp_[a-zA-Z0-9]{36}'),
    'Generic Secret Pattern': RegExp(r'(-[a-zA-Z0-9]{39})'),
  };

  final gitFiles = Process.runSync('git', ['diff', '--cached', '--name-only'],
      runInShell: true);
  if (gitFiles.exitCode != 0) {
    print(
        '⚠️ Error running git diff. Scanning all files in current directory...');
  }

  final filesToScan = gitFiles.stdout
      .toString()
      .split('\n')
      .where((s) => s.isNotEmpty && File(s).existsSync());

  bool flagged = false;

  for (final filePath in filesToScan) {
    if (filePath == 'scripts/local_secret_guard.dart' ||
        filePath.endsWith('.json.template')) continue;

    final file = File(filePath);
    final content = file.readAsStringSync();

    secretPatterns.forEach((name, pattern) {
      if (pattern.hasMatch(content)) {
        print('❌ DANGER: Potential $name found in $filePath!');
        flagged = true;
      }
    });
  }

  if (flagged) {
    print(
        '\n🚨 COMMIT BLOCKED: Please remove secrets or move them to env.json (ignored by git).');
    exit(1);
  } else {
    print('✅ No obvious secrets detected in staged files.');
  }
}
