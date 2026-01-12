import 'dart:io';

void main() {
  print('--- 🛡️ Hermes Secret Expiry Watchdog ---');

  final templateFile = File('Notes-Hub/env.json.template');
  if (!templateFile.existsSync()) return;

  final content = templateFile.readAsStringSync();
  final lines = content.split('\n');

  final today = DateTime.now();
  bool flagged = false;

  for (final line in lines) {
    if (line.contains('EXPIRY')) {
      // Expecting format: "KEY_EXPIRY": "YYYY-MM-DD"
      final parts = line.split(':');
      if (parts.length < 2) continue;

      final dateStr = parts[1].replaceAll('"', '').replaceAll(',', '').trim();
      try {
        final expiry = DateTime.parse(dateStr);
        final daysLeft = expiry.difference(today).inDays;

        if (daysLeft < 0) {
          print('❌ ERROR: ${parts[0].trim()} expired $daysLeft days ago!');
          flagged = true;
        } else if (daysLeft < 30) {
          print('⚠️ WARNING: ${parts[0].trim()} expires in $daysLeft days!');
          flagged = true;
        }
      } catch (_) {
        // Skip invalid formats
      }
    }
  }

  if (!flagged) {
    print('✅ No secrets near expiration detected.');
  }
}
