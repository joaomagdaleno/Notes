import 'package:flutter/material.dart';

class MaterialSetupRecoveryView extends StatelessWidget {
  const MaterialSetupRecoveryView({
    required this.canSetup,
    required this.email,
    required this.understood,
    required this.isLoading,
    required this.errorMessage,
    required this.onUnderstoodChanged,
    required this.onSetupRecovery,
    required this.onCancel,
    required this.onVerifyEmail,
    super.key,
  });

  final bool canSetup;
  final String? email;
  final bool understood;
  final bool isLoading;
  final String? errorMessage;
  final ValueChanged<bool?> onUnderstoodChanged;
  final VoidCallback onSetupRecovery;
  final VoidCallback onCancel;
  final VoidCallback onVerifyEmail;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Recuperação de Senha'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configure a recuperação para não perder acesso às suas notas caso esqueça a senha.',
                      style: TextStyle(color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Como funciona:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _StepItem(
              number: '1',
              text: 'Uma chave de recuperação será criada e armazenada de forma segura',
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
            _StepItem(
              number: '2',
              text: 'Se você esquecer a senha, poderá recuperá-la via email',
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
            _StepItem(
              number: '3',
              text: 'Um código de verificação será enviado para confirmar sua identidade',
              primaryColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            if (!canSetup) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Você precisa verificar seu email ($email) para configurar a recuperação.',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A recuperação usará seu email: $email',
                        style: TextStyle(color: Colors.green[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            CheckboxListTile(
              value: understood,
              onChanged: onUnderstoodChanged,
              title: const Text(
                'Entendo que sem a recuperação configurada, não poderei acessar minhas notas se esquecer a senha',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        if (!canSetup)
          TextButton(
            onPressed: onVerifyEmail,
            child: const Text('Verificar Email'),
          )
        else
          FilledButton(
            onPressed: understood && !isLoading ? onSetupRecovery : null,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Configurar Recuperação'),
          ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.number,
    required this.text,
    required this.primaryColor,
  });

  final String number;
  final String text;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
