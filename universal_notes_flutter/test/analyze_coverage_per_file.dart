import 'dart:io';

void main() async {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('lcov.info not found');
    return;
  }

  final lines = await file.readAsLines();
  final fileCoverage = <String, Map<String, int>>{};
  String? currentFile;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      fileCoverage[currentFile] = {'LF': 0, 'LH': 0};
    } else if (line.startsWith('LF:')) {
      fileCoverage[currentFile!]!['LF'] = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileCoverage[currentFile!]!['LH'] = int.parse(line.substring(3));
    }
  }

  final report = fileCoverage.entries.map((e) {
    final lf = e.value['LF']!;
    final lh = e.value['LH']!;
    final coverage = lf == 0 ? 0.0 : (lh / lf) * 100;
    return {
      'file': e.key,
      'coverage': coverage,
      'lf': lf,
      'lh': lh,
    };
  }).toList();

  // Filter for domain layer (lib/services, lib/repositories, lib/models)
  final domainReport = report.where((r) {
    final path = (r['file']! as String).replaceAll(r'\', '/');
    return path.contains('lib/services/') ||
        path.contains('lib/repositories/') ||
        path.contains('lib/models/');
  }).toList();

  domainReport.sort(
    (a, b) => (a['coverage']! as double).compareTo(b['coverage']! as double),
  );

  print('=== DOMAIN LAYER COVERAGE (LOWEST FIRST) ===\n');
  for (final r in domainReport) {
    final cov = (r['coverage']! as double).toStringAsFixed(2);
    print('$cov% (${r['lh']}/${r['lf']}) - ${r['file']}');
  }
}
