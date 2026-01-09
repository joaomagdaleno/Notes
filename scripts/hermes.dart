import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    await _runInteractiveMode();
    return;
  }

  final command = args[0];
  final remainingArgs = args.sublist(1);

  switch (command) {
    case 'doctor':
      await _runScript('scripts/hermes_doctor.dart', remainingArgs);
      break;
    case 'status':
      await _runScript('scripts/hermes_status.dart', remainingArgs);
      break;
    case 'bump':
      await _runScript('scripts/bump_version.dart', remainingArgs);
      break;
    case 'perf':
      await _runScript('scripts/audit_performance.dart', remainingArgs);
      break;
    case 'repair':
      await _runScript('scripts/hermes_repair.dart', remainingArgs);
      break;
    case 'docs':
      await _runScript('scripts/generate_docs.dart', remainingArgs);
      break;
    case 'arch':
      await _runScript('scripts/audit_architecture.dart', remainingArgs);
      await _runScript('scripts/calculate_cognitive_depth.dart', remainingArgs);
      break;
    case 'viz':
      await _runScript('scripts/generate_dependency_graph.dart', remainingArgs);
      break;
    case 'assurance':
      await _runScript('scripts/audit_dead_code.dart', remainingArgs);
      await _runScript('scripts/smoke_test_env.dart', remainingArgs);
      break;
    case 'context':
      await _runScript('scripts/generate_ai_context.dart', remainingArgs);
      break;
    case 'hygiene':
      await _runScript('scripts/audit_git_hygiene.dart', remainingArgs);
      break;
    case 'fidelity':
      await _runScript('scripts/audit_asset_fidelity.dart', remainingArgs);
      break;
    case 'ready':
      await _runScript('scripts/generate_readiness_report.dart', remainingArgs);
      break;
    case 'predict':
      await _runScript('scripts/predict_next_version.dart', remainingArgs);
      break;
    case 'style':
      await _runScript('scripts/audit_design_system.dart', remainingArgs);
      break;
    case 'telemetry':
      await _runScript('scripts/generate_visual_telemetry.dart', remainingArgs);
      break;
    case 'efficiency':
      await _runScript('scripts/audit_asset_size.dart', remainingArgs);
      break;
    case 'compliance':
      await _runScript('scripts/audit_licenses.dart', remainingArgs);
      break;
    case 'gov':
      await _runScript(
          'scripts/generate_governance_manifest.dart', remainingArgs);
      break;
    case 'secret':
      await _runScript('scripts/local_secret_guard.dart', remainingArgs);
      break;
    case 'firewall':
      await _runScript('scripts/audit_security_rules.dart', remainingArgs);
      break;
    case 'impact':
      await _runScript('scripts/calculate_impact_score.dart', remainingArgs);
      break;
    case 'lock':
      await _runScript('scripts/lock_toolchain.dart', remainingArgs);
      break;
    case 'pulse':
      await _runScript('scripts/generate_health_dashboard.dart', remainingArgs);
      break;
    case 'i18n':
      await _runScript('scripts/audit_i18n.dart', remainingArgs);
      break;
    case 'parity':
      await _runScript('scripts/audit_platform_parity.dart', remainingArgs);
      break;
    case 'env':
      await _runScript('scripts/audit_env_sync.dart', remainingArgs);
      break;
    case 'bom':
      await _runScript('scripts/generate_bom.dart', remainingArgs);
      break;
    case 'log':
      await _runScript('scripts/generate_changelog.dart', remainingArgs);
      break;
    case 'verify':
      await _runScript('scripts/verify_integrity.dart', remainingArgs);
      break;
    case 'sync':
      await _runScript('scripts/sync_coverage_data.dart', remainingArgs);
      break;
    case 'delta':
      await _runScript('scripts/audit_coverage_delta.dart', remainingArgs);
      break;
    case 'badge':
      await _runScript('scripts/generate_coverage_badge.dart', remainingArgs);
      break;
    case 'stability':
      await _runScript('scripts/audit_test_stability.dart', remainingArgs);
      break;
    case 'economy':
      await _runScript('scripts/calculate_code_economy.dart', remainingArgs);
      break;
    case 'notes':
      await _runScript('scripts/generate_release_notes.dart', remainingArgs);
      break;
    case 'audit':
      await _runAudits();
      break;
    case 'e2e':
      await _runScript('scripts/run_e2e_tests.dart', remainingArgs);
      break;
    case 'a11y':
      await _runScript('scripts/audit_accessibility.dart', remainingArgs);
      break;
    case 'security':
      await _runScript('scripts/audit_vulnerabilities.dart', remainingArgs);
      await _runScript('scripts/audit_env_sync.dart', remainingArgs);
      break;
    case 'metrics':
      await _runScript('scripts/collect_metrics.dart', remainingArgs);
      break;
    case 'help':
    default:
      _printUsage();
      break;
  }
}

