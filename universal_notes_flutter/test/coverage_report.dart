// This script is intended to be run from the command line,
// so printing is appropriate.
// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('Coverage file not found.');
    return;
  }

  final lines = file.readAsLinesSync();
  final fileCoverage = <String, Map<String, int>>{};
  var currentFile = '';

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = {'total': 0, 'covered': 0};
    } else if (line.startsWith('DA:')) {
      fileCoverage[currentFile]!['total'] =
          fileCoverage[currentFile]!['total']! + 1;
      final parts = line.split(',');
      if (parts.length > 1 && int.parse(parts[1]) > 0) {
        fileCoverage[currentFile]!['covered'] =
            fileCoverage[currentFile]!['covered']! + 1;
      }
    }
  }

  final sortedFiles = fileCoverage.entries.toList()
    ..sort((a, b) {
      final aTotal = a.value['total']!;
      final bTotal = b.value['total']!;
      if (aTotal == 0) return 0;
      if (bTotal == 0) return 0;
      final aCov = a.value['covered']! / aTotal;
      final bCov = b.value['covered']! / bTotal;
      if (aCov != bCov) return aCov.compareTo(bCov);
      return bTotal.compareTo(aTotal); // Prioritize larger files
    });

  print('--- Low Coverage Files (Top 20) ---');
  for (final entry in sortedFiles.take(20)) {
    final total = entry.value['total']!;
    final covered = entry.value['covered']!;
    final percentage = total == 0 ? 0.0 : (covered / total) * 100;
    if (percentage < 100) {
      print(
        '${percentage.toStringAsFixed(2)}% ($covered/$total) - ${entry.key}',
      );
    }
  }
}
