import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main(List<String> args) async {
  print('--- Hermes BOM Generator ---');

  if (args.isEmpty) {
    print('Usage: dart generate_bom.dart <artifacts_dir>');
    exit(1);
  }

  final dir = Directory(args[0]);
  if (!dir.existsSync()) {
    print('❌ Directory not found: ${args[0]}');
    exit(1);
  }

  final bom = <String, dynamic>{
    'timestamp': DateTime.now().toIso8601String(),
    'artifacts': [],
  };

  final files = dir.listSync(recursive: true).whereType<File>();
  for (final file in files) {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final name = file.path.split(Platform.pathSeparator).last;

    bom['artifacts'].add({
      'name': name,
      'size': file.lengthSync(),
      'sha256': hash,
    });

    print('📄 Hashed: $name ($hash)');
  }

  final bomFile = File('bom.json');
  bomFile.writeAsStringSync(json.encode(bom));
  print('\n✅ BOM generated: bom.json');
}
