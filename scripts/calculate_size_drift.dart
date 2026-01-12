import 'dart:io';
import 'dart:convert';

void main(List<String> args) {
  print('--- Hermes Size Drift Auditor ---');

  if (args.length < 2) {
    print(
      'Usage: dart calculate_size_drift.dart <baseline_json_path> <current_artifacts_dir>',
    );
    exit(0); // Optional: don't fail the build if one is missing
  }

  final baselineFile = File(args[0]);
  final artifactsDir = Directory(args[1]);

  if (!baselineFile.existsSync()) {
    print('ℹ️ Baseline file not found. Skipping drift calculation.');
    return;
  }

  Map<String, dynamic> baseline = {};
  try {
    baseline = json.decode(baselineFile.readAsStringSync());
  } catch (e) {
    print('⚠️ Error parsing baseline: $e');
    return;
  }

  final currentSizes = <String, int>{};
  if (artifactsDir.existsSync()) {
    final files = artifactsDir.listSync(recursive: true).whereType<File>();
    for (final file in files) {
      currentSizes[file.path.split(Platform.pathSeparator).last] = file
          .lengthSync();
    }
  }

  print('\n--- Size Drift Report ---');
  final sb = StringBuffer();
  sb.writeln('### 📊 Artifact Size Drift');
  sb.writeln('| Artifact | Baseline | Current | Drift | Status |');
  sb.writeln('| :--- | :--- | :--- | :--- | :--- |');

  bool significantDrift = false;

  currentSizes.forEach((name, size) {
    if (baseline.containsKey(name)) {
      final oldSize = baseline[name] as int;
      final diff = size - oldSize;
      final percent = (diff / oldSize) * 100;
      final driftStr =
          '${(diff / 1024).toStringAsFixed(2)} KB (${percent.toStringAsFixed(2)}%)';

      String status = '✅';
      if (percent > 5.0) {
        status = '⚠️';
        significantDrift = true;
      } else if (percent < -5.0) {
        status = '📉';
      }

      sb.writeln(
        '| $name | ${(_toMb(oldSize))} | ${(_toMb(size))} | $driftStr | $status |',
      );
    } else {
      sb.writeln('| $name | - | ${(_toMb(size))} | [NEW] | ✨ |');
    }
  });

  print(sb.toString());

  // Save for PR Summary
  File('size_drift.md').writeAsStringSync(sb.toString());

  // Also save current sizes as the new baseline candidate
  File('current_sizes.json').writeAsStringSync(json.encode(currentSizes));

  if (significantDrift) {
    print('\n⚠️ WARNING: Significant size drift detected (> 5%)');
  }
}

String _toMb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
