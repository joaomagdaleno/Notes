# 🦅 HERMES CLI Manual

> **The Complete Guide to the Notes Hub Automation Ecosystem**

Hermes is the unified CLI for the Notes Hub development workflow. It consolidates 40+ automation scripts into a single, intelligent interface that enforces quality, security, and governance across the entire development lifecycle.

---

## 🚀 Quick Start

```bash
# Run interactive TUI menu
dart scripts/hermes.dart

# Run specific command
dart scripts/hermes.dart <command>

# Examples
dart scripts/hermes.dart doctor    # Check environment health
dart scripts/hermes.dart status    # View project dashboard
dart scripts/hermes.dart help      # Show all commands
```

---

## 📋 Command Reference

### 🩺 Environment & Health

| Command  | Description                                      |
| -------- | ------------------------------------------------ |
| `doctor` | Verify toolchain (Flutter, Dart, Git hooks)      |
| `status` | Show comprehensive project health dashboard      |
| `repair` | Self-healing: clean caches, fix formatting       |
| `lock`   | Lock toolchain versions to `toolchain.lock.json` |

### 🔐 Security & Compliance

| Command      | Description                                   |
| ------------ | --------------------------------------------- |
| `secret`     | Pre-commit secret scanner (API keys, tokens)  |
| `firewall`   | Audit Firebase/Firestore security rules       |
| `security`   | Combined: vulnerabilities + env sync          |
| `compliance` | License audit for all dependencies            |

### 📊 Quality & Metrics

| Command     | Description                                              |
| ----------- | -------------------------------------------------------- |
| `perf`      | Detect Flutter anti-patterns (Opacity, oversized builds) |
| `arch`      | Architecture layer violation detection                   |
| `economy`   | Code duplication (DRY) analysis                          |
| `stability` | Test flakiness detection                                 |
| `impact`    | Calculate PR Impact Score (A-F grading)                  |

### 📈 Observability & Trends

| Command     | Description                        |
| ----------- | ---------------------------------- |
| `pulse`     | Generate HTML health dashboard     |
| `telemetry` | Generate Mermaid trend charts      |
| `metrics`   | Collect and store project metrics  |
| `delta`     | Coverage delta vs baseline         |
| `badge`     | Generate coverage badge            |

### 🌍 Internationalization & Assets

| Command      | Description                                    |
| ------------ | ---------------------------------------------- |
| `i18n`       | Detect hardcoded strings (localization)        |
| `fidelity`   | High-resolution asset audit                    |
| `efficiency` | Asset size optimization check                  |
| `parity`     | Platform version consistency (Android/Windows) |

### 📦 Release & Governance

| Command  | Description                            |
| -------- | -------------------------------------- |
| `bump`   | Increment version (major/minor/patch)  |
| `ready`  | Deployment readiness report (Go/No-Go) |
| `bom`    | Generate Bill of Materials (SHA-256)   |
| `verify` | Verify artifact integrity against BOM  |
| `log`    | Generate automated changelog           |
| `notes`  | Generate release notes from commits    |
| `gov`    | Consolidated governance manifest       |

### 🔍 Code Analysis

| Command     | Description                                  |
| ----------- | -------------------------------------------- |
| `assurance` | Dead code + environment smoke tests          |
| `context`   | Generate AI_CONTEXT.md for AI assistants     |
| `hygiene`   | Git branch/commit hygiene audit              |
| `viz`       | Generate dependency graph visualization      |
| `predict`   | Predict next semantic version from commits   |
| `style`     | Design system / hardcoded style audit        |

### 🧪 Testing

| Command | Description                      |
| ------- | -------------------------------- |
| `e2e`   | Run Patrol E2E tests on device   |
| `a11y`  | Accessibility (a11y) guard       |
| `sync`  | Sync coverage data with vault    |

### 📚 Documentation

| Command | Description                        |
| ------- | ---------------------------------- |
| `docs`  | Generate HERMES_REGISTRY.md        |
| `env`   | Environment template sync audit    |

### 🔄 Batch Operations

| Command | Description                          |
| ------- | ------------------------------------ |
| `audit` | Run ALL project audits sequentially  |

---

## 🖥️ Interactive TUI

When you run `dart scripts/hermes.dart` without arguments, you enter the **Interactive TUI Mode**:

```text
╔══════════════════════════════════════════════╗
║             🦅 HERMES CLI v1.0.0             ║
╠══════════════════════════════════════════════╣
║                                              ║
║  1.  doctor      [Env]   Check Toolchain     ║
║  2.  status      [Audit] Project Health      ║
║  3.  repair      [Fix]   Self-Healing        ║
║  4.  ready       [Rel]   Readiness Report    ║
║  5.  secret      [Sec]   Secret Guard        ║
║  6.  firewall    [Sec]   Security Rules      ║
║  7.  impact      [Qual]  PR Impact Score     ║
║  8.  pulse       [Qual]  Health Dashboard    ║
║  9.  lock        [Env]   Lock Toolchain      ║
║  10. bom         [Rel]   Bill of Materials   ║
║  11. e2e         [Test]  E2E Patrol Test     ║
║  12. a11y        [Qual]  Accessibility Guard ║
║  13. exit                                    ║
║                                              ║
╚══════════════════════════════════════════════╝

Select an option (1-13): _
```

