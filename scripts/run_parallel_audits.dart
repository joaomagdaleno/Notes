import 'dart:async';
import 'dart:io';

typedef AuditResult = ({String name, bool passed, String output, int durationMs});

final List<String> fastAudits = [
  'audit_dependencies',
  'audit_licenses',
  'audit_assets',
  'calculate_complexity',
  'check_updates',
  'audit_dependency_usage',
  'audit_platform_parity',
  'audit_i18n',
  'audit_vulnerabilities',
  'audit_env_sync',
  'audit_performance',
  'audit_dead_code',
  'audit_git_hygiene',
  'audit_asset_fidelity',
  'audit_design_system',
  'audit_test_stability',
  'calculate_code_economy',
  'audit_asset_size',
  'audit_workflows',
  'secret_expiry_watchdog',
];

final List<String> slowAudits = [
  'audit_architecture',
  'smoke_test_env',
];

Future<AuditResult> runAudit(String name) async {
  final stopwatch = Stopwatch()..start();
  final script = 'scripts/${name}.dart';
  
  if (!File(script).existsSync()) {
    return (
      name: name,
      passed: true,
      output: 'SKIPPED: $script not found',
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
  
  final result = await Process.run('dart', [script], runInShell: true);
  
  return (
    name: name,
    passed: result.exitCode == 0,
    output: result.stdout.toString().trim(),
    durationMs: stopwatch.elapsedMilliseconds,
  );
}

Future<void> main() async {
  print('--- 🚀 Parallel Audit Runner ---');
  print('Running ${fastAudits.length} audits in parallel...\n');

  final stopwatch = Stopwatch()..start();

  final fastResults = await Future.wait(
    fastAudits.map(runAudit),
  );

  final slowResults = await Future.wait(
    slowAudits.map(runAudit),
  );

  final allResults = [...fastResults, ...slowResults];
  final passed = allResults.where((r) => r.passed).length;
  final failed = allResults.where((r) => !r.passed).length;

  print('\n--- 📊 AUDIT RESULTS ---');
  print('Total: ${allResults.length} | Passed: $passed | Failed: $failed');
  print('Duration: ${stopwatch.elapsedMilliseconds}ms\n');

  for (final result in allResults) {
    final icon = result.passed ? '✅' : '❌';
    print('$icon ${result.name}: ${result.durationMs}ms');
    if (!result.passed) {
      print('   Output: ${result.output.substring(0, min(200, result.output.length))}...');
    }
  }

  if (failed > 0) {
    print('\n❌ AUDITS FAILED: ${failed}');
    exit(1);
  } else {
    print('\n✅ ALL AUDITS PASSED');
  }
}

int min(int a, int b) => a < b ? a : b;