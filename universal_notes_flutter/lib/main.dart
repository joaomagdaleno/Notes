import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/firebase_options.dart';
import 'package:universal_notes_flutter/screens/notes_screen.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';
import 'package:universal_notes_flutter/services/security_service.dart';
import 'package:universal_notes_flutter/services/startup_logger.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/services/tracing_service.dart';
import 'package:universal_notes_flutter/styles/app_themes.dart';
import 'package:universal_notes_flutter/widgets/command_palette.dart';
import 'package:universal_notes_flutter/widgets/sync_conflict_listener.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const AppBootstrap());
    },
    (error, stack) {
      debugPrint('🔥 [FATAL] Global runZonedGuarded error: $error');
      debugPrint(stack.toString());
      unawaited(StartupLogger.log('🔥 [FATAL] Global error: $error'));
      unawaited(StartupLogger.log(stack.toString()));
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        unawaited(
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
        );
      }
    },
  );
}

/// Bootstrap widget that handles async initialization and shows a splash
/// screen.
class AppBootstrap extends StatefulWidget {
  /// Creates a new instance of [AppBootstrap].
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _errorMessage;
  String _currentStep = 'Starting...';

  @override
  void initState() {
    super.initState();
    unawaited(_initializeApp());
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize StartupLogger first
      await StartupLogger.init();
      await StartupLogger.log('🚀 App initialization started');

      // Update UI
      _updateStep('Initializing Tracing...');
      TracingService().init();
      await StartupLogger.log('✅ TracingService initialized');

      // Initialize Firebase
      _updateStep('Initializing Firebase...');
      await StartupLogger.log('⏳ Initializing Firebase...');
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await StartupLogger.log('✅ Firebase initialized');

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          FlutterError.onError = (errorDetails) {
            unawaited(
              FirebaseCrashlytics.instance
                  .recordFlutterFatalError(errorDetails),
            );
          };
          PlatformDispatcher.instance.onError = (error, stack) {
            unawaited(
              FirebaseCrashlytics.instance
                  .recordError(error, stack, fatal: true),
            );
            return true;
          };
          await StartupLogger.log('✅ Crashlytics configured');
        }
      } on Exception catch (e) {
        await StartupLogger.log('❌ Firebase initialization failed: $e');
        // Continue without Firebase on desktop
      }

      // Windows/Desktop window setup
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        _updateStep('Initializing Window...');
        await StartupLogger.log('⏳ Initializing WindowManager...');
        try {
          await windowManager.ensureInitialized();
          const windowOptions = WindowOptions(
            size: Size(1280, 800),
            center: true,
            backgroundColor: Colors.white,
            skipTaskbar: false,
            titleBarStyle: TitleBarStyle.normal,
          );
          await windowManager.waitUntilReadyToShow(windowOptions, () async {
            await windowManager.show();
            await windowManager.focus();
          });
          await StartupLogger.log('✅ WindowManager initialized');
        } on Exception catch (e) {
          await StartupLogger.log('❌ WindowManager initialization failed: $e');
          // Continue anyway
        }
      }

      // Initialize sqflite FFI for desktop platforms
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        _updateStep('Initializing Database...');
        await StartupLogger.log('⏳ Initializing sqflite FFI...');
        try {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          await StartupLogger.log('✅ sqflite FFI initialized');
        } on Exception catch (e) {
          await StartupLogger.log('❌ sqflite FFI initialization failed: $e');
          // This is critical for desktop, but let's continue to show error
        }
      }

      // Initialize Sync Service
      _updateStep('Initializing Sync Service...');
      await StartupLogger.log('⏳ Initializing SyncService...');
      try {
        await SyncService.instance.init();
        await StartupLogger.log('✅ SyncService initialized');
      } on Exception catch (e, stack) {
        await StartupLogger.log('❌ SyncService initialization failed: $e');
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          await FirebaseCrashlytics.instance.recordError(
            e,
            stack,
            reason: 'SyncService init failure',
          );
        }
        // Continue anyway
      }

      await StartupLogger.log('🚀 App initialization complete, launching UI');
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } on Exception catch (e, stack) {
      await StartupLogger.log('🔥 FATAL: App initialization failed: $e');
      await StartupLogger.log(stack.toString());
      if (mounted) {
        setState(() {
          _errorMessage =
              'Initialization failed: $e\n\nCheck startup_log.txt for details.';
        });
      }
    }
  }

  void _updateStep(String step) {
    if (mounted) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    unawaited(StartupLogger.log(
        '🎨 [BUILD] AppBootstrap.build called - '
        '_isInitialized=$_isInitialized, _errorMessage=$_errorMessage',
    ));
    if (_errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitialized = false;
                        _currentStep = 'Retrying...';
                      });
                      unawaited(_initializeApp());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_currentStep, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }
    unawaited(
      StartupLogger.log('🎨 [BUILD] Returning MultiProvider with MyApp'),
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
    );
  }
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates a new instance of [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [BUILD] MyApp.build called');
    unawaited(StartupLogger.log('🎨 [BUILD] MyApp.build called'));
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
    } on Exception catch (e, stack) {
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
    debugPrint(
      '🎨 [BUILD] AuthWrapper.build called - '
      '_isCheckingAuth=$_isCheckingAuth, _isAuthenticated=$_isAuthenticated',
    );
    unawaited(StartupLogger.log(
      '🎨 [BUILD] AuthWrapper.build called - '
      '_isCheckingAuth=$_isCheckingAuth, _isAuthenticated=$_isAuthenticated',
    ));

    if (_isCheckingAuth) {
      unawaited(
        StartupLogger.log('🎨 [BUILD] AuthWrapper showing loading spinner'),
      );
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

    debugPrint('✅ [NAVIGATION] Showing NotesScreen (Auth Optional)');
    unawaited(StartupLogger.log('✅ [NAVIGATION] Returning NotesScreen widget'));
    return const NotesScreen();
  }
}
