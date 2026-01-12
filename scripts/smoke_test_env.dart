import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 🚬 Hermes Env Smoke Test ---');

  final envFile = File('Notes-Hub/env.json');
  if (!envFile.existsSync()) {
    print('ℹ️  Notes-Hub/env.json not found. Skipping smoke test.');
    return;
  }

  try {
    final content = envFile.readAsStringSync();
    final data = json.decode(content) as Map<String, dynamic>;

    bool hasErrors = false;

    // 1. Check for missing critical keys
    final requiredKeys = ['FIREBASE_OPTIONS', 'AUTH_CONFIG', 'APP_ENV'];
    for (final key in requiredKeys) {
      if (!data.containsKey(key) || data[key].toString().isEmpty) {
        print('❌ ERROR: Critical key "$key" is missing or empty in env.json.');
        hasErrors = true;
      }
    }

    // 2. Validate Base64 encoding for specific fields
    final base64Keys = ['FIREBASE_OPTIONS', 'AUTH_CONFIG'];
    for (final key in base64Keys) {
      if (data.containsKey(key)) {
        try {
          base64.decode(data[key]);
        } catch (e) {
          print('❌ ERROR: Key "$key" contains invalid base64 data.');
          hasErrors = true;
        }
      }
    }

    if (hasErrors) {
      print('\n🔥 Env Smoke Test FAILED.');
      exit(1);
    }

    print('✅ Environment payload passed all smoke tests.');
  } catch (e) {
    print('❌ FAILED to parse env.json: $e');
    exit(1);
  }
}
