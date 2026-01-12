import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 📉 Hermes Coverage Delta Auditor ---');

  if (!File('coverage.json').existsSync()) {
    print('❌ coverage.json not found. Run tests first.');
    exit(1);
  }

  final current = json.decode(File('coverage.json').readAsStringSync());
  final currentPct = current['percentage'] as double;

  double baselinePct = 0.0;
  if (File('coverage_baseline.json').existsSync()) {
    final baseline =
        json.decode(File('coverage_baseline.json').readAsStringSync());
    baselinePct = (baseline['percentage'] ?? 0.0).toDouble();
  } else {
    print('ℹ️  No baseline found. Assuming 0% previous coverage.');
  }

  final delta = currentPct - baselinePct;
  final symbol = delta >= 0 ? '📈' : '📉';

  print('Baseline: ${baselinePct.toStringAsFixed(2)}%');
  print('Current:  ${currentPct.toStringAsFixed(2)}%');
  print(
      'Delta:    ${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}% $symbol');

  // Report Generation
  final sb = StringBuffer();
  sb.writeln(
      '### $symbol Coverage Delta: **${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}%**');
  sb.writeln('| Metric | Baseline | Current |');
  sb.writeln('|:---:|:---:|:---:|');
  sb.writeln(
      '| **Percentage** | ${baselinePct.toStringAsFixed(2)}% | **${currentPct.toStringAsFixed(2)}%** |');

  File('COVERAGE_DELTA.md').writeAsStringSync(sb.toString());

  if (delta < -2.0) {
    print('⚠️  WARNING: Significant coverage drop detected (>2%).');
    // We could exit(1) here if we wanted to block drops, but for now just warn.
  }
}
