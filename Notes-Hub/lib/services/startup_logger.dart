import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A simple logger to record startup events to a file.
/// This is useful for debugging issues that occur before the UI is rendered.
class StartupLogger {
  static File? _logFile;
  static final StringBuffer _buffer = StringBuffer();
  static bool _initialized = false;
  static Future<void> _lock = Future.value();

  /// Initializes the logger by creating or clearing the log file.
  static Future<void> init() async {
    try {
      if (_initialized) return;

      final docsDir = await getApplicationDocumentsDirectory();
      _logFile = File(
        '${docsDir.path}${Platform.pathSeparator}startup_log.txt',
      );

      // Clear previous logs or start fresh
      if (_logFile!.existsSync()) {
        try {
          _logFile!.deleteSync();
        } on Exception catch (e) {
          debugPrint('⚠️ Could not delete old log file: $e');
        }
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

    // Print to console (always safe)
    debugPrint(logMessage);

    // Buffer locally (always safe)
    _buffer.writeln(logMessage);

    // Enqueue file write to ensure sequential, non-overlapping access
    return _lock = _lock.then((_) async {
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
    }).catchError((dynamic e) {
      debugPrint('⚠️ StartupLogger queue error: $e');
    });
  }

  /// Gets the full log content.
  static String getLogs() {
    return _buffer.toString();
  }
}
