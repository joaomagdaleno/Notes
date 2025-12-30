import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

/// A Windows-specific view for setting up password recovery.
class FluentSetupRecoveryView extends StatelessWidget {
  /// Creates a [FluentSetupRecoveryView].
  const FluentSetupRecoveryView({
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

  /// Whether recovery can be set up (usually depends on email verification).
  final bool canSetup;

  /// The user's email address.
  final String? email;

  /// Whether the user has confirmed they understand the consequences.
  final bool understood;

  /// Whether an operation is currently in progress.
  final bool isLoading;

  /// Error message to display, if any.
  final String? errorMessage;

  /// Callback when the understood checkbox is changed.
  final ValueChanged<bool?> onUnderstoodChanged;

  /// Callback to proceed with setting up recovery.
  final VoidCallback onSetupRecovery;

  /// Callback to cancel the setup process.
  final VoidCallback onCancel;

  /// Callback to initiate email verification.
  final VoidCallback onVerifyEmail;

  @override
  Widget build(BuildContext context) {
    return fluent.ContentDialog(
      title: const Text('Configurar Recuperação de Senha'),
      constraints: const BoxConstraints(maxWidth: 500),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const fluent.InfoBar(
            title: Text('Importante'),
            content: Text(
              'Configure a recuperação para não perder acesso às suas notas '
              'caso esqueça a senha.',
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
            text: 'Uma chave de recuperação será criada e armazenada de forma '
                'segura',
            accentColor: fluent.FluentTheme.of(context).accentColor,
          ),
          _StepItem(
            number: '2',
            text: 'Se você esquecer a senha, poderá recuperá-la via email',
            accentColor: fluent.FluentTheme.of(context).accentColor,
          ),
          _StepItem(
            number: '3',
            text: 'Um código de verificação será enviado para confirmar sua '
                'identidade',
            accentColor: fluent.FluentTheme.of(context).accentColor,
          ),
          const SizedBox(height: 20),
          if (!canSetup) ...[
            fluent.InfoBar(
              title: const Text('Verificação necessária'),
              content: Text(
                'Você precisa verificar seu email ($email) para configurar a '
                'recuperação.',
              ),
              severity: fluent.InfoBarSeverity.warning,
            ),
            const SizedBox(height: 16),
          ] else ...[
            fluent.InfoBar(
              title: const Text('Pronto'),
              content: Text('A recuperação usará seu email: $email'),
              severity: fluent.InfoBarSeverity.success,
            ),
            const SizedBox(height: 16),
          ],
          fluent.Checkbox(
            checked: understood,
            onChanged: onUnderstoodChanged,
            content: const Text(
              'Entendo que sem a recuperação configurada, não poderei acessar '
              'minhas notas se esquecer a senha',
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        fluent.Button(
          onPressed: onCancel,
          child: const Text('Cancelar'),
        ),
        if (!canSetup)
          fluent.Button(
            onPressed: onVerifyEmail,
            child: const Text('Verificar Email'),
          )
        else
          fluent.FilledButton(
            onPressed: understood && !isLoading ? onSetupRecovery : null,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: fluent.ProgressRing(strokeWidth: 2),
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
    required this.accentColor,
  });

  final String number;
  final String text;
  final Color accentColor;

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
              color: accentColor,
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
