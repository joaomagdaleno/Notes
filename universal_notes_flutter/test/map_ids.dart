// ignore_for_file: avoid_print
library;

import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('test_timing.json');
  if (!file.existsSync()) return;

  final lines = await file.readAsLines();
  final idToName = <int, String>{};
  final slowIds = [758, 754, 757, 756, 755, 750, 751, 697, 745];

  for (final line in lines) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      if (json['type'] == 'testStart') {
        final test = json['test'] as Map<String, dynamic>;
        idToName[test['id'] as int] = test['name'] as String;
      }
    } catch (_) {}
  }

  print('=== SLOW TESTS MAPPING ===');
  for (final id in slowIds) {
    print('ID $id: ${idToName[id] ?? "Unknown"}');
  }
}
