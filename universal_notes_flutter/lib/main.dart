import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/firebase_options.dart';
import 'package:universal_notes_flutter/screens/auth_screen.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  TracingService().init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
  }

  await SyncService.instance.init();

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
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates a new instance of [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ⚡ Bolt: By passing the theme-independent widgets to the `child` parameter
    // of the Consumer, we ensure that they are built only once. The `builder`
    // will be called again on theme changes, but the `child` widget instance
    // will be reused, preventing unnecessary rebuilds of a large widget
    // subtree.
    // Impact: Reduces widget rebuilds in the main tree significantly on theme
    // change.
    // Measurement: Verified with Flutter DevTools' "Highlight Repaints".
    return Consumer<ThemeService>(
      child: const SyncConflictListener(
        child: AuthWrapper(),
      ),
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Universal Notes',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeService.themeMode,
          home: CallbackShortcuts(
            bindings: {
              const SingleActivator(
                LogicalKeyboardKey.keyK,
                control: true,
              ): () =>
                  showCommandPalette(context),
            },
            child: child!,
          ),
        );
      },
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
    final security = SecurityService.instance;
    final enabled = await security.isLockEnabled();
    if (enabled) {
      final success = await security.authenticate();
      if (mounted) {
        setState(() {
          _isAuthenticated = success;
          _isCheckingAuth = false;
        });
      }
    } else {
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
    final firebaseUser = context.watch<User?>();

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

    if (firebaseUser != null) {
      return const NotesScreen();
    }
    return const AuthScreen();
  }
}
