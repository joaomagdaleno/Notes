import 'dart:io';

void main() {
  print('--- 🛡️ Hermes Vulnerability Auditor ---');

  final lockFile = File('Notes-Hub/pubspec.lock');
  if (!lockFile.existsSync()) {
    print('❌ Notes-Hub/pubspec.lock not found.');
    exit(1);
  }

  final content = lockFile.readAsStringSync();

  // High-risk packages known for frequent vulnerabilities if outdated
  // In a real scenario, this would call OSV.dev or a similar API.
  final riskPackages = {
    'http': '>=0.13.0 <1.0.0',
    'archive': '<3.3.0',
    'crypto': '<3.0.0',
  };

  bool hasRisks = false;

  for (final package in riskPackages.keys) {
    if (content.contains(' $package:')) {
      print('   ⚠️ WARNING: Potential vulnerability risk with "$package".');
      print('   💡 Recommended: Run "flutter pub upgrade" to mitigate.');
      hasRisks = true;
    }
  }

  if (!hasRisks) {
    print('✅ No high-risk dependency vulnerabilities detected locally.');
  } else {
    print('\n⚠️ Vulnerability Audit completed with warnings.');
  }
}
