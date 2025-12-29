import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A simple logger to record startup events to a file.
/// This is useful for debugging issues that occur before the UI is rendered.
class StartupLogger {
  static File? _logFile;
  static final StringBuffer _buffer = StringBuffer();
  static bool _initialized = false;

  /// Initializes the logger by creating or clearing the log file.
  static Future<void> init() async {
    try {
      if (_initialized) return;

      final docsDir = await getApplicationDocumentsDirectory();
      _logFile = File(
        '${docsDir.path}${Platform.pathSeparator}startup_log.txt',
      );

      // Clear previous logs or start fresh
      if (await _logFile!.exists()) {
        await _logFile!.delete();
      }

      _initialized = true;
      await log('🚀 StartupLogger initialized at ${docsDir.path}');
    } on Exception catch (e) {
      debugPrint('❌ Failed to initialize StartupLogger: $e');
    }
  }

  /// Logs a message to the file and console.
  static Future<void> log(String message) async {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    
    // Print to console
    debugPrint(logMessage);

    // Buffer locally
    _buffer.writeln(logMessage);

    // Write to file if initialized
    if (_initialized && _logFile != null) {
      try {
        await _logFile!.writeAsString(
          '$logMessage\n',
          mode: FileMode.append,
          flush: true,
        );
      } on Exception catch (e) {
        debugPrint('❌ Failed to write to log file: $e');
      }
    }
  }

  /// Gets the full log content.
  static String getLogs() {
    return _buffer.toString();
  }
}
