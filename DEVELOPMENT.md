# 🚀 Hermes Development Guide

Welcome to the Hermes ecosystem. This guide is automatically generated to stay in sync with the repository.

## 🛠️ Required Toolchain
To ensure environment parity, please use these exact versions:
- **Flutter:** `Flutter 3.38.2 â€¢ channel stable â€¢ https://github.com/flutter/flutter.git`
- **Dart:** `Dart SDK version: 3.10.0 (stable) (Thu Nov 6 05:24:55 2025 -0800) on "windows_x64"`

> [!TIP]
> Run `dart scripts/hermes_doctor.dart` to verify your local setup.

## 💻 Essential Commands
| Command | Purpose |
| --- | --- |
| `dart scripts/hermes_doctor.dart` | Verify local dev environment |
| `dart scripts/hermes_status.dart` | Full project health check |
| `dart scripts/lock_toolchain.dart` | Update toolchain lockfile |
| `flutter pub get` | Sync dependencies in Notes-Hub |

## 🛰️ CI/CD Pipeline
The pipeline is mapped in [CI_MAP.md](./CI_MAP.md). Key workflows include Build & Release, Quality Gate, and PR Labeler.

