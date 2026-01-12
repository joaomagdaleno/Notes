import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A Material Design view for password recovery flow.
class MaterialRecoveryView extends StatelessWidget {
  /// Creates a [MaterialRecoveryView].
  const MaterialRecoveryView({
    required this.currentStep,
    required this.isLoading,
    required this.errorMessage,
    required this.codeController,
    required this.passwordController,
    required this.confirmController,
    required this.formattedTime,
    required this.secondsRemaining,
    required this.userEmail,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onSendCode,
    required this.onVerifyCode,
    required this.onSubmitNewPassword,
    required this.onCancel,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirm,
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

  /// Whether to obscure the password text.
  final bool obscurePassword;

  /// Whether to obscure the confirm password text.
  final bool obscureConfirm;

  /// Callback to send a verification code.
  final VoidCallback onSendCode;

  /// Callback to verify the entered code.
  final VoidCallback onVerifyCode;

  /// Callback to submit the new password.
  final VoidCallback onSubmitNewPassword;

  /// Callback to cancel the recovery flow.
  final VoidCallback onCancel;

  /// Callback to toggle password visibility.
  final VoidCallback onToggleObscurePassword;

  /// Callback to toggle confirm password visibility.
  final VoidCallback onToggleObscureConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isLoading ? null : onSendCode,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
            color: secondsRemaining < 60
                ? Theme.of(context).colorScheme.error
                : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            counterText: '',
            border: OutlineInputBorder(),
            hintText: '000000',
          ),
          onSubmitted: (_) => onVerifyCode(),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: isLoading ? null : onSendCode,
              child: const Text('Reenviar código'),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isLoading ? null : onVerifyCode,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
        TextField(
          controller: passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleObscurePassword,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: confirmController,
          obscureText: obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirmar senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggleObscureConfirm,
            ),
          ),
          onSubmitted: (_) => onSubmitNewPassword(),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onSubmitNewPassword,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }
}
