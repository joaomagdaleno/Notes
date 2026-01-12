import 'dart:io';

void main() {
  print('--- 🧱 Hermes Security Rule Auditor ---');

  bool firestoreOk = _validateRules('Note-Hub/firestore.rules');
  bool storageOk = _validateRules('Note-Hub/storage.rules');

  if (!firestoreOk || !storageOk) {
    print('\n🚨 SECURITY AUDIT FAILED: Insecure rules detected.');
    exit(1);
  } else {
    print('\n✅ Security rules validation passed.');
  }
}

bool _validateRules(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    print('ℹ️  SKIPPING: $path not found.');
    return true;
  }

  final content = file.readAsStringSync();
  bool secure = true;

  if (content.contains('allow read, write: if true')) {
    print('❌ CRITICAL: $path allows public read/write access!');
    secure = false;
  }

  if (content.contains('allow write: if request.auth != null') &&
      !content.contains('allow write: if true')) {
    print('✅ INFO: $path requires authentication for writes. Good.');
  }

  return secure;
}
