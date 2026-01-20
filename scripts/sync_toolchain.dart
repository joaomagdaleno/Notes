import 'dart:io';
import 'dart:convert';

sealed class VersionDrift {
  final String local;
  final String locked;
  const VersionDrift(this.local, this.locked);
}

class FlutterDrift extends VersionDrift {
  const FlutterDrift(String local, String locked) : super(local, locked);
}

class DartDrift extends VersionDrift {
  const DartDrift(String local, String locked) : super(local, locked);
}

class NoDrift extends VersionDrift {
  const NoDrift(String version) : super(version, version);
}

typedef VersionCheckResult = ({VersionDrift drift, String tool, bool needsSync});

void main(List<String> args) {
  print('--- 🔧 Flutter Toolchain Sync ---');
  print('Detecting and fixing version drift...\n');

  final results = [
    _checkFlutterVersion(),
    _checkDartVersion(),
  ];

  final hasDrift = results.any((r) => r.needsSync);
  
  if (hasDrift) {
    print('\n--- 🚨 VERSION DRIFT DETECTED ---');
    for (final result in results) {
      if (result.needsSync) {
        _reportDrift(result);
      }
    }
    
    if (_shouldAutoSync(args)) {
      print('\n--- 🔄 AUTO-SYNCING TOOLCHAIN ---');
      _syncToolchain(results);
    } else {
      print('\n⚠️ Run with --sync flag to auto-fix version drift.');
      exit(1);
    }
  } else {
    print('\n✅ Toolchain versions are synchronized.');
  }

  print('\n--- 📊 VERSION SUMMARY ---');
  for (final result in results) {
    _printVersionStatus(result);
  }
}

VersionCheckResult _checkFlutterVersion() {
  final localVersion = _getLocalFlutterVersion();
  final lockedVersion = _getLockedVersion('flutter');
  
  final drift = switch ((localVersion, lockedVersion)) {
    (String local, String locked) when local != locked => 
      FlutterDrift(local, locked),
    (String version, _) => NoDrift(version),
  };

  return (drift: drift, tool: 'flutter', needsSync: drift is FlutterDrift);
}

VersionCheckResult _checkDartVersion() {
  final localVersion = _getLocalDartVersion();
  final lockedVersion = _getLockedVersion('dart');
  
  final drift = switch ((localVersion, lockedVersion)) {
    (String local, String locked) when local != locked => 
      DartDrift(local, locked),
    (String version, _) => NoDrift(version),
  };

  return (drift: drift, tool: 'dart', needsSync: drift is DartDrift);
}

String _getLocalFlutterVersion() {
  final result = Process.runSync('flutter', ['--version'], runInShell: true);
  if (result.exitCode != 0) return 'unknown';
  
  final lines = result.stdout.toString().split('\n');
  final flutterLine = lines.firstWhere(
    (line) => line.startsWith('Flutter'),
    orElse: () => '',
  );
  
  return flutterLine.replaceFirst('Flutter ', '').split(' •').first;
}

String _getLocalDartVersion() {
  final result = Process.runSync('dart', ['--version'], runInShell: true);
  if (result.exitCode != 0) return 'unknown';
  
  final lines = result.stdout.toString().split('\n');
  final dartLine = lines.firstWhere(
    (line) => line.startsWith('Dart SDK'),
    orElse: () => '',
  );
  
  return dartLine.replaceFirst('Dart SDK version: ', '').split(' ').first;
}

String _getLockedVersion(String tool) {
  final lockFile = File('toolchain.lock.json');
  if (!lockFile.existsSync()) return 'none';
  
  try {
    final lockData = json.decode(lockFile.readAsStringSync()) as Map<String, dynamic>;
    return lockData[tool] ?? 'none';
  } catch (e) {
    return 'error';
  }
}

void _reportDrift(VersionCheckResult result) {
  final drift = result.drift;
  print('🔴 ${result.tool.toUpperCase()} DRIFT:');
  print('   Local: ${drift.local}');
  print('   Locked: ${drift.locked}');
}

bool _shouldAutoSync(List<String> args) {
  return args.contains('--sync') || args.contains('-s');
}

void _syncToolchain(List<VersionCheckResult> results) {
  final lockData = <String, String>{};
  
  for (final result in results) {
    if (result.needsSync) {
      final newVersion = switch (result.drift) {
        FlutterDrift(local: String local) => local,
        DartDrift(local: String local) => local,
        NoDrift(local: String local) => local,
      };
      
      lockData[result.tool] = newVersion;
      print('✅ Updated ${result.tool} to: $newVersion');
    } else {
      lockData[result.tool] = result.drift.local;
    }
  }
  
  final lockFile = File('toolchain.lock.json');
  lockFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(lockData),
  );
  
  print('✅ toolchain.lock.json updated successfully.');
}

void _printVersionStatus(VersionCheckResult result) {
  final status = result.needsSync ? '🔴 DRIFT' : '✅ SYNCED';
  final version = result.drift.local;
  print('$status ${result.tool}: $version');
}