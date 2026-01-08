import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Windows-specific view for password recovery flow.
class FluentRecoveryView extends StatelessWidget {
  /// Creates a [FluentRecoveryView].
  const FluentRecoveryView({
    required this.currentStep,
    required this.isLoading,
    required this.errorMessage,
    required this.codeController,
    required this.passwordController,
    required this.confirmController,
    required this.formattedTime,
    required this.secondsRemaining,
    required this.userEmail,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onSubmitNewPassword,
    required this.onCancel,
    super.key,
  });

  /// The current step in the recovery flow (0: send, 1: verify, 2: reset).
  final int currentStep;

  /// Whether an operation is currently in progress.
  final bool isLoading;

  /// Error message to display, if any.
  final String? errorMessage;

  /// Controller for the verification code input.
  final TextEditingController codeController;

  /// Controller for the new password input.
  final TextEditingController passwordController;

  /// Controller for confirming the new password.
  final TextEditingController confirmController;

  /// Formatted string showing time remaining for the code.
  final String formattedTime;

  /// Number of seconds remaining before the code expires.
  final int secondsRemaining;

  /// The email address of the user recovering their password.
  final String userEmail;

  /// Callback to send a verification code.
  final VoidCallback onSendCode;

  /// Callback to verify the entered code.
  final VoidCallback onVerifyCode;

  /// Callback to submit the new password.
  final VoidCallback onSubmitNewPassword;

  /// Callback to cancel the recovery flow.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return fluent.ContentDialog(
      constraints: const BoxConstraints(maxWidth: 450),
      content: SizedBox(
        width: 400,
        child: switch (currentStep) {
          0 => _buildStep0(context),
          1 => _buildStep1(context),
          2 => _buildStep2(context),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildStep0(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recuperação de Senha',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text('Enviaremos um código de verificação para:\n$userEmail'),
        const SizedBox(height: 24),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            fluent.Button(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            fluent.FilledButton(
              onPressed: isLoading ? null : onSendCode,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: fluent.ProgressRing(strokeWidth: 2),
                    )
                  : const Text('Enviar Código'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Digite o Código',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Verifique seu email e digite o código de 6 dígitos.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Expira em: $formattedTime',
          style: TextStyle(
            color: secondsRemaining < 60 ? Colors.red : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        fluent.TextBox(
          controller: codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          placeholder: '000000',
          onSubmitted: (_) => onVerifyCode(),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            fluent.HyperlinkButton(
              onPressed: isLoading ? null : onSendCode,
              child: const Text('Reenviar código'),
            ),
            Row(
              children: [
                fluent.Button(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                fluent.FilledButton(
                  onPressed: isLoading ? null : onVerifyCode,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: fluent.ProgressRing(strokeWidth: 2),
                        )
                      : const Text('Verificar'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nova Senha',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Crie uma nova senha para suas notas bloqueadas.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        fluent.InfoLabel(
          label: 'Nova senha',
          child: fluent.PasswordBox(
            controller: passwordController,
            placeholder: 'Digite sua nova senha',
          ),
        ),
        const SizedBox(height: 16),
        fluent.InfoLabel(
          label: 'Confirmar senha',
          child: fluent.PasswordBox(
            controller: confirmController,
            placeholder: 'Confirme sua senha',
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            fluent.Button(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            fluent.FilledButton(
              onPressed: onSubmitNewPassword,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }
}
