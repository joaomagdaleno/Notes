import 'dart:io';

void main() {
  print('--- 🏛️ Hermes Workflow Governance Auditor ---');

  final workflowDir = Directory('.github/workflows');
  if (!workflowDir.existsSync()) return;

  final workflows = workflowDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.yml'));

  bool hasIssues = false;

  for (final file in workflows) {
    final name = file.path.split(Platform.pathSeparator).last;
    final content = file.readAsStringSync();

    print('Auditing $name...');

    // 1. Check for Timeout
    if (!content.contains('timeout-minutes:')) {
      print('   ⚠️ MISSING: timeout-minutes (Potential runner hang)');
      hasIssues = true;
    }

    // 2. Check for broad permissions
    if (content.contains('permissions: write-all')) {
      print(
          '   ❌ DANGER: permissions: write-all used! Use granular permissions.');
      hasIssues = true;
    }

    // 3. Check for specific commit hashes or @vX tags (best practice)
    if (content.contains('@master') || content.contains('@main')) {
      print(
          '   ⚠️ WARNING: Action pinned to master/main branch. Use major version tags.');
      hasIssues = true;
    }

    // 4. Check for concurrency
    if (!content.contains('concurrency:')) {
      print(
          '   ℹ️ INFO: No concurrency group defined. Multiple runs might conflict.');
    }
  }

  if (!hasIssues) {
    print('\n✅ Workflow Governance Audit PASSED.');
  } else {
    print('\n⚠️ Workflow Governance Audit completed with warnings.');
    // We don't fail yet, but we could if we want to enforce strictly.
  }
}
