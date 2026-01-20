import 'dart:io';

typedef HealthCheck = ({
  String name,
  String status,
  String details,
  int duration,
});

HealthCheck checkFlutterVersion() {
  final result = Process.runSync('flutter', ['--version'], runInShell: true);
  final version = result.exitCode == 0 
      ? result.stdout.toString().split('\n').first
      : 'Not installed';
  return (
    name: 'Flutter Version',
    status: result.exitCode == 0 ? '✅' : '❌',
    details: version,
    duration: 0,
  );
}

HealthCheck checkDartVersion() {
  final result = Process.runSync('dart', ['--version'], runInShell: true);
  final version = result.exitCode == 0 
      ? result.stdout.toString().split('\n').first
      : 'Not installed';
  return (
    name: 'Dart Version',
    status: result.exitCode == 0 ? '✅' : '❌',
    details: version,
    duration: 0,
  );
}

HealthCheck checkToolchainSync() {
  final result = Process.runSync(
    'dart', ['scripts/sync_toolchain.dart'], runInShell: true,
  );
  final output = result.stdout.toString();
  final synced = output.contains('Toolchain versions are synchronized');
  return (
    name: 'Toolchain Sync',
    status: synced ? '✅' : '⚠️',
    details: synced ? 'Locked versions match local' : 'Version drift detected',
    duration: 0,
  );
}

HealthCheck checkPubDependencies() {
  final stopwatch = Stopwatch()..start();
  final result = Process.runSync(
    'flutter', ['pub', 'get'], runInShell: true,
    workingDirectory: 'Notes-Hub',
  );
  stopwatch.stop();
  
  return (
    name: 'Pub Dependencies',
    status: result.exitCode == 0 ? '✅' : '❌',
    details: result.exitCode == 0 
        ? 'Resolved in ${stopwatch.elapsedMilliseconds}ms'
        : 'Failed to resolve dependencies',
    duration: stopwatch.elapsedMilliseconds,
  );
}

HealthCheck checkBuildRunner() {
  final stopwatch = Stopwatch()..start();
  final result = Process.runSync(
    'flutter', ['pub', 'run', 'build_runner', '--version'], 
    runInShell: true,
    workingDirectory: 'Notes-Hub',
  );
  stopwatch.stop();
  
  return (
    name: 'Build Runner',
    status: result.exitCode == 0 ? '✅' : '❌',
    details: result.exitCode == 0 
        ? 'Available (${stopwatch.elapsedMilliseconds}ms)'
        : 'Not available',
    duration: stopwatch.elapsedMilliseconds,
  );
}

HealthCheck checkGitHooks() {
  final result = Process.runSync('lefthook', ['install'], runInShell: true);
  return (
    name: 'Git Hooks',
    status: result.exitCode == 0 ? '✅' : '❌',
    details: result.exitCode == 0 
        ? 'Hooks installed and active'
        : 'Failed to install hooks',
    duration: 0,
  );
}

HealthCheck checkSecrets() {
  final envFile = File('Notes-Hub/env.json');
  final templateFile = File('Notes-Hub/env.json.template');
  
  if (!envFile.existsSync() && templateFile.existsSync()) {
    return (
      name: 'Secrets Configuration',
      status: '⚠️',
      details: 'env.json missing (copy from template)',
      duration: 0,
    );
  }
  
  if (envFile.existsSync()) {
    final content = envFile.readAsStringSync();
    final hasFirebase = content.contains('FIREBASE_OPTIONS');
    final hasAuth = content.contains('AUTH_CONFIG');
    
    if (hasFirebase && hasAuth) {
      return (
        name: 'Secrets Configuration',
        status: '✅',
        details: 'Environment configured',
        duration: 0,
      );
    }
  }
  
  return (
    name: 'Secrets Configuration',
    status: '❌',
    details: 'Missing required secrets',
    duration: 0,
  );
}

void main() {
  print('--- 🚀 Hermes Build Health Dashboard ---');
  print('Checking CI/CD pipeline health...\n');

  final stopwatch = Stopwatch()..start();

  final checks = [
    checkFlutterVersion(),
    checkDartVersion(),
    checkToolchainSync(),
    checkPubDependencies(),
    checkBuildRunner(),
    checkGitHooks(),
    checkSecrets(),
  ];

  stopwatch.stop();

  final passed = checks.where((c) => c.status == '✅').length;
  final warnings = checks.where((c) => c.status == '⚠️').length;
  final failed = checks.where((c) => c.status == '❌').length;

  print('--- 📊 Health Summary ---');
  print('Passed: $passed | Warnings: $warnings | Failed: $failed');
  print('Duration: ${stopwatch.elapsedMilliseconds}ms\n');

  print('--- 🔍 Detailed Results ---');
  for (final check in checks) {
    print('${check.status} ${check.name}');
    print('   ${check.details}');
    if (check.duration > 0) {
      print('   Duration: ${check.duration}ms');
    }
  }

  print('\n--- 📈 Recommendations ---');
  if (warnings > 0 || failed > 0) {
    print('❌ Fix failed checks before committing');
    if (checks.any((c) => c.name == 'Toolchain Sync' && c.status == '⚠️')) {
      print('💡 Run: dart scripts/sync_toolchain.dart --sync');
    }
    if (checks.any((c) => c.name == 'Secrets Configuration' && c.status == '⚠️')) {
      print('💡 Run: cp Notes-Hub/env.json.template Notes-Hub/env.json');
    }
  } else {
    print('✅ Pipeline is healthy and ready for deployment');
  }

  if (failed > 0) {
    exit(1);
  }
}