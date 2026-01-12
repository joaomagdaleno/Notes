import 'dart:io';
import 'dart:convert';

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

  _verifyToolchain();

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

void _verifyToolchain() {
  print('\n--- 🔒 Toolchain Verification ---');
  final lockFile = File('toolchain.lock.json');
  if (!lockFile.existsSync()) {
    print(
      '⚠️ WARNING: toolchain.lock.json not found. Run "dart scripts/lock_toolchain.dart" to lock versions.',
    );
    return;
  }

  try {
    final lockData = json.decode(lockFile.readAsStringSync());
    _compareVersion('flutter', lockData['flutter']);
    _compareVersion('dart', lockData['dart']);
  } catch (e) {
    print('❌ ERROR: Failed to parse toolchain.lock.json');
  }
}

void _compareVersion(String tool, String? lockedVersion) {
  if (lockedVersion == null) return;

  // Real compare would need to run the tool again
  // For now, we print what's locked vs expected
  print('ℹ️ Locked $tool: $lockedVersion');
}
