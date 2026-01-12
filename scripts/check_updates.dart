import 'dart:io';
import 'dart:convert';

void main() async {
  print('--- Hermes Dependency Update Auditor ---');

  final result = await Process.run(
    'flutter',
    ['pub', 'outdated', '--json'],
    workingDirectory: 'Notes-Hub',
    runInShell: true,
  );

  if (result.exitCode != 0) {
    print('❌ Error running flutter pub outdated: ${result.stderr}');
    exit(1);
  }

  try {
    final data = json.decode(result.stdout);
    final packages = data['packages'] as List;

    final updates = <String>[];
    for (final pkg in packages) {
      final name = pkg['package'];
      final current = pkg['current']?['version'];
      final latest = pkg['latest']?['version'];

      if (current != null && latest != null && current != latest) {
        final cParts = current.split('.');
        final lParts = latest.split('.');
        String drift = 'Low';
        if (cParts[0] != lParts[0]) {
          drift = '🔥 CRITICAL (Major)';
        } else if (cParts[1] != lParts[1]) {
          drift = '⚠️ HIGH (Minor)';
        }
        updates.add('* **$name**: $current -> **$latest** ($drift)');
      }
    }

    final sb = StringBuffer();
    sb.writeln('### 🚀 Dependency Updates Available');
    if (updates.isEmpty) {
      sb.writeln('- All dependencies are up to date! ✨');
    } else {
      sb.writeln('The following packages have updates available:');
      for (final update in updates) {
        sb.writeln(update);
      }
      sb.writeln(
        '\n> Run `flutter pub upgrade` to update compatible versions.',
      );
    }

    File('dependency_updates.md').writeAsStringSync(sb.toString());
    print('✅ Update report generated: dependency_updates.md');
    print(sb.toString());
  } catch (e) {
    print('⚠️ Error parsing outdated JSON: $e');
  }
}
