import 'dart:io';

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args[0] : 'Notes-Hub/coverage/lcov.info';
  final minCoverage = args.length > 1 ? double.tryParse(args[1]) ?? 80.0 : 80.0;

  final file = File(lcovPath);
  if (!file.existsSync()) {
    print('❌ Coverage file not found at: $lcovPath');
    exit(1);
  }

  final lines = file.readAsLinesSync();
  var totalLF = 0;
  var totalLH = 0;

  for (final line in lines) {
    if (line.startsWith('LF:')) {
      totalLF += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      totalLH += int.parse(line.substring(3));
    }
  }

  if (totalLF == 0) {
    print('❌ No lines found in coverage report.');
    exit(1);
  }

  final coverage = (totalLH / totalLF) * 100;
  print('--- Coverage Summary ---');
  print('Total Lines Found (LF): $totalLF');
  print('Total Lines Hit (LH): $totalLH');
  print('Total Project Coverage: ${coverage.toStringAsFixed(2)}%');
  print('Required Minimum: ${minCoverage.toStringAsFixed(2)}%');

  // Output for GITHUB_OUTPUT
  final githubOutput = Platform.environment['GITHUB_OUTPUT'];
  if (githubOutput != null) {
    File(githubOutput).writeAsStringSync(
      'percentage=${coverage.toStringAsFixed(2)}\n',
      mode: FileMode.append,
    );
  }

  if (coverage < minCoverage) {
    print('\n❌ FAILED: Coverage is below the required threshold!');
    exit(1);
  } else {
    print('\n✅ PASSED: Coverage is above threshold.');

    // Generate JSON for Vault
    final coverageData =
        '{"percentage": ${coverage.toStringAsFixed(2)}, "lines_found": $totalLF, "lines_hit": $totalLH}';
    File('coverage.json').writeAsStringSync(coverageData);
    print('📦 Generated vault artifact: coverage.json');

    exit(0);
  }
}
