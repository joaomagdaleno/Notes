import 'package:flutter/material.dart';

class MaterialAuthView extends StatelessWidget {
  const MaterialAuthView({
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
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48),
                  const SizedBox(height: 24),
                  if (showSignUp) ...[
                    TextFormField(
                      controller: nameController,
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
                    controller: emailController,
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
                    controller: passwordController,
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
                      onPressed: isProcessing ? null : onAuth,
                      child: isProcessing
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
                          : Text(showSignUp ? 'Cadastrar' : 'Entrar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    child: Text(
                      showSignUp
                          ? 'Já tem uma conta? Entre aqui'
                          : 'Não tem conta? Crie uma agora',
                    ),
                    onPressed: onToggleMode,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  const Text('Ou entre com'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onGoogleAuth,
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
