import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:universal_notes_flutter/screens/auth/views/fluent_auth_view.dart';
import 'package:universal_notes_flutter/screens/auth/views/material_auth_view.dart';
import 'package:universal_notes_flutter/services/auth_service.dart';

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

  bool _isSigningIn = false;
  bool _isSigningUp = false;
  bool _isGoogleProcessing = false;
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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        if (_showSignUp) {
          _isSigningUp = true;
        } else {
          _isSigningIn = true;
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
            _isSigningIn = false;
            _isSigningUp = false;
          });
        }
      }
    }
  }

  Future<void> _handleGoogleAuth() async {
    setState(() {
      _isGoogleProcessing = true;
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
          _isGoogleProcessing = false;
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
        isProcessing: _isSigningIn || _isSigningUp,
        isGoogleProcessing: _isGoogleProcessing,
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
        isProcessing: _isSigningIn || _isSigningUp,
        isGoogleProcessing: _isGoogleProcessing,
        onAuth: _handleEmailAuth,
        onToggleMode: () => setState(() => _showSignUp = !_showSignUp),
        onGoogleAuth: _handleGoogleAuth,
      );
    }
  }

}
