import 'dart:io';

void main() {
  print('--- 🩺 Hermes Project Doctor ---');
  print('Verifying local development environment...\n');

  _checkTool('flutter', ['--version']);
  _checkTool('dart', ['--version']);
  _checkTool('lefthook', ['version']);

  _checkFile('Notes-Hub/pubspec.yaml', 'Essential project file');
  _checkFile(
    'Notes-Hub/env.json',
    'Local environment variables',
    remedy:
        'Copy Notes-Hub/env.json.template to Notes-Hub/env.json and fill it.',
  );

  _checkDirectory(
    'Notes-Hub/.dart_tool',
    'Project state',
    remedy: 'Run "flutter pub get" in Notes-Hub directory.',
  );

  print('\n--- Hook Status ---');
  final hookResult = Process.runSync('lefthook', ['install'], runInShell: true);
  if (hookResult.exitCode == 0) {
    print('✅ Git hooks are active and synced.');
  } else {
    print('❌ ERROR: Failed to sync Git hooks.');
    print('   Try: "dart pub global activate lefthook && lefthook install"');
  }

  print(
    '\n✅ Doctor audit complete. If any items above failed, follow the "Try" suggestions.',
  );
}

void _checkTool(String tool, List<String> args) {
  try {
    final result = Process.runSync(tool, args, runInShell: true);
    if (result.exitCode == 0) {
      final firstLine = result.stdout.toString().split('\n').first;
      print('✅ $tool: Found ($firstLine)');
    } else {
      print('❌ $tool: Command failed.');
    }
  } catch (e) {
    print('❌ $tool: Not found in PATH.');
  }
}

void _checkFile(String path, String description, {String? remedy}) {
  if (File(path).existsSync()) {
    print('✅ File: $path ($description)');
  } else {
    print('❌ MISSING: $path ($description)');
    if (remedy != null) print('   Try: $remedy');
  }
}

void _checkDirectory(String path, String description, {String? remedy}) {
  if (Directory(path).existsSync()) {
    print('✅ Folder: $path ($description)');
  } else {
    print('❌ MISSING: $path ($description)');
    if (remedy != null) print('   Try: $remedy');
  }
}
