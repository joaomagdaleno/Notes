import 'dart:io';
import 'dart:convert';

void main() {
  print('--- 📖 Hermes Onboarding Generator ---');

  final sb = StringBuffer();
  sb.writeln('# 🚀 Hermes Development Guide\n');
  sb.writeln(
      'Welcome to the Hermes ecosystem. This guide is automatically generated to stay in sync with the repository.\n');

  // 1. Toolchain info
  final lockFile = File('toolchain.lock.json');
  if (lockFile.existsSync()) {
    final lockData = json.decode(lockFile.readAsStringSync());
    sb.writeln('## 🛠️ Required Toolchain');
    sb.writeln(
        'To ensure environment parity, please use these exact versions:');
    sb.writeln('- **Flutter:** `${lockData['flutter']}`');
    sb.writeln('- **Dart:** `${lockData['dart']}`');
    sb.writeln(
        '\n> [!TIP]\n> Run `dart scripts/hermes_doctor.dart` to verify your local setup.\n');
  }

  // 2. Local Commands
  sb.writeln('## 💻 Essential Commands');
  sb.writeln('| Command | Purpose |');
  sb.writeln('| --- | --- |');
  sb.writeln(
      '| `dart scripts/hermes_doctor.dart` | Verify local dev environment |');
  sb.writeln(
      '| `dart scripts/hermes_status.dart` | Full project health check |');
  sb.writeln(
      '| `dart scripts/lock_toolchain.dart` | Update toolchain lockfile |');
  sb.writeln('| `flutter pub get` | Sync dependencies in Notes-Hub |\n');

  // 3. CI/CD Overview
  final ciMapFile = File('CI_MAP.md');
  if (ciMapFile.existsSync()) {
    sb.writeln('## 🛰️ CI/CD Pipeline');
    sb.writeln(
        'The pipeline is mapped in [CI_MAP.md](./CI_MAP.md). Key workflows include Build & Release, Quality Gate, and PR Labeler.\n');
  }

  File('DEVELOPMENT.md').writeAsStringSync(sb.toString());
  print('✅ Development guide generated: DEVELOPMENT.md');
}
