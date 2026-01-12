import 'dart:io';
import 'dart:convert';

void main(List<String> args) {
  print('--- 🛡️ Hermes Coverage Badge Generator ---');

  String branch = _getCurrentBranch();
  // Normalize branch (e.g., refs/heads/main -> main)
  branch = branch.replaceAll('refs/heads/', '');
  print('Context: $branch');

  final currentCoverage = _readCoverage('coverage.json');
  if (currentCoverage == null) {
    print('⚠️  No coverage.json found. Skipping badge generation.');
    return;
  }

  // 1. Badge Generation (Skip for Main)
  if (branch == 'main') {
    print('🔇 "No-Metrics Policy" active for Main. Skipping badge generation.');
  } else {
    _generateBadge(currentCoverage['percentage'], 'coverage_badge.svg');
    print('✅ Generated badge: coverage_badge.svg');
  }

  // 2. Global Dashboard (Dev Only)
  if (branch == 'dev') {
    print('\n🌐 Generating Global Metrics Dashboard (Dev Mode)...');
    _generateGlobalDashboard();
  }
}

Map<String, dynamic>? _readCoverage(String path) {
  if (!File(path).existsSync()) return null;
  return json.decode(File(path).readAsStringSync());
}

String _getCurrentBranch() {
  final result = Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (result.exitCode == 0) {
    return result.stdout.toString().trim();
  }
  return 'unknown';
}

void _generateBadge(double percentage, String outputPath) {
  String color;
  if (percentage >= 80)
    color = '#4c1'; // Green
  else if (percentage >= 60)
    color = '#dfb317'; // Yellow
  else
    color = '#e05d44'; // Red

  final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="110" height="20">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <mask id="a">
    <rect width="110" height="20" rx="3" fill="#fff"/>
  </mask>
  <g mask="url(#a)">
    <path fill="#555" d="M0 0h70v20H0z"/>
    <path fill="$color" d="M70 0h40v20H70z"/>
    <path fill="url(#b)" d="M0 0h110v20H0z"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="11">
    <text x="35" y="15" fill="#010101" fill-opacity=".3">coverage</text>
    <text x="35" y="14">coverage</text>
    <text x="90" y="15" fill="#010101" fill-opacity=".3">${percentage.toStringAsFixed(0)}%</text>
    <text x="90" y="14">${percentage.toStringAsFixed(0)}%</text>
  </g>
</svg>
''';
  File(outputPath).writeAsStringSync(svg);
}

void _generateGlobalDashboard() {
  // We need to look into data/ * /coverage.json
  // Since we are likely in the "runner" workspace, we might rely on the sync script
  // having pulled everything? No, sync only pulls specific baseline.
  // BUT the CI orchestrator for "dev" should likely fetch the whole 'coverage-data' branch
  // to a subfolder to allow this readout.

  // For now, let's assume the script looks into a 'vault_snapshot' folder
  // which we will instruct the CI to populate.

  final sb = StringBuffer();
  sb.writeln('# 🌍 Global Metrics Dashboard');
  sb.writeln('Updates automatically from `dev` branch runs.\n');
  sb.writeln('| Branch | Coverage | Status | Last Updated |');
  sb.writeln('|---|---|---|---|');

  final branches = ['main', 'beta', 'dev', 'teste-notes'];

  // To make this work without checking out multiple times, we scan a presumed 'vault' directory
  // In reality, we might need to adjust the CI to clone coverage-data to ./hermes_vault/

  // Mocking the read for now as we set up the infrastructure
  // Real implementation would list directories in ./hermes_vault/data/

  // Checking if local vault cache exists (populated by CI)
  final vaultDir = Directory('hermes_vault/data');
  if (!vaultDir.existsSync()) {
    sb.writeln('\n*Vault data not available in this run context.*');
  } else {
    for (var branch in branches) {
      final file = File('${vaultDir.path}/$branch/coverage.json');
      if (file.existsSync()) {
        final data = json.decode(file.readAsStringSync());
        final pct = data['percentage'];
        final status = pct >= 80 ? '🟢' : (pct >= 60 ? '🟡' : '🔴');
        sb.writeln(
            '| **$branch** | $pct% | $status | ${FileStat.statSync(file.path).modified} |');
      } else {
        sb.writeln('| $branch | N/A | ⚪ | - |');
      }
    }
  }

  File('GLOBAL_METRICS.md').writeAsStringSync(sb.toString());
  print('✅ Generated dashboard: GLOBAL_METRICS.md');
}
