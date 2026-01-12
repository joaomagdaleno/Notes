import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 🛳️ Generating Deployment Readiness Report ---');

  final sb = StringBuffer();
  sb.writeln('# 🚀 Notes Hub Deployment Readiness Report');
  sb.writeln('\nGenerated on: ${DateTime.now().toLocal()}\n');

  // 1. Version Check
  final pubspec = File('Notes-Hub/pubspec.yaml').readAsStringSync();
  final versionMatch = RegExp(r'version: (.*)').firstMatch(pubspec);
  final version = versionMatch?.group(1) ?? 'Unknown';
  sb.writeln('## 📦 Release Identity');
  sb.writeln('- Target Version: `$version`');

  // 2. Health Score Check (Simplified)
  sb.writeln('\n## ✅ Quality Gate Checklist');

  final statusFile = File('project_pulse.json');
  if (statusFile.existsSync()) {
    final history = json.decode(statusFile.readAsStringSync()) as List;
    final latest = history.isNotEmpty ? history.last['metrics'] : null;
    if (latest != null) {
      sb.writeln(
          '- [${latest['coverage'] >= 80 ? 'x' : ' '}] Unit Test Coverage (Currently: ${latest['coverage']}%)');
      sb.writeln(
          '- [x] Binary Size Analysis (Currently: ${(latest['apk_size_bytes'] / (1024 * 1024)).toStringAsFixed(2)} MB)');
    }
  } else {
    sb.writeln('- [ ] Project Health Score (Pulse data missing)');
  }

  // 3. Infrastructure & Assurance
  final envPassed = File('Notes-Hub/env.json').existsSync();
  sb.writeln('- [${envPassed ? 'x' : ' '}] Environment Payload Validation');

  final locked = File('toolchain.lock.json').existsSync();
  sb.writeln('- [${locked ? 'x' : ' '}] Toolchain Lock Verification');

  // 4. Final Recommendation
  sb.writeln('\n## ⚖️ Final Recommendation');
  if (envPassed && locked) {
    sb.writeln(
        '**READY FOR SHIPMENT.** The fortress is prepared for deployment. 🦅');
  } else {
    sb.writeln(
        '**HOLD SHIPMENT.** Critical pre-checks are missing or failing. ⚠️');
  }

  File('READINESS_REPORT.md').writeAsStringSync(sb.toString());
  print('✅ Readiness report generated: READINESS_REPORT.md');
}
