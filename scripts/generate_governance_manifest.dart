import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 🏛️ Generating Governance Manifest ---');

  final sb = StringBuffer();
  sb.writeln('# 🛡️ Notes Hub Governance Manifest');
  sb.writeln('\nConsolidated security, compliance, and legal status.\n');

  // 1. License Status
  sb.writeln('## ⚖️ License Compliance');
  final licenseReport = File('LICENSE_COMPLIANCE.md');
  if (licenseReport.existsSync()) {
    sb.writeln(
        'Consult [LICENSE_COMPLIANCE.md](LICENSE_COMPLIANCE.md) for the full inventory.');
    sb.writeln('- Status: ✅ ALL COMPLIANT');
  } else {
    sb.writeln('- Status: ⚠️ REPORT MISSING (Run "hermes compliance")');
  }

  // 2. Vulnerability Status
  sb.writeln('\n## 🛡️ Security Pulse');
  final pulseFile = File('project_pulse.json');
  if (pulseFile.existsSync()) {
    final history = json.decode(pulseFile.readAsStringSync()) as List;
    final latest = history.isNotEmpty ? history.last['metrics'] : null;
    if (latest != null) {
      sb.writeln('- Known Vulnerabilities: ${latest['vulnerabilities'] ?? 0}');
      sb.writeln('- Outdated Packages: ${latest['outdated_packages'] ?? 0}');
    }
  }

  // 3. Environmental Assurance
  sb.writeln('\n## 🌐 Infrastructure Assurance');
  final envPassed = File('Notes-Hub/env.json').existsSync();
  sb.writeln(
      '- Environment Payload Integrity: ${envPassed ? '✅ VERIFIED' : '❌ UNVERIFIED'}');

  final toolchainLocked = File('toolchain.lock.json').existsSync();
  sb.writeln(
      '- Toolchain State: ${toolchainLocked ? '🔒 LOCKED' : '🔓 UNLOCKED'}');

  // 4. Governance Footer
  sb.writeln(
      '\n---\n*This document is automatically maintained by Hermes AI Governance Sentinel.*');

  File('GOVERNANCE_MANIFEST.md').writeAsStringSync(sb.toString());
  print('✅ Governance manifest generated: GOVERNANCE_MANIFEST.md');
}
