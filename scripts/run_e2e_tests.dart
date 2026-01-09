import 'dart:io';

void main(List<String> args) {
  print('--- 🤖 Hermes E2E Runner (Patrol) ---');
  print('Launching integration tests on connected device...\n');

  // Check if any device is connected
  final devicesResult = Process.runSync('flutter', ['devices']);
  if (!devicesResult.stdout.toString().contains('•')) {
    print(
        '❌ No devices connected. Please launch an emulator or connect a phone.');
    print('   Run: flutter emulators --launch <emulator_id>');
    exit(1);
  }

  print('🚀 Running integration_test/app_test.dart...');

  // Running standard flutter integration test.
  // If patrol_cli is configured, we could use 'patrol test'.
  // For now, we use standard flutter test which patrol supports via its bindings.
  final process = Process.start(
    'flutter',
    ['test', 'integration_test/app_test.dart', '--reporter=expanded'],
    workingDirectory: 'Notes-Hub',
    runInShell: true,
  );

  process.then((p) {
    stdout.addStream(p.stdout);
    stderr.addStream(p.stderr);
    p.exitCode.then((code) {
      if (code == 0) {
        print('\n✅ E2E Tests Passed! The app is functional.');
      } else {
        print('\n❌ E2E Tests Failed.');
        exit(code);
      }
    });
  });
}
