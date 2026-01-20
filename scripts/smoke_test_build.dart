import 'dart:io';

typedef SmokeTestResult = ({
  String name,
  bool passed,
  String message,
});

final minSizes = {
  '.apk': 1024 * 1024,      // 1 MB minimum for APK
  '.exe': 5 * 1024 * 1024,   // 5 MB minimum for installer
};

Future<SmokeTestResult> verifyArtifact(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return (
      name: path,
      passed: false,
      message: 'Artifact not found',
    );
  }

  final size = file.lengthSync();
  final extension = '.${path.split('.').last}';
  final minSize = minSizes[extension] ?? 0;

  if (size < minSize) {
    return (
      name: path,
      passed: false,
      message: 'Size ${size / 1024 / 1024}MB below minimum ${minSize / 1024 / 1024}MB',
    );
  }

  return (
    name: path,
    passed: true,
    message: 'Size: ${(size / 1024 / 1024).toStringAsFixed(2)}MB',
  );
}

Future<void> main(List<String> args) async {
  print('--- 🔍 Build Smoke Test ---');

  final artifacts = args.isNotEmpty ? args : _discoverArtifacts();

  print('Found ${artifacts.length} artifacts to verify\n');

  final results = await Future.wait(
    artifacts.map(verifyArtifact),
  );

  final passed = results.where((r) => r.passed).length;
  final failed = results.length - passed;

  print('--- 📊 Smoke Test Results ---');
  print('Total: ${results.length} | Passed: $passed | Failed: $failed\n');

  for (final result in results) {
    final icon = result.passed ? '✅' : '❌';
    print('$icon ${result.name}');
    print('   ${result.message}');
  }

  if (failed > 0) {
    print('\n❌ SMOKE TESTS FAILED');
    exit(1);
  } else {
    print('\n✅ ALL SMOKE TESTS PASSED');
  }
}

List<String> _discoverArtifacts() {
  final artifacts = <String>[];

  final apkDir = Directory('Notes-Hub/build/app/outputs/flutter-apk');
  if (apkDir.existsSync()) {
    artifacts.addAll(
      apkDir.listSync()
        .where((e) => e.path.endsWith('.apk'))
        .map((e) => e.path),
    );
  }

  final exeDir = Directory('Output');
  if (exeDir.existsSync()) {
    artifacts.addAll(
      exeDir.listSync()
        .where((e) => e.path.endsWith('.exe'))
        .map((e) => e.path),
    );
  }

  return artifacts;
}