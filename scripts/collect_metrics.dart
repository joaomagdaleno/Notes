import 'dart:io';
import 'dart:convert';

void main() async {
  print('--- 📊 Hermes Metric Collector ---');

  final now = DateTime.now().toIso8601String();

  // 1. Gather Metrics
  double coverage = 0.0;
  final coverageFile = File('Notes-Hub/coverage.json');
  if (coverageFile.existsSync()) {
    coverage = double.tryParse(
            json.decode(coverageFile.readAsStringSync())['percentage'] ??
                '0') ??
        0.0;
  }

  int apkSize = 0;
  // Look for APK in typical build location
  final apkDir = Directory('Notes-Hub/build/app/outputs/flutter-apk');
  if (apkDir.existsSync()) {
    final apks = apkDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.apk'));
    if (apks.isNotEmpty) {
      apkSize = apks.first.lengthSync();
    }
  }

  // 2. Prepare Pulse Data
  final currentPulse = {
    'timestamp': now,
    'metrics': {
      'coverage': coverage,
      'apk_size_bytes': apkSize,
    }
  };

  // 3. Update History
  final historyFile = File('project_pulse.json');
  List<dynamic> history = [];
  if (historyFile.existsSync()) {
    try {
      history = json.decode(historyFile.readAsStringSync());
    } catch (_) {}
  }

  history.add(currentPulse);

  // Keep last 50 entries
  if (history.length > 50) {
    history = history.sublist(history.length - 50);
  }

  historyFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(history));
  print('✅ Project Pulse updated: ${history.length} entries.');
}
