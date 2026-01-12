import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 📊 Hermes Visual Telemetry Generator ---');

  final pulseFile = File('project_pulse.json');
  if (!pulseFile.existsSync()) {
    print('ℹ️  project_pulse.json not found. Run "hermes metrics" first.');
    return;
  }

  try {
    final history = json.decode(pulseFile.readAsStringSync()) as List;
    if (history.isEmpty) {
      print('ℹ️  Metrics history is empty.');
      return;
    }

    final sb = StringBuffer();
    sb.writeln('# 📈 Notes Hub Visual Telemetry');
    sb.writeln(
        '\nProject evolution trends over the last ${history.length} data points.\n');

    // 1. Coverage Trend Chart
    sb.writeln('## 🧪 Code Coverage Trend');
    sb.writeln('\n```mermaid');
    sb.writeln('xychart-beta');
    sb.writeln('    title "Code Coverage (%)"');

    final xLabels = history
        .map((e) => '"${e['timestamp'].toString().substring(5, 10)}"')
        .toList();
    final coverageData =
        history.map((e) => e['metrics']['coverage'].toString()).toList();

    sb.writeln('    x-axis [${xLabels.join(', ')}]');
    sb.writeln('    y-axis "Coverage" 0 --> 100');
    sb.writeln('    line [${coverageData.join(', ')}]');
    sb.writeln('```\n');

    // 2. Size Trend Chart
    sb.writeln('## 📦 Binary Size Trend');
    sb.writeln('\n```mermaid');
    sb.writeln('xychart-beta');
    sb.writeln('    title "APK Size (MB)"');

    final sizeData = history
        .map((e) =>
            (e['metrics']['apk_size_bytes'] / (1024 * 1024)).toStringAsFixed(1))
        .toList();

    sb.writeln('    x-axis [${xLabels.join(', ')}]');
    // Estimate Y axis range based on data
    final sizes = sizeData.map((s) => double.parse(s)).toList();
    final minSize = (sizes.reduce((a, b) => a < b ? a : b) - 2).floor();
    final maxSize = (sizes.reduce((a, b) => a > b ? a : b) + 2).ceil();

    sb.writeln('    y-axis "Size (MB)" $minSize --> $maxSize');
    sb.writeln('    line [${sizeData.join(', ')}]');
    sb.writeln('```\n');

    File('VISUAL_TELEMETRY.md').writeAsStringSync(sb.toString());
    print('✅ Visual telemetry generated: VISUAL_TELEMETRY.md');
  } catch (e) {
    print('❌ FAILED to generate telemetry: $e');
  }
}
