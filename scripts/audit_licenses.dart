import 'dart:io';

void main(List<String> args) {
  print('--- Hermes License Auditor ---');

  final whitelist = [
    'mit',
    'bsd-3-clause',
    'apache-2.0',
    'bsd-2-clause',
    'isc',
    'zlib',
  ];

  print(
    '🔍 Scanning dependencies for non-compliant licenses (Whitelist: ${whitelist.join(", ")})...',
  );

  // This is a simplified audit. In a full implementation, we'd use
  // 'flutter pub pub run license_checker' or similar.
  // For now, we perform a high-level check via 'flutter pub deps'.

  final result = Process.runSync(
    'flutter',
    ['pub', 'deps', '--style=list'],
    workingDirectory: 'Notes-Hub',
    runInShell: true,
  );

  if (result.exitCode != 0) {
    print('❌ Error running flutter pub deps: ${result.stderr}');
    exit(1);
  }

  // NOTE: Real license auditing requires searching through the transitive
  // dependency tree's LICENSE files. This script serves as a placeholder
  // and demonstration for a stricter policy.

  print('✅ License scan complete (Mock: No forbidden licenses found).');
  print(
    '⚠️ TIP: For production, integrate a tool like "pants" or "license_checker".',
  );
}
