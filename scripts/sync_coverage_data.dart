import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart sync_coverage_data.dart <pull|push> [target_branch]');
    exit(1);
  }

  final action = args[0];
  String branch = args.length > 1 ? args[1] : _getCurrentBranch();

  // Normalize branch name if triggered by PR (e.g., refs/heads/main -> main)
  branch = branch.replaceAll('refs/heads/', '');
  print('--- 🔄 Hermes Coverage Vault Sync ($action) ---');
  print('Target Branch Vault: $branch');

  final vaultBranches = ['main', 'dev', 'beta', 'teste-notes'];

  // If branch is not a vault candidate (e.g. feature/foo), map it to 'dev' for PULL (baseline comparison)
  // BUT for PUSH, we only push if it IS a vault branch.
  String vaultPath = branch;
  if (!vaultBranches.contains(branch)) {
    if (action == 'pull') {
      print('ℹ️  Feature branch detected. Using "dev" as baseline vault.');
      vaultPath = 'dev';
    } else {
      print('🚫 Skipping PUSH: Feature branches do not persist coverage data.');
      return;
    }
  }

  if (action == 'pull') {
    _pullBaseline(vaultPath);
  } else if (action == 'push') {
    _pushNewData(vaultPath);
  } else {
    print('❌ Invalid action. Use pull or push.');
    exit(1);
  }
}

String _getCurrentBranch() {
  final result = Process.runSync('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (result.exitCode == 0) {
    return result.stdout.toString().trim();
  }
  return 'unknown';
}

void _pullBaseline(String vaultBranch) {
  print('📥 Pulling baseline from code-vault (branch: $vaultBranch)...');

  // We use git show to extract the file without checking out the branch
  // Format: git show origin/coverage-data:data/<branch>/coverage.json
  final remotePath = 'origin/coverage-data:data/$vaultBranch/coverage.json';
  final result = Process.runSync('git', ['show', remotePath]);

  if (result.exitCode == 0) {
    File('coverage_baseline.json').writeAsStringSync(result.stdout.toString());
    print('✅ Baseline downloaded: coverage_baseline.json');
  } else {
    print(
        '⚠️  Baseline not found in vault (First run?). Assuming 0% coverage.');
    // Create dummy baseline
    File('coverage_baseline.json')
        .writeAsStringSync('{"total_coverage": 0.0, "files": {}}');
  }
}

void _pushNewData(String vaultBranch) {
  print('📤 Pushing new data to code-vault (branch: $vaultBranch)...');

  final coverageFile = File('coverage.json');
  if (!coverageFile.existsSync()) {
    print('❌ coverage.json not found. Run tests first.');
    exit(1);
  }

  // 1. Create a safe temporary directory
  final tempDir = Directory.systemTemp.createTempSync('hermes_vault_');
  print('   Temp workspace: ${tempDir.path}');

  try {
    // 2. Clone the coverage-data branch specifically
    print('   Cloning coverage-data...');
    final repoUrl = _getRemoteUrl();
    _runGit(
        ['clone', '--branch', 'coverage-data', '--single-branch', repoUrl, '.'],
        tempDir.path);

    // 3. Prepare target directory
    final targetDir = Directory('${tempDir.path}/data/$vaultBranch');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    // 4. Update data
    print('   Updating metrics...');
    coverageFile.copySync('${targetDir.path}/coverage.json');

    // 5. Commit and Push
    _runGit(['config', 'user.name', 'Hermes Governance Guard'], tempDir.path);
    _runGit(['config', 'user.email', 'hermes@notes-hub.com'], tempDir.path);

    _runGit(['add', '.'], tempDir.path);

    final status = _runGit(['status', '--porcelain'], tempDir.path);
    if (status.isEmpty) {
      print('   No changes to coverage data.');
    } else {
      _runGit([
        'commit',
        '-m',
        'chore(vault): update coverage for $vaultBranch [skip ci]'
      ], tempDir.path);
      _runGit(['push'], tempDir.path);
      print('✅ Code Vault updated successfully.');
    }
  } catch (e) {
    print('❌ Failed to push to vault: $e');
    exit(1);
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

String _getRemoteUrl() {
  final result =
      Process.runSync('git', ['config', '--get', 'remote.origin.url']);
  if (result.exitCode == 0) {
    return result.stdout.toString().trim();
  }
  // Fallback for CI environments using GITHUB_TOKEN
  final token = Platform.environment['GITHUB_TOKEN'];
  final repo = Platform.environment['GITHUB_REPOSITORY']; // e.g. user/repo
  if (token != null && repo != null) {
    return 'https://x-access-token:$token@github.com/$repo.git';
  }
  throw Exception('Could not determine remote URL.');
}

String _runGit(List<String> args, String workingDir) {
  final result = Process.runSync('git', args, workingDirectory: workingDir);
  if (result.exitCode != 0) {
    throw Exception(
        'Git command failed: git ${args.join(' ')}\n${result.stderr}');
  }
  return result.stdout.toString().trim();
}
