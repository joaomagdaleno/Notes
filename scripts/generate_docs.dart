import 'dart:io';

void main() {
  print('--- 📜 Generating Hermes Automation Registry ---');

  final scriptsDir = Directory('scripts');
  if (!scriptsDir.existsSync()) exit(0);

  final scripts = scriptsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final sb = StringBuffer();
  sb.writeln('# 🦅 Hermes Automation Registry');
  sb.writeln(
      '\nA centralized directory of all automation tools and DevOps scripts in the Hermes ecosystem.\n');
  sb.writeln('| Tool | Purpose | CI Integration |');
  sb.writeln('| :--- | :--- | :--- |');

  for (final script in scripts) {
    final name = script.path.split(Platform.pathSeparator).last;
    final content = script.readAsStringSync();

    // Very simple heuristic to extract "Purpose" from first few lines
    String purpose = 'DevOps Utility';
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.contains('---') && line.contains('Hermes')) {
        purpose = line.replaceAll('---', '').replaceAll('Hermes', '').trim();
        break;
      }
    }

    final inCI = _checkCIIntegration(name);
    sb.writeln('| `$name` | $purpose | ${inCI ? '✅' : '❌'} |');
  }

  File('HERMES_REGISTRY.md').writeAsStringSync(sb.toString());
  print('✅ Registry generated: HERMES_REGISTRY.md');
}

bool _checkCIIntegration(String scriptName) {
  final workflowsDir = Directory('.github/workflows');
  if (!workflowsDir.existsSync()) return false;

  return workflowsDir.listSync().any((f) {
    if (f is File && f.path.endsWith('.yml')) {
      return f.readAsStringSync().contains(scriptName);
    }
    return false;
  });
}
