import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('lcov.info not found');
    exit(1);
  }
  final lines = file.readAsLinesSync();
  bool allCovered = true;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('SF:')) {
      int? lf;
      int? lh;
      String filename = lines[i].substring(3); // Remove SF:
      List<int> missedLines = [];
      // Scan forward for DA records
      int k = i + 1;
      while (k < lines.length && lines[k] != 'end_of_record') {
        if (lines[k].startsWith('DA:')) {
          final parts = lines[k].split(':')[1].split(',');
          final lineNum = int.parse(parts[0]);
          final hitCount = int.parse(parts[1]);
          if (hitCount == 0) {
            missedLines.add(lineNum);
          }
        }
        if (lines[k].startsWith('LF:')) {
          lf = int.parse(lines[k].split(':')[1]);
        }
        if (lines[k].startsWith('LH:')) {
          lh = int.parse(lines[k].split(':')[1]);
        }
        k++;
      }

      if (lf != null && lh != null) {
        if (lf != lh) {
          print('Missed coverage in $filename: $lh/$lf');
          print('  Lines: ${missedLines.join(', ')}');
          allCovered = false;
        } else {
          // print('$filename: $lh/$lf (100%)');
        }
      }
    }
  }
  if (allCovered) {
    print('All files 100% covered!');
  }
}
