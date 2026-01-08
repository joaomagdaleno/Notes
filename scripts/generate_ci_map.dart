import 'dart:io';

void main() {
  print('--- 🗺️ Hermes CI Map Generator ---');

  final workflowDir = Directory('.github/workflows');
  if (!workflowDir.existsSync()) {
    print('❌ Workflows directory not found.');
    return;
  }

  final sb = StringBuffer();
  sb.writeln('# 🛰️ Hermes CI/CD Map');
  sb.writeln('\n*Automatic mapping of pipeline logic and job dependencies.*\n');

  final files = workflowDir.listSync().whereType<File>().where(
    (f) => f.path.endsWith('.yml'),
  );

  for (final file in files) {
    final name = file.path.split(Platform.pathSeparator).last;
    final content = file.readAsStringSync();

    sb.writeln('## 📄 $name');

    // Simple parsing for triggers and jobs
    if (content.contains('on:')) {
      sb.writeln('### ⚡ Triggers');
      final onSection = _extractSection(content, 'on:', 'jobs:');
      sb.writeln('```yaml\n${onSection.trim()}\n```');
    }

    if (content.contains('jobs:')) {
      sb.writeln('### 👷 Jobs');
      final jobs = _extractJobs(content);
      for (final job in jobs) {
        sb.writeln('- **$job**');
      }
    }
    sb.writeln('\n---');
  }

  File('CI_MAP.md').writeAsStringSync(sb.toString());
  print('✅ CI Map generated: CI_MAP.md');
}

String _extractSection(String content, String start, String end) {
  final startIndex = content.indexOf(start);
  if (startIndex == -1) return '';
  final endIndex = content.indexOf(end, startIndex);
  if (endIndex == -1) return content.substring(startIndex);
  return content.substring(startIndex, endIndex);
}

List<String> _extractJobs(String content) {
  final jobs = <String>[];
  final lines = content.split('\n');
  bool inJobs = false;
  for (final line in lines) {
    if (line.trim().startsWith('jobs:')) {
      inJobs = true;
      continue;
    }
    if (inJobs) {
      // Look for top-level job names (indented 2 spaces)
      if (line.startsWith('  ') &&
          !line.startsWith('    ') &&
          line.contains(':')) {
        final jobName = line.split(':').first.trim();
        if (jobName != 'name') {
          jobs.add(jobName);
        }
      }
      // If we hit steps or something deeper, we might be inside a job
      if (line.startsWith('    steps:')) {
        // continue
      }
    }
  }
  return jobs;
}