Simply type the number and press Enter to execute that command.

---

## 📊 PR Impact Score System

The `hermes impact` command calculates a composite score for Pull Requests, grading them from **A** (excellent) to **F** (needs attention).

### Score Components

| Factor             | Weight | What It Measures                   |
| ------------------ | ------ | ---------------------------------- |
| **Size**           | 25%    | Lines changed (smaller is better)  |
| **Coverage Delta** | 25%    | Test coverage change               |
| **Security**       | 20%    | No secrets leaked, rules passed    |
| **Documentation**  | 15%    | README/comments updated            |
| **Hygiene**        | 15%    | Commit message quality             |

### Grade Interpretation

| Grade   | Score Range | Meaning                            |
| ------- | ----------- | ---------------------------------- |
| **A**   | 90-100      | Excellent. Ship it! 🚀             |
| **B**   | 80-89       | Good. Minor improvements possible. |
| **C**   | 70-79       | Acceptable. Address feedback.      |
| **D**   | 60-69       | Below standards. Needs work.       |
| **F**   | 0-59        | Critical issues. Block merge.      |

---

## 🔄 Git Hooks Integration

Hermes integrates with **Lefthook** for local enforcement:

```yaml
# lefthook.yml
pre-commit:
  commands:
    format:
      run: dart format --set-exit-if-changed Notes-Hub/lib
    secret-guard:
      run: dart scripts/local_secret_guard.dart

pre-push:
  commands:
    analyze:
      run: flutter analyze Notes-Hub/lib
    coverage:
      run: dart scripts/calculate_coverage.dart
```

### Sync Hooks

```bash
lefthook install  # Install hooks after clone
lefthook run pre-commit  # Manual test
```

---

## 🏗️ Architecture Layers

The Hermes ecosystem operates on four layers:

```text
┌─────────────────────────────────────────────────────┐
│  INTERACTION LAYER (DX)                             │
│  • Hermes CLI • TUI • Self-Healing • Repair        │
├─────────────────────────────────────────────────────┤
│  INTELLIGENCE LAYER (Observability)                 │
│  • Metrics Vault • Visual Telemetry • Trends       │
├─────────────────────────────────────────────────────┤
│  DEFENSE LAYER (Security)                           │
│  • Secret Guard • BOM • License Audit • Firewall   │
├─────────────────────────────────────────────────────┤
│  FOUNDATION LAYER (Hygiene)                         │
│  • Environment Parity • Versioning • Formatting    │
└─────────────────────────────────────────────────────┘
```

---

## 📁 Key Files & Directories

| Path                    | Purpose                          |
| ----------------------- | -------------------------------- |
| `scripts/hermes.dart`   | Main CLI entry point             |
| `scripts/`              | All automation scripts (Dart)    |
| `lefthook.yml`          | Git hooks configuration          |
| `toolchain.lock.json`   | Locked Flutter/Dart versions     |
| `.github/workflows/`    | CI/CD pipeline definitions       |
| `HERMES_REGISTRY.md`    | Auto-generated script index      |
| `AI_CONTEXT.md`         | Context file for AI assistants   |

---

## 🆘 Troubleshooting

### "Command not found" errors

```bash
# Ensure you're in the project root
cd /path/to/Notes

# Run with explicit path
dart scripts/hermes.dart doctor
```

### Git hooks not running

```bash
# Reinstall lefthook
lefthook install --force
```

### Flutter version mismatch

```bash
# Check locked version
cat toolchain.lock.json

# Switch to correct version (using fvm or manual)
fvm use <version>
```

### Windows build issues

```bash
# Install NuGet if missing
winget install Microsoft.NuGet

# Enable native assets
flutter config --enable-native-assets

# Clean and rebuild
flutter clean
flutter pub get
```

---

## 🎯 Best Practices

1. **Run `hermes doctor` after cloning** - Verify your environment is ready.
2. **Use `hermes repair` when stuck** - It fixes most common issues automatically.
3. **Check `hermes status` before PRs** - Ensure all audits pass.
4. **Run `hermes ready` before releases** - Get a Go/No-Go decision.

---

## 📚 Further Reading

- [DEVELOPMENT.md](./DEVELOPMENT.md) - Developer onboarding guide
- [HERMES_REGISTRY.md](./HERMES_REGISTRY.md) - Complete script index
- [AI_CONTEXT.md](./AI_CONTEXT.md) - Project context for AI tools

---

## Footer

Generated by Hermes CLI v1.0.0 | Notes Hub Platform Engineering
