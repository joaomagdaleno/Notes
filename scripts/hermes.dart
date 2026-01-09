import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    return;
  }

  final command = args[0];
  final remainingArgs = args.sublist(1);

  switch (command) {
    case 'doctor':
      _runScript('scripts/hermes_doctor.dart', remainingArgs);
      break;
    case 'status':
      _runScript('scripts/hermes_status.dart', remainingArgs);
      break;
    case 'bump':
      _runScript('scripts/bump_version.dart', remainingArgs);
      break;
    case 'perf':
      _runScript('scripts/audit_performance.dart', remainingArgs);
      break;
    case 'repair':
      _runScript('scripts/hermes_repair.dart', remainingArgs);
      break;
    case 'docs':
      _runScript('scripts/generate_docs.dart', remainingArgs);
      break;
    case 'arch':
      _runScript('scripts/audit_architecture.dart', remainingArgs);
      _runScript('scripts/calculate_cognitive_depth.dart', remainingArgs);
      break;
    case 'viz':
      _runScript('scripts/generate_dependency_graph.dart', remainingArgs);
      break;
    case 'assurance':
      _runScript('scripts/audit_dead_code.dart', remainingArgs);
      _runScript('scripts/smoke_test_env.dart', remainingArgs);
      break;
    case 'context':
      _runScript('scripts/generate_ai_context.dart', remainingArgs);
      break;
    case 'hygiene':
      _runScript('scripts/audit_git_hygiene.dart', remainingArgs);
      break;
    case 'fidelity':
      _runScript('scripts/audit_asset_fidelity.dart', remainingArgs);
      break;
    case 'ready':
      _runScript('scripts/generate_readiness_report.dart', remainingArgs);
      break;
    case 'audit':
      _runAudits();
      break;
    case 'security':
      _runScript('scripts/audit_vulnerabilities.dart', remainingArgs);
      _runScript('scripts/audit_env_sync.dart', remainingArgs);
      break;
    case 'metrics':
      _runScript('scripts/collect_metrics.dart', remainingArgs);
      break;
    case 'help':
    default:
      _printUsage();
      break;
  }
}

void _runScript(String path, List<String> args) {
  final result = Process.runSync('dart', [path, ...args]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);
}

void _runAudits() {
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
    'scripts/audit_vulnerabilities.dart',
    'scripts/audit_env_sync.dart',
    'scripts/calculate_dependency_weight.dart',
    'scripts/audit_dependencies.dart',
    'scripts/audit_dependency_usage.dart',
  ];

  for (final script in audits) {
    _runScript(script, []);
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
  audit    Run all project audits (I18n, Assets, etc.)
  metrics  Collect and store project metrics
  help     Show this message
''');
}
