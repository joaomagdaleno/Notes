import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 🔄 Hermes Env Sync Guard ---');

  final templateFile = File('Notes-Hub/env.json.template');
  final activeFile = File('Notes-Hub/env.json');

  if (!templateFile.existsSync()) {
    print('❌ Notes-Hub/env.json.template not found.');
    exit(1);
  }

  if (!activeFile.existsSync()) {
    print(
        'ℹ️  Active env.json not found (Local development). Skipping sync check.');
    return;
  }

  try {
    final template =
        json.decode(templateFile.readAsStringSync()) as Map<String, dynamic>;
    final active =
        json.decode(activeFile.readAsStringSync()) as Map<String, dynamic>;

    final missingInTemplate =
        active.keys.where((k) => !template.containsKey(k)).toList();

    if (missingInTemplate.isNotEmpty) {
      print(
          '❌ ERROR: Keys found in env.json but MISSING from env.json.template:');
      for (final key in missingInTemplate) {
        print('   - $key');
      }
      print(
          '\n💡 ACTION: Update env.json.template to ensure environment parity.');
      exit(1);
    }

    print('✅ Environment template is in sync with active configuration.');
  } catch (e) {
    print('❌ Error parsing environment files: $e');
    exit(1);
  }
}
