# 🛰️ Hermes CI/CD Map

*Automatic mapping of pipeline logic and job dependencies.*

## 📄 build-and-package.yml
### ⚡ Triggers
```yaml
on:
  workflow_call:
```
### 👷 Jobs
- **build_windows**
- **build_android**

---
## 📄 build.yml
### ⚡ Triggers
```yaml
on:
  push:
    branches:
      - dev
      - beta
      - main
    tags:
      - 'v*'
  pull_request:
    branches:
      - dev
      - beta

concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true
```
### 👷 Jobs
- **quality_gate**
- **build**
- **prerelease**
- **release**

---
## 📄 dashboard.yml
### ⚡ Triggers
```yaml
on:
  workflow_run:
    workflows: ["Build & Release"]
    types: [completed]
    branches: [main, dev, beta]
```
### 👷 Jobs
- **publish**

---
## 📄 labeler-workflow.yml
### ⚡ Triggers
```yaml
on:
- pull_request_target
```
### 👷 Jobs
- **labeler**

---
## 📄 prerelease.yml
### ⚡ Triggers
```yaml
on:
  workflow_call:
```
### 👷 Jobs
- **pre-release**

---
## 📄 quality-gate.yml
### ⚡ Triggers
```yaml
on:
  workflow_call:
    inputs:
      min_coverage:
        description: 'Minimum code coverage percentage'
        required: false
        default: '80'
        type: string
```
### 👷 Jobs
- **check-changes**
- **static-analysis**
- **functional-tests**
- **report-results**

---
## 📄 release.yml
### ⚡ Triggers
```yaml
on:
  workflow_call:
```
### 👷 Jobs
- **release**

---
