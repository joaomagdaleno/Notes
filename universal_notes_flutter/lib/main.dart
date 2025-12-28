import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/firebase_options.dart';
import 'package:universal_notes_flutter/screens/notes_screen.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';
import 'package:universal_notes_flutter/services/security_service.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/services/tracing_service.dart';
import 'package:universal_notes_flutter/styles/app_themes.dart';
import 'package:universal_notes_flutter/widgets/command_palette.dart';
import 'package:universal_notes_flutter/widgets/sync_conflict_listener.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  await runZonedGuarded(
    () async {
      debugPrint('🚀 [STARTUP] main() execution started');
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('✅ [STARTUP] WidgetsFlutterBinding initialized');

      // Initialize Tracing
      TracingService().init();
      debugPrint('✅ [STARTUP] TracingService initialized');

      // Initialize Firebase
      try {
        debugPrint('⏳ [STARTUP] Initializing Firebase...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ [STARTUP] Firebase initialized');

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // Pass all uncaught errors from the framework to Crashlytics.
          FlutterError.onError = (errorDetails) {
            unawaited(
              FirebaseCrashlytics.instance.recordFlutterFatalError(
                errorDetails,
              ),
            );
          };
          debugPrint(
            '✅ [STARTUP] Crashlytics recordFlutterFatalError configured',
          );

          // Pass all uncaught asynchronous errors that aren't handled by the
          // Flutter framework to Crashlytics
          PlatformDispatcher.instance.onError = (error, stack) {
            unawaited(
              FirebaseCrashlytics.instance.recordError(
                error,
                stack,
                fatal: true,
              ),
            );
            return true;
          };
          debugPrint('✅ [STARTUP] PlatformDispatcher.onError configured');
        }
      } on Object catch (e, stack) {
        debugPrint('❌ [STARTUP] Firebase initialization failed: $e');
        debugPrint(stack.toString());
      }

      // Windows/Desktop window setup
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        debugPrint('⏳ [STARTUP] Initializing WindowManager...');
        await windowManager.ensureInitialized();
        const windowOptions = WindowOptions(
          size: Size(800, 600),
          center: true,
          minimumSize: Size(400, 300),
        );
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
        debugPrint('✅ [STARTUP] WindowManager initialized');
      }

      // Initialize Sync Service
      try {
        debugPrint('⏳ [STARTUP] Initializing SyncService...');
        await SyncService.instance.init();
        debugPrint('✅ [STARTUP] SyncService initialized');
      } on Object catch (e, stack) {
        debugPrint('❌ [STARTUP] SyncService initialization failed: $e');
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          await FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'SyncService init failure',
          );
        }
      }

      debugPrint('🚀 [STARTUP] Running App...');
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeService()),
            StreamProvider<User?>.value(
              value: AuthService().authStateChanges,
              initialData: null,
            ),
          ],
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('🔥 [FATAL] Global runZonedGuarded error: $error');
      debugPrint(stack.toString());
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
      }
    },
  );
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates a new instance of [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt: This is a performance optimization.
    // By using the `child` property of the `Consumer`, we ensure that the
    // `AuthWrapper` and its descendants are built only once. Only the
    // `MaterialApp` is rebuilt when the theme changes, which is much more
    // efficient.
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Universal Notes',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeService.themeMode,
          home: child,
        );
      },
      child: Builder(
        builder: (materialAppContext) => CallbackShortcuts(
          bindings: {
            const SingleActivator(
              LogicalKeyboardKey.keyK,
              control: true,
            ): () => showCommandPalette(materialAppContext),
          },
          child: const SyncConflictListener(child: AuthWrapper()),
        ),
      ),
    );
  }
}

/// A wrapper that handles authentication state and navigation.
class AuthWrapper extends StatefulWidget {
  /// Creates a new [AuthWrapper].
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    unawaited(_checkBiometrics());
  }

  Future<void> _checkBiometrics() async {
    try {
      debugPrint('⏳ [AUTH] Checking biometrics/lock...');
      final security = SecurityService.instance;
      final enabled = await security.isLockEnabled();
      if (enabled) {
        final success = await security.authenticate();
        debugPrint('✅ [AUTH] Biometric result: $success');
        if (mounted) {
          setState(() {
            _isAuthenticated = success;
            _isCheckingAuth = false;
          });
        }
      } else {
        debugPrint('ℹ️ [AUTH] Lock not enabled');
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isCheckingAuth = false;
          });
        }
      }
    } on Object catch (e, stack) {
      debugPrint('❌ [AUTH] Error during biometric check: $e');
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          reason: 'Biometric check failure',
        );
      }
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              const Text('App Locked'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkBiometrics,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    // 🚀 Start: Refactored navigation flow.
    // The app no longer enforces login at startup.
    // AuthScreen is accessible via the Sidebar for sync features.
    debugPrint('✅ [NAVIGATION] Showing NotesScreen (Auth Optional)');
    return const NotesScreen();
  }
}
