// ignore_for_file: avoid_print

import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!await file.exists()) {
    print('Coverage file not found.');
    return;
  }

  final lines = await file.readAsLines();
  var totalLines = 0;
  var coveredLines = 0;

  for (final line in lines) {
    if (line.startsWith('DA:')) {
      totalLines++;
      final parts = line.split(',');
      if (parts.length > 1 && int.parse(parts[1]) > 0) {
        coveredLines++;
      }
    }
  }

  if (totalLines == 0) {
    print('No lines to cover.');
  } else {
    final percentage = (coveredLines / totalLines) * 100;
    print('Total Lines: $totalLines');
    print('Covered Lines: $coveredLines');
    print('Coverage: ${percentage.toStringAsFixed(2)}%');
  }
}
