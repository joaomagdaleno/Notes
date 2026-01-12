import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 🎯 Hermes Impact Scorer ---');

  double coverage = 0.0;
  int analysisErrors = 0;

  // 1. Load Data
  final coverageFile = File('Notes-Hub/coverage.json');
  if (coverageFile.existsSync()) {
    coverage =
        double.tryParse(
          json.decode(coverageFile.readAsStringSync())['percentage'] ?? '0',
        ) ??
        0.0;
  }

  // Analysis results could be parsed from analyzer output if needed

  // 2. Calculate Grade
  String grade = 'C';
  String reason = 'Standard changes detected.';

  if (coverage >= 90) {
    grade = 'A';
    reason = 'Excellent coverage and stability.';
  } else if (coverage < 80) {
    grade = 'D';
    reason = 'Coverage dropped below safety threshold.';
  }

  // 3. Save Score
  final score = {
    'grade': grade,
    'reason': reason,
    'metrics': {'coverage': coverage, 'analysis': analysisErrors},
  };

  File('impact_score.json').writeAsStringSync(json.encode(score));
  print('✅ PR Impact Scored: $grade ($reason)');
}
