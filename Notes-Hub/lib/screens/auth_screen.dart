import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:notes_hub/screens/auth/views/fluent_auth_view.dart';
import 'package:notes_hub/screens/auth/views/material_auth_view.dart';
import 'package:notes_hub/services/auth_service.dart';

/// The authentication screen with platform-adaptive UI.
class AuthScreen extends StatefulWidget {
  /// Creates an auth screen.
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();

  bool _isSigningInWithEmail = false;
  bool _isSigningUpWithEmail = false;
  bool _isSigningInWithGoogle = false;
  bool _showSignUp = false;

  Future<void> _showErrorFluent(Object e) async {
    if (!mounted) return;
    await fluent.displayInfoBar(
      context,
      builder: (context, close) {
        return fluent.InfoBar(
          title: const Text('Erro'),
          content: Text(e.toString()),
          action: fluent.IconButton(
            icon: const Icon(fluent.FluentIcons.clear),
            onPressed: close,
          ),
          severity: fluent.InfoBarSeverity.error,
        );
      },
    );
  }

  Future<void> _showErrorMaterial(Object e) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (_isSigningInWithEmail ||
        _isSigningUpWithEmail ||
        _isSigningInWithGoogle) {
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        if (_showSignUp) {
          _isSigningUpWithEmail = true;
        } else {
          _isSigningInWithEmail = true;
        }
      });

      try {
        if (_showSignUp) {
          await _authService.createUserWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
            _nameController.text,
          );
        } else {
          await _authService.signInWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
        }
        if (!mounted) return;

        if (_showSignUp) {
          if (defaultTargetPlatform == TargetPlatform.windows) {
            await fluent.displayInfoBar(
              context,
              builder: (context, close) {
                return fluent.InfoBar(
                  title: const Text('Verifique seu e-mail'),
                  content: const Text(
                    'Enviamos um link de confirmação para o seu e-mail. '
                    'Por favor, verifique sua caixa de entrada.',
                  ),
                  severity: fluent.InfoBarSeverity.warning,
                  onClose: close,
                );
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Verifique seu e-mail. Enviamos um link de confirmação.',
                ),
              ),
            );
          }
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } on Exception catch (e) {
        if (defaultTargetPlatform == TargetPlatform.windows) {
          await _showErrorFluent(e);
        } else {
          await _showErrorMaterial(e);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSigningInWithEmail = false;
            _isSigningUpWithEmail = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isSigningInWithGoogle = true;
    });
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (result != null) {
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        await _showErrorFluent(e);
      } else {
        await _showErrorMaterial(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningInWithGoogle = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentAuthView(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        nameController: _nameController,
        showSignUp: _showSignUp,
        isSigningInWithEmail: _isSigningInWithEmail,
        isSigningUpWithEmail: _isSigningUpWithEmail,
        isSigningInWithGoogle: _isSigningInWithGoogle,
        isGoogleProcessing: _isSigningInWithGoogle,
        onAuth: _handleEmailAuth,
        onToggleMode: () => setState(() => _showSignUp = !_showSignUp),
        onGoogleAuth: _handleGoogleAuth,
      );
    } else {
      return MaterialAuthView(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        nameController: _nameController,
        showSignUp: _showSignUp,
        isSigningInWithEmail: _isSigningInWithEmail,
        isSigningUpWithEmail: _isSigningUpWithEmail,
        isSigningInWithGoogle: _isSigningInWithGoogle,
        isGoogleProcessing: _isSigningInWithGoogle,
        onAuth: _handleEmailAuth,
        onToggleMode: () => setState(() => _showSignUp = !_showSignUp),
        onGoogleAuth: _handleGoogleAuth,
      );
    }
  }
}
