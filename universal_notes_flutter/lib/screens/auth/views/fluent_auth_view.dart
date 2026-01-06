import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart' hide Divider, IconButton, ListTile;

/// A Windows-specific view for authentication (login and signup).
class FluentAuthView extends StatelessWidget {
  /// Creates a [FluentAuthView].
  const FluentAuthView({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.showSignUp,
    required this.isSigningInWithEmail,
    required this.isSigningUpWithEmail,
    required this.isSigningInWithGoogle,
    required this.onAuth,
    required this.onToggleMode,
    required this.onGoogleAuth,
    super.key,
  });

  /// The form key for the auth form.
  final GlobalKey<FormState> formKey;

  /// Controller for the email input field.
  final TextEditingController emailController;

  /// Controller for the password input field.
  final TextEditingController passwordController;

  /// Controller for the name input field (used in sign up).
  final TextEditingController nameController;

  /// Whether to show the sign up form instead of login.
  final bool showSignUp;

  /// Whether the email sign-in process is running.
  final bool isSigningInWithEmail;

  /// Whether the email sign-up process is running.
  final bool isSigningUpWithEmail;

  /// Whether the Google sign-in process is running.
  final bool isSigningInWithGoogle;

  /// Callback when the primary auth button is pressed.
  final VoidCallback onAuth;

  /// Callback when the user toggles between login and sign up.
  final VoidCallback onToggleMode;

  /// Callback when the Google auth button is pressed.
  final VoidCallback onGoogleAuth;

  @override
  Widget build(BuildContext context) {
    final title = showSignUp ? 'Criar Conta' : 'Entrar';
    final isEmailProcessing = isSigningInWithEmail || isSigningUpWithEmail;
    final isAnyProcessRunning = isEmailProcessing || isSigningInWithGoogle;

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
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(fluent.FluentIcons.lock),
                      const SizedBox(height: 24),
                      if (showSignUp) ...[
                        fluent.InfoLabel(
                          label: 'Nome de Exibição',
                          child: fluent.TextBox(
                            controller: nameController,
                            enabled: !isAnyProcessRunning,
                            placeholder: 'Como você quer ser chamado',
                            prefix: const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(fluent.FluentIcons.contact),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      fluent.InfoLabel(
                        label: 'Email',
                        child: fluent.TextBox(
                          controller: emailController,
                          enabled: !isAnyProcessRunning,
                          placeholder: 'seu@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),
                      fluent.InfoLabel(
                        label: 'Senha',
                        child: fluent.PasswordBox(
                          controller: passwordController,
                          enabled: !isAnyProcessRunning,
                          placeholder: 'Sua senha segura',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: fluent.FilledButton(
                          onPressed: isAnyProcessRunning ? null : onAuth,
                          child: (showSignUp
                                  ? isSigningUpWithEmail
                                  : isSigningInWithEmail)
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: fluent.ProgressRing(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Processando...'),
                                  ],
                                )
                              : Text(showSignUp ? 'Cadastrar' : 'Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      fluent.HyperlinkButton(
                        onPressed: isAnyProcessRunning ? null : onToggleMode,
                        child: Text(
                          showSignUp
                              ? 'Já tem uma conta? Entre aqui'
                              : 'Não tem conta? Crie uma agora',
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: fluent.Divider(),
                      ),
                      const Text('Ou entre com'),
                      const SizedBox(height: 16),
                      Center(
                        child: fluent.HoverButton(
                          onPressed: isAnyProcessRunning ? null : onGoogleAuth,
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
                              child: isSigningInWithGoogle
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: fluent.ProgressRing(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Entrando...'),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.network(
                                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                                          width: 18,
                                          height: 18,
                                          errorBuilder: (ctx, err, stack) =>
                                              const Icon(
                                            fluent.FluentIcons.chrome_back,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Continuar com Google',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
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
}
