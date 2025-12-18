import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/encryption_service.dart';
import 'package:universal_notes_flutter/services/recovery_service.dart';

/// A dialog to set up password recovery before enabling note encryption.
class SetupRecoveryDialog extends StatefulWidget {
  /// Creates a new [SetupRecoveryDialog].
  const SetupRecoveryDialog({
    required this.recoveryService,
    required this.password,
    super.key,
  });

  /// The recovery service to use.
  final RecoveryService recoveryService;

  /// The password that will be used to encrypt notes.
  final String password;

  /// Shows the dialog and returns true if recovery was set up successfully.
  static Future<bool> show(
    BuildContext context, {
    required RecoveryService recoveryService,
    required String password,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SetupRecoveryDialog(
        recoveryService: recoveryService,
        password: password,
      ),
    );
    return result ?? false;
  }

  @override
  State<SetupRecoveryDialog> createState() => _SetupRecoveryDialogState();
}

class _SetupRecoveryDialogState extends State<SetupRecoveryDialog> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _understood = false;

  Future<void> _setupRecovery() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Generate a recovery key
      final recoveryKey = EncryptionService.generateRecoveryKey();

      // Encrypt the recovery key with the user's password
      final encryptedRecoveryKey = await EncryptionService.encryptRecoveryKey(
        recoveryKey,
        widget.password,
      );

      // Save to Firestore
      await widget.recoveryService.saveEncryptedRecoveryKey(
        encryptedRecoveryKey,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'Erro ao configurar recuperação: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSetup = widget.recoveryService.canSetupRecovery;
    final email = widget.recoveryService.userEmail;

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
            const _StepItem(
              number: '1',
              text:
                  'Uma chave de recuperação será criada e armazenada de forma segura',
            ),
            const _StepItem(
              number: '2',
              text: 'Se você esquecer a senha, poderá recuperá-la via email',
            ),
            const _StepItem(
              number: '3',
              text:
                  'Um código de verificação será enviado para confirmar sua identidade',
            ),
            const SizedBox(height: 20),
            if (!canSetup) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
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
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
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
              value: _understood,
              onChanged: (value) {
                setState(() {
                  _understood = value ?? false;
                });
              },
              title: const Text(
                'Entendo que sem a recuperação configurada, não poderei acessar minhas notas se esquecer a senha',
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        if (!canSetup)
          TextButton(
            onPressed: () {
              // In a real app, would trigger email verification
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verifique seu email para confirmar'),
                ),
              );
            },
            child: const Text('Verificar Email'),
          )
        else
          FilledButton(
            onPressed: _understood && !_isLoading ? _setupRecovery : null,
            child: _isLoading
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
  });

  final String number;
  final String text;

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
              color: Theme.of(context).colorScheme.primary,
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
