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
    'Dependency Usage Audit': 'scripts/audit_dependency_usage.dart',
    'Localization Status': 'scripts/audit_i18n.dart',
    'Platform Parity': 'scripts/audit_platform_parity.dart',
    'Env Sync': 'scripts/audit_env_sync.dart',
    'Design System Audit': 'scripts/audit_design_system.dart',
    'Test Stability': 'scripts/audit_test_stability.dart',
    'Code Economy': 'scripts/calculate_code_economy.dart',
    'Asset Efficiency': 'scripts/audit_asset_size.dart',
    'License Compliance': 'scripts/audit_licenses.dart',
    'Dead Code Audit': 'scripts/audit_dead_code.dart',
    'Git Hygiene': 'scripts/audit_git_hygiene.dart',
    'Asset Fidelity': 'scripts/audit_asset_fidelity.dart',
    'Env Smoke Test': 'scripts/smoke_test_env.dart',
    'Performance Audit': 'scripts/audit_performance.dart',
    'Debt Audit': 'scripts/audit_todo.dart',
    'Metric Collection': 'scripts/collect_metrics.dart',
    'Dependency Audit': 'scripts/audit_dependencies.dart',
    'Secret Watchdog': 'scripts/secret_expiry_watchdog.dart',
    'BOM Generator': 'scripts/generate_bom.dart',
    'Changelog System': 'scripts/generate_changelog.dart',
    'Integrity Verifier': 'scripts/verify_integrity.dart',
    'Firewall Guard': 'scripts/audit_security_rules.dart',
    'Local Secret Guard': 'scripts/local_secret_guard.dart',
    'Impact Scorer': 'scripts/calculate_impact_score.dart',
    'Toolchain Lock': 'scripts/lock_toolchain.dart',
    'Health Dashboard': 'scripts/generate_health_dashboard.dart',
    'Accessibility Guard': 'scripts/audit_accessibility.dart',
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
