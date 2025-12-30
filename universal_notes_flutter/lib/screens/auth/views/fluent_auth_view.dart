import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart' hide ListTile, Divider, IconButton;

class FluentAuthView extends StatelessWidget {
  const FluentAuthView({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.showSignUp,
    required this.isProcessing,
    required this.onAuth,
    required this.onToggleMode,
    required this.onGoogleAuth,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final bool showSignUp;
  final bool isProcessing;
  final VoidCallback onAuth;
  final VoidCallback onToggleMode;
  final VoidCallback onGoogleAuth;

  @override
  Widget build(BuildContext context) {
    final title = showSignUp ? 'Criar Conta' : 'Entrar';

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
                          controller: emailController,
                          placeholder: 'seu@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),
                      fluent.InfoLabel(
                        label: 'Senha',
                        child: fluent.PasswordBox(
                          controller: passwordController,
                          placeholder: 'Sua senha segura',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: fluent.FilledButton(
                          onPressed: isProcessing ? null : onAuth,
                          child: isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: fluent.ProgressRing(strokeWidth: 2),
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
                        child: Text(
                          showSignUp
                              ? 'Já tem uma conta? Entre aqui'
                              : 'Não tem conta? Crie uma agora',
                        ),
                        onPressed: onToggleMode,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: fluent.Divider(),
                      ),
                      const Text('Ou entre com'),
                      const SizedBox(height: 16),
                      Center(
                        child: fluent.HoverButton(
                          onPressed: onGoogleAuth,
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
                                    style: TextStyle(fontWeight: FontWeight.w500),
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
