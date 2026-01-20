# CI/CD Pipeline Documentation

## Workflow Overview

```
build.yml (Main Orchestrator)
    ├── quality-gate.yml (Tests & Analysis)
    │       ├── static-analysis (Code quality)
    │       ├── functional-tests (Unit tests)
    │       └── report-results (PR summary)
    ├── build-and-package.yml (Builds)
    │       ├── build_windows (Windows installer)
    │       └── build_android (APK generation)
    └── (prerelease/release jobs)
```

## Trigger Conditions

| Event | Branches | Quality Gate | Build | Release |
|-------|----------|--------------|-------|---------|
| Push | dev, beta, main | ✅ | ✅ | ✅ |
| Tag | v* | ✅ | ✅ | ✅ |
| PR | dev, beta | ✅ | ❌ | ❌ |

## Environment Configuration

### Version Management
- **Flutter**: 3.38.6 (locked in `toolchain.lock.json`)
- **Dart**: 3.10.7
- **Java**: 17

### Version Sync
```bash
# Sync local toolchain with CI
dart scripts/sync_toolchain.dart --sync

# Check for drift
dart scripts/sync_toolchain.dart
```

## Build Optimization

### Caching Strategy
| Cache | Key | Restore Keys |
|-------|-----|--------------|
| Flutter | `flutter-3.38.6` | `flutter-*` |
| Pub | `{os}-pub-{hash}` | `{os}-pub-*` |
| Gradle | `{os}-gradle-{hash}` | `{os}-gradle-*` |
| Build Runner | `{os}-build-runner-{hash}` | `{os}-build-*` |
| Inno Setup | `inno-setup-6.2.2` | N/A |

### Artifact Retention
| Artifact | Retention | Compression |
|----------|-----------|-------------|
| Changelog | 7 days | Level 9 |
| Windows Installer | 30 days | Default |
| APK (per ABI) | 30 days | Level 9 |
| Debug Symbols | 7 days | Level 9 |
| Version Info | 7 days | Default |

## Quality Gates

### Path Filtering
Quality gate skips unnecessary jobs based on changed paths:
- **Code changes** (`Notes-Hub/lib/**`, `test/**`): Full analysis
- **CI changes** (`.github/workflows/**`): Static analysis only
- **Documentation** (`.md`, `docs/**`): Skipped

### Required Checks
- ✅ Flutter analyze (no fatal infos)
- ✅ Dart format check
- ✅ Coverage ≥ 80%
- ✅ OSV vulnerability scan
- ✅ TruffleHog secret scan

## Troubleshooting

### Common Issues

**Build fails with "version mismatch"**
```bash
dart scripts/sync_toolchain.dart --sync
```

**APK build fails on signing**
Verify secrets are configured:
- `UPLOAD_SIGNING_KEY`
- `UPLOAD_STORE_PASSWORD`
- `UPLOAD_KEY_PASSWORD`
- `UPLOAD_KEY_ALIAS`

**Tests timeout**
Check `dart_test.yaml` for timeout configuration

### Debug Commands
```bash
# Run quality gate locally
dart scripts/run_parallel_audits.dart

# Verify build environment
dart scripts/hermes_doctor.dart

# Test smoke test
dart scripts/smoke_test_build.dart
```

## Performance Targets

| Metric | Target | Actual |
|--------|--------|--------|
| Quality Gate | < 5 min | ~2-3 min |
| Windows Build | < 20 min | ~15-18 min |
| Android Build | < 15 min | ~10-12 min |
| Full Pipeline | < 30 min | ~20-25 min |

## Security

### Secrets Required
- `FIREBASE_OPTIONS_DART_B64`
- `AUTH_CONFIG_DART_B64`
- `GOOGLE_SERVICES_JSON_BASE64`
- `GOOGLE_SERVICE_INFO`
- `UPLOAD_SIGNING_KEY` (Android)
- `UPLOAD_*` (Android signing)

### Security Scans
- TruffleHog: Secrets in commits
- OSV Scanner: Dependency vulnerabilities
- Manual: Secret expiry watchdog

## Adding New Workflows

Use `workflow_call` for reusable workflows:

```yaml
jobs:
  my-job:
    uses: ./.github/workflows/template.yml
    with:
      input: value
    secrets: inherit
```