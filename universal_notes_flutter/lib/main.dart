import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/firebase_options.dart';
import 'package:universal_notes_flutter/screens/auth_screen.dart';
import 'package:universal_notes_flutter/screens/notes_screen.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/styles/app_themes.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Universal Notes',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeService.themeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return const NotesScreen();
    }
    return const AuthScreen();
  }
}
