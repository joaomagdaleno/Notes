import 'dart:io';

void main(List<String> args) {
  print('--- 🤖 Hermes E2E Runner (Patrol) ---');
  print('Launching integration tests on connected device...\n');

  // Check if any device is connected
  final devicesResult =
      Process.runSync('flutter', ['devices'], runInShell: true);
  final output = devicesResult.stdout.toString();

  String? deviceId;
  if (output.toLowerCase().contains('windows')) {
    print('✅ Windows device detected. Using windows.');
    deviceId = 'windows';
  } else if (output.contains('•')) {
    print('✅ Device detected.');
    // Let flutter test pick one or fail if multiple
  } else {
    print(
        '❌ No devices connected. Please launch an emulator or connect a phone.');
    print('   Run: flutter emulators --launch <emulator_id>');
    exit(1);
  }

  print('🚀 Running integration_test/app_test.dart...');

  final testArgs = [
    'test',
    'integration_test/app_test.dart',
    '--reporter=expanded'
  ];
  if (deviceId != null) {
    testArgs.addAll(['-d', deviceId]);
  }

  final process = Process.start(
    'flutter',
    testArgs,
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
