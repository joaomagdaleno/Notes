import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_notes_flutter/services/recovery_service.dart';

/// A dialog for recovering a forgotten encryption password using 2FA.
class RecoveryDialog extends StatefulWidget {
  /// Creates a new [RecoveryDialog].
  const RecoveryDialog({
    required this.recoveryService,
    required this.onRecoveryComplete,
    super.key,
  });

  /// The recovery service to use.
  final RecoveryService recoveryService;

  /// Callback when recovery is complete with the new password.
  final ValueChanged<String> onRecoveryComplete;

  /// Shows the dialog.
  static Future<void> show(
    BuildContext context, {
    required RecoveryService recoveryService,
    required ValueChanged<String> onRecoveryComplete,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RecoveryDialog(
        recoveryService: recoveryService,
        onRecoveryComplete: onRecoveryComplete,
      ),
    );
  }

  @override
  State<RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<RecoveryDialog> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Code verification
  final _codeController = TextEditingController();
  Timer? _expirationTimer;
  int _secondsRemaining = 600; // 10 minutes

  // Step 2: New password
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _expirationTimer?.cancel();
    super.dispose();
  }

  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _errorMessage = 'O código expirou. Por favor, solicite um novo.';
        });
      }
    });
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    final minuteStr = minutes.toString().padLeft(2, '0');
    final secondStr = seconds.toString().padLeft(2, '0');
    return '$minuteStr:$secondStr';
  }

  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.recoveryService.sendVerificationCode();
      setState(() {
        _currentStep = 1;
        _secondsRemaining = 600;
      });
      _startExpirationTimer();
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'Erro ao enviar código: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.length != 6) {
      setState(() {
        _errorMessage = 'Digite o código de 6 dígitos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.recoveryService.verifyCode(
        _codeController.text,
      );

      switch (result) {
        case RecoveryResult.success:
          _expirationTimer?.cancel();
          setState(() {
            _currentStep = 2;
          });
        case RecoveryResult.invalidCode:
          setState(() {
            _errorMessage = 'Código inválido. Tente novamente.';
          });
        case RecoveryResult.codeExpired:
          setState(() {
            _errorMessage = 'O código expirou. Solicite um novo.';
            _currentStep = 0;
          });
        case RecoveryResult.notLoggedIn:
          setState(() {
            _errorMessage = 'Você precisa estar logado.';
          });
        case RecoveryResult.noRecoverySetup:
          setState(() {
            _errorMessage = 'Recuperação não configurada.';
          });
      }
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'Erro ao verificar código: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _submitNewPassword() {
    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'A senha deve ter pelo menos 6 caracteres';
      });
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = 'As senhas não coincidem';
      });
      return;
    }

    Navigator.of(context).pop();
    widget.onRecoveryComplete(_passwordController.text);
  }

  Widget _buildStep0() {
    final email = widget.recoveryService.userEmail ?? 'seu email';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recuperação de Senha',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Enviaremos um código de verificação para:\n$email',
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isLoading ? null : _sendCode,
              child: _isLoading
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

  Widget _buildStep1() {
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
          'Expira em: $_formattedTime',
          style: TextStyle(
            color: _secondsRemaining < 60
                ? Theme.of(context).colorScheme.error
                : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
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
          onSubmitted: (_) => _verifyCode(),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isLoading ? null : _sendCode,
              child: const Text('Reenviar código'),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading
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

  Widget _buildStep2() {
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
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirmar senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
            ),
          ),
          onSubmitted: (_) => _submitNewPassword(),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _submitNewPassword,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 400,
        child: switch (_currentStep) {
          0 => _buildStep0(),
          1 => _buildStep1(),
          2 => _buildStep2(),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