Future<void> _runInteractiveMode() async {
  print('''
╔══════════════════════════════════════════════╗
║             🦅 HERMES CLI v1.0.0             ║
╠══════════════════════════════════════════════╣
║                                              ║
║  1.  doctor      [Env]   Check Toolchain     ║
║  2.  status      [Audit] Project Health      ║
║  3.  repair      [Fix]   Self-Healing        ║
║  4.  ready       [Rel]   Readiness Report    ║
║  5.  secret      [Sec]   Secret Guard        ║
║  6.  firewall    [Sec]   Security Rules      ║
║  7.  impact      [Qual]  PR Impact Score     ║
║  8.  pulse       [Qual]  Health Dashboard    ║
║  9.  lock        [Env]   Lock Toolchain      ║
║  10. bom         [Rel]   Bill of Materials   ║
║  11. e2e         [Test]  E2E Patrol Test     ║
║  12. a11y        [Qual]  Accessibility Guard ║
║  13. exit                                    ║
║                                              ║
╚══════════════════════════════════════════════╝
''');

  stdout.write('Select an option (1-13): ');
  final input = stdin.readLineSync();

  switch (input) {
    case '1':
      await _runScript('scripts/hermes_doctor.dart', []);
      break;
    case '2':
      await _runScript('scripts/hermes_status.dart', []);
      break;
    case '3':
      await _runScript('scripts/hermes_repair.dart', []);
      break;
    case '4':
      await _runScript('scripts/generate_readiness_report.dart', []);
      break;
    case '5':
      await _runScript('scripts/local_secret_guard.dart', []);
      break;
    case '6':
      await _runScript('scripts/audit_security_rules.dart', []);
      break;
    case '7':
      await _runScript('scripts/calculate_impact_score.dart', []);
      break;
    case '8':
      await _runScript('scripts/generate_health_dashboard.dart', []);
      break;
    case '9':
      await _runScript('scripts/lock_toolchain.dart', []);
      break;
    case '10':
      await _runScript('scripts/generate_bom.dart', []);
      break;
    case '11':
      await _runScript('scripts/run_e2e_tests.dart', []);
      break;
    case '12':
      await _runScript('scripts/audit_accessibility.dart', []);
      break;
    case '13':
      print('👋 Bye!');
      exit(0);
    default:
      print(
          '❌ Invalid option. Try "dart scripts/hermes.dart help" for all commands.');
  }
}

Future<void> _runScript(String path, List<String> args) async {
  final process = await Process.start(
    'dart',
    [path, ...args],
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) exit(exitCode);
}

Future<void> _runAudits() async {
  print('--- 🦅 Hermes Unified Audit ---');
  final audits = [
    'scripts/audit_assets.dart',
    'scripts/audit_licenses.dart',
    'scripts/audit_workflows.dart',
    'scripts/audit_platform_parity.dart',
    'scripts/audit_i18n.dart',
    'scripts/audit_performance.dart',
    'scripts/bundle_analyzer.dart',
    'scripts/audit_architecture.dart',
    'scripts/calculate_cognitive_depth.dart',
    'scripts/audit_dead_code.dart',
    'scripts/smoke_test_env.dart',
    'scripts/audit_git_hygiene.dart',
    'scripts/audit_asset_fidelity.dart',
    'scripts/audit_design_system.dart',
    'scripts/audit_asset_size.dart',
    'scripts/audit_licenses.dart',
    'scripts/audit_test_stability.dart',
    'scripts/calculate_code_economy.dart',
    'scripts/audit_vulnerabilities.dart',
    'scripts/audit_env_sync.dart',
    'scripts/calculate_dependency_weight.dart',
    'scripts/audit_dependencies.dart',
    'scripts/audit_dependency_usage.dart',
  ];

  for (final script in audits) {
    await _runScript(script, []);
  }
}

void _printUsage() {
  print('''
--- 🦅 Hermes CLI ---
Usage: hermes <command> [args]

Commands:
  doctor   Verify toolchain and environment
  status   Show project health dashboard
  bump     Increment project version (major/minor/patch)
  perf     Run performance anti-pattern audit
  repair   Run self-healing project repair
  docs     Generate HERMES_REGISTRY.md documentation
  arch     Run architectural and cognitive depth audits
  viz      Generate dependency graph visualization
  assurance Run dead code and environment smoke tests
  context   Generate AI_CONTEXT.md manifest
  hygiene   Run Git branch and commit hygiene audits
  fidelity  Run high-resolution asset fidelity audit
  ready     Generate deployment readiness report
  predict   Analyze commits to predict next version
  style     Run design system / hardcoded style audit
  telemetry Generate visual trend charts (Mermaid)
  efficiency Run asset size and optimization audit
  compliance Run dependency license compliance audit
  gov       Generate consolidated governance manifest
  secret    Run local pre-commit secret scanner
  firewall  Run security rules (firewall) audit
  impact    Calculate PR impact score (Grading)
  lock      Lock toolchain versions (Flutter/Dart)
  pulse     Generate HTML health dashboard
  i18n      Run localization hardcoded string audit
  parity    Run platform version parity audit
  env       Run environment template sync audit
  bom       Generate Bill of Materials (SHA-256)
  log       Generate automated changelog from git
  verify    Verify artifact integrity against BOM
  sync      Sync coverage data with vault (push/pull)
  delta     Audit coverage delta vs baseline
  badge     Generate coverage badge and dashboard
  stability Run test stability (flakiness) audit
  economy   Run code economy (duplication) audit
  notes     Generate automated release notes
  audit    Run all project audits (I18n, Assets, etc.)
  metrics  Collect and store project metrics
  help     Show this message
''');
}
