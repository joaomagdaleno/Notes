import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main(List<String> args) async {
  print('--- Hermes Integrity Verifier ---');

  if (args.length < 2) {
    print('Usage: dart verify_integrity.dart <bom_json_path> <artifacts_dir>');
    exit(1);
  }

  final bomFile = File(args[0]);
  final dir = Directory(args[1]);

  if (!bomFile.existsSync()) {
    print('❌ BOM file not found: ${args[0]}');
    exit(1);
  }

  if (!dir.existsSync()) {
    print('❌ Directory not found: ${args[1]}');
    exit(1);
  }

  final bom = json.decode(bomFile.readAsStringSync());
  final List artifacts = bom['artifacts'];

  int verifiedCount = 0;
  int failedCount = 0;

  for (final item in artifacts) {
    final name = item['name'];
    final expectedHash = item['sha256'];
    final file = File('${dir.path}${Platform.pathSeparator}$name');

    if (!file.existsSync()) {
      print('⚠️ Missing: $name');
      continue;
    }

    final bytes = await file.readAsBytes();
    final actualHash = sha256.convert(bytes).toString();

    if (actualHash == expectedHash) {
      print('✅ Verified: $name');
      verifiedCount++;
    } else {
      print('❌ FAILED: $name');
      print('   Expected: $expectedHash');
      print('   Actual:   $actualHash');
      failedCount++;
    }
  }

  print('\n--- Integrity Summary ---');
  print('Total artifacts in BOM: ${artifacts.length}');
  print('Verified: $verifiedCount');
  print('Failed:   $failedCount');

  if (failedCount > 0) {
    exit(1);
  }
}
