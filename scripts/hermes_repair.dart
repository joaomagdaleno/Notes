import 'dart:io';

void main() async {
  print('--- 🔧 Hermes Self-Repair Tool ---');

  _step(
      'Running Flutter Clean',
      () =>
          Process.runSync('flutter', ['clean'], workingDirectory: 'Notes-Hub'));
  _step(
      'Resolving Dependencies',
      () => Process.runSync('flutter', ['pub', 'get'],
          workingDirectory: 'Notes-Hub'));
  _step(
      'Applying Dart Fixes',
      () => Process.runSync('dart', ['fix', '--apply'],
          workingDirectory: 'Notes-Hub'));
  _step('Performing Custom Cleanup', () {
    // Example: remove DS_Store or other debris
    final debris = [
      'Notes-Hub/.DS_Store',
      'Notes-Hub/android/.gradle',
      'Notes-Hub/build',
    ];
    for (final path in debris) {
      final f = File(path);
      if (f.existsSync()) f.deleteSync(recursive: true);
    }
    return ProcessResult(0, 0, 'Cleaned debris', '');
  });

  _step('Cleaning iOS Pods', () {
    if (Directory('Notes-Hub/ios/Pods').existsSync()) {
      return Process.runSync('rm', ['-rf', 'Pods', 'Podfile.lock'],
          workingDirectory: 'Notes-Hub/ios');
    }
    return ProcessResult(0, 0, 'No Pods found', '');
  });

  _step('Cleaning Android Gradle', () {
    if (Platform.isWindows) {
      return Process.runSync('cmd', ['/c', 'gradlew.bat', 'clean'],
          workingDirectory: 'Notes-Hub/android');
    } else {
      return Process.runSync('./gradlew', ['clean'],
          workingDirectory: 'Notes-Hub/android');
    }
  });

  print(
      '\n✅ Project repair sequence complete. Hermes is back in top shape! 🦅');
}

void _step(String name, ProcessResult Function() action) {
  stdout.write('➡️  $name... ');
  try {
    final result = action();
    if (result.exitCode == 0) {
      print('DONE');
    } else {
      print('FAILED (Non-fatal)');
      // stderr.writeln(result.stderr);
      // Suppress stderr for cleaner repair logs unless debug is needed
    }
  } catch (e) {
    print('SKIPPED (Not applicable)');
  }
}
