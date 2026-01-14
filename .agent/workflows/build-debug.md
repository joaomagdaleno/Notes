---
description: Build the application in debug mode for Windows with maximum performance
---

# Fast Windows Debug Build

This workflow provides the fastest way to build and run the application on Windows, leveraging parallel compilation and skipping redundant steps.

## Steps

// turbo

1. Build the Windows application with maximum CPU parallelism

   ```powershell
   flutter build windows --debug -- /m
   ```

2. Run the application without re-running pub get (fastest for iterative changes)

   ```powershell
   flutter run -d windows --no-pub
   ```

## Optimization Tips

- **Antivirus Exclusion**: Ensure your project directory and the Flutter SDK directory are excluded from real-time antivirus scanning. This can speed up builds by up to 50%.
- **Incremental Builds**: Avoid running `flutter clean` unless you encounter strange build errors. Most changes are handled incrementally.
- **Parallel MSBuild**: The `/m` (or `/maxcpucount`) flag tells MSBuild to use all available CPU cores for compilation.
