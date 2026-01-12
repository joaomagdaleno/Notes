import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 🤖 Generating AI Context Manifest ---');

  final sb = StringBuffer();
  sb.writeln('# 🦅 Hermes AI Context Manifest');
  sb.writeln(
      '\nThis file provides a consolidated snapshot of the project state for AI assistants.\n');

  // 1. Toolchain
  final toolchainFile = File('toolchain.lock.json');
  if (toolchainFile.existsSync()) {
    final data = json.decode(toolchainFile.readAsStringSync());
    sb.writeln('## 🔒 Toolchain');
    sb.writeln('- Flutter: `${data['flutter']}`');
    sb.writeln('- Dart: `${data['dart']}`');
  }

  // 2. Pulse Metrics
  final pulseFile = File('project_pulse.json');
  if (pulseFile.existsSync()) {
    final history = json.decode(pulseFile.readAsStringSync()) as List;
    if (history.isNotEmpty) {
      final latest = history.last['metrics'];
      sb.writeln('\n## 📈 Project Pulse');
      sb.writeln('- Coverage: `${latest['coverage']}%`');
      sb.writeln(
          '- Binary Size: `${(latest['apk_size_bytes'] / (1024 * 1024)).toStringAsFixed(2)} MB`');
    }
  }

  // 3. Automation Inventory
  final scriptsDir = Directory('scripts');
  if (scriptsDir.existsSync()) {
    final scripts = scriptsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .length;
    sb.writeln('\n## 🛠️ Automation Inventory');
    sb.writeln('- Total Scripts: `$scripts`');
    sb.writeln('- Primary Entrypoint: `scripts/hermes.dart`');
  }

  // 4. Maintenance Status
  sb.writeln('\n## 🧹 Maintenance');
  sb.writeln(
      '- Last Generate Time: ${DateTime.now().toUtc().toIso8601String()}');
  sb.writeln('- Documentation: `HERMES_REGISTRY.md`');

  File('AI_CONTEXT.md').writeAsStringSync(sb.toString());
  print('✅ AI Context Manifest generated: AI_CONTEXT.md');
}
