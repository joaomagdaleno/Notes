import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:universal_notes_flutter/services/auth_service.dart';

/// The authentication screen redesigned with Fluent UI.
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
  bool _showSignUp = false;

  Future<void> _showError(Object e) async {
    if (!mounted) return;
    await displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: const Text('Erro'),
          content: Text(e.toString()),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: InfoBarSeverity.error,
        );
      },
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
        if (mounted) {
          if (_showSignUp) {
            await displayInfoBar(
              context,
              builder: (context, close) {
                return InfoBar(
                  title: const Text('Verifique seu e-mail'),
                  content: const Text(
                    'Enviamos um link de confirmação para o seu e-mail. '
                    'Por favor, verifique sua caixa de entrada.',
                  ),
                  severity: InfoBarSeverity.warning,
                  onClose: close,
                );
              },
            );
          }
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } on Exception catch (e) {
        await _showError(e);
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
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (result != null) {
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      await _showError(e);
    }
  }


  @override
  Widget build(BuildContext context) {
    final title = _showSignUp ? 'Criar Conta' : 'Entrar';
    
    return FluentTheme(
      data: FluentThemeData.light(),
      child: ScaffoldPage(
        header: PageHeader(
          title: Text(title),
        ),
        content: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.lock),
                    const SizedBox(height: 24),
                    if (_showSignUp) ...[
                      InfoLabel(
                        label: 'Nome de Exibição',
                        child: TextBox(
                          controller: _nameController,
                          placeholder: 'Como você quer ser chamado',
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    InfoLabel(
                      label: 'Email',
                      child: TextBox(
                        controller: _emailController,
                        placeholder: 'seu@email.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InfoLabel(
                      label: 'Senha',
                      child: PasswordBox(
                        controller: _passwordController,
                        placeholder: 'Sua senha segura',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_isSigningIn || _isSigningUp)
                            ? null
                            : () => unawaited(_handleEmailAuth()),
                        child: _isSigningIn || _isSigningUp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: ProgressRing(),
                              )
                            : Text(_showSignUp ? 'Cadastrar' : 'Entrar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    HyperlinkButton(
                      child: Text(
                        _showSignUp
                            ? 'Já tem uma conta? Entre aqui'
                            : 'Não tem conta? Crie uma agora',
                      ),
                      onPressed: () => setState(() => _showSignUp = !_showSignUp),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    const Text('Ou entre com'),
                    const SizedBox(height: 16),
                    Center(
                      child: Button(
                        onPressed: () => unawaited(_handleGoogleAuth()),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.chrome_back),
                            SizedBox(width: 8),
                            Text('Google'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
