import 'dart:io';
import 'dart:convert';

void main() async {
  print('--- 🔒 Hermes Toolchain Locker ---');

  final toolchain = {
    'flutter': await _getVersion('flutter', ['--version']),
    'dart': await _getVersion('dart', ['--version']),
    'java': await _getVersion('java', ['-version']),
    'timestamp': DateTime.now().toIso8601String(),
  };

  final file = File('toolchain.lock.json');
  file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(toolchain));

  print('✅ Toolchain locked in ${file.path}');
}

Future<String> _getVersion(String tool, List<String> args) async {
  try {
    final result = await Process.run(tool, args, runInShell: true);
    // Combine stdout and stderr since java -version prints to stderr
    final output = (result.stdout.toString() + result.stderr.toString()).trim();
    if (output.isEmpty) return 'Unknown';
    // Return first meaningful line
    return output
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => 'Unknown');
  } catch (e) {
    return 'Not found';
  }
}
