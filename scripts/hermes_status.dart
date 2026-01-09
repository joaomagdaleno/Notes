import 'dart:io';

void main() async {
  print('--- 🏺 Hermes Project Status Dashboard ---');
  print('Aggregating health metrics across the ecosystem...\n');

  final audits = {
    'Project Doctor': 'scripts/hermes_doctor.dart',
    'Asset Audit': 'scripts/audit_assets.dart',
    'License Audit': 'scripts/audit_licenses.dart',
    'Complexity Audit': 'scripts/calculate_complexity.dart',
    'Governance Audit': 'scripts/audit_workflows.dart',
    'Metric Collection': 'scripts/collect_metrics.dart',
    'Dependency Audit': 'scripts/audit_dependencies.dart',
    'Dependency Usage': 'scripts/audit_dependency_usage.dart',
    'Secret Watchdog': 'scripts/secret_expiry_watchdog.dart',
  };

  int successCount = 0;

  for (final entry in audits.entries) {
    stdout.write('Checking ${entry.key}... ');
    final result = await Process.run('dart', [entry.value], runInShell: true);
    if (result.exitCode == 0) {
      print('✅');
      successCount++;
    } else {
      print('❌ (Review ${entry.value})');
    }
  }

  final total = audits.length;
  final score = (successCount / total) * 100;

  print('\n--- 📊 Final Score: ${score.toStringAsFixed(1)}% ---');
  if (score == 100) {
    print('✨ STATUS: LEGENDARY. The fortress is impregnable.');
  } else if (score >= 80) {
    print('🛡️ STATUS: STRONG. Minor maintenance recommended.');
  } else {
    print('⚠️ STATUS: VULNERABLE. Immediate action required.');
    exit(1);
  }
}
