import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    final title = _showSignUp ? 'Criar Conta' : 'Entrar';

    return fluent.FluentTheme(
      data: fluent.FluentThemeData.light(),
      child: Builder(
        builder: (context) => fluent.ScaffoldPage(
          header: fluent.PageHeader(
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
                      const Icon(fluent.FluentIcons.lock),
                      const SizedBox(height: 24),
                      if (_showSignUp) ...[
                        fluent.InfoLabel(
                          label: 'Nome de Exibição',
                          child: fluent.TextBox(
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
                      fluent.InfoLabel(
                        label: 'Email',
                        child: fluent.TextBox(
                          controller: _emailController,
                          placeholder: 'seu@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),
                      fluent.InfoLabel(
                        label: 'Senha',
                        child: fluent.PasswordBox(
                          controller: _passwordController,
                          placeholder: 'Sua senha segura',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: fluent.FilledButton(
                          onPressed: (_isSigningIn || _isSigningUp)
                              ? null
                              : () => unawaited(_handleEmailAuth()),
                          child: _isSigningIn || _isSigningUp
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child:
                                          fluent.ProgressRing(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Processando...'),
                                  ],
                                )
                              : Text(_showSignUp ? 'Cadastrar' : 'Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      fluent.HyperlinkButton(
                        child: Text(
                          _showSignUp
                              ? 'Já tem uma conta? Entre aqui'
                              : 'Não tem conta? Crie uma agora',
                        ),
                        onPressed: () =>
                            setState(() => _showSignUp = !_showSignUp),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      const Text('Ou entre com'),
                      const SizedBox(height: 16),
                      Center(
                        child: fluent.HoverButton(
                          onPressed: () => unawaited(_handleGoogleAuth()),
                          builder: (context, states) {
                            final theme = fluent.FluentTheme.of(context);
                            return fluent.Card(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              backgroundColor: states.isHovered
                                  ? theme.resources.subtleFillColorTertiary
                                  : theme.resources.subtleFillColorSecondary,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                                    width: 18,
                                    height: 18,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Icon(fluent.FluentIcons.chrome_back, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continuar com Google',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    final title = _showSignUp ? 'Criar Conta' : 'Entrar';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48),
                  const SizedBox(height: 24),
                  if (_showSignUp) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome de Exibição',
                        hintText: 'Como você quer ser chamado',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Sua senha segura',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
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
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Processando...'),
                              ],
                            )
                          : Text(_showSignUp ? 'Cadastrar' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    child: Text(
                      _showSignUp
                          ? 'Já tem uma conta? Entre aqui'
                          : 'Não tem conta? Crie uma agora',
                    ),
                    onPressed: () =>
                        setState(() => _showSignUp = !_showSignUp),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  const Text('Ou entre com'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(_handleGoogleAuth()),
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (ctx, err, stack) =>
                          const Icon(Icons.g_mobiledata, size: 18),
                    ),
                    label: const Text('Continuar com Google'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
