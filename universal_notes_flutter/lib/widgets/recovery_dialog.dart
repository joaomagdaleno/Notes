import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:universal_notes_flutter/services/recovery_service.dart';
import 'package:universal_notes_flutter/widgets/recovery/fluent_recovery_view.dart';
import 'package:universal_notes_flutter/widgets/recovery/material_recovery_view.dart';

/// A dialog for recovering a forgotten encryption password using 2FA.
///
/// This widget acts as a controller, managing state and logic,
/// while delegating the UI to platform-specific view widgets.
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
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return fluent.showDialog<void>(
        context: context,
        builder: (context) => RecoveryDialog(
          recoveryService: recoveryService,
          onRecoveryComplete: onRecoveryComplete,
        ),
      );
    } else {
      return showDialog<void>(
        context: context,
        builder: (context) => RecoveryDialog(
          recoveryService: recoveryService,
          onRecoveryComplete: onRecoveryComplete,
        ),
      );
    }
  }

  @override
  State<RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<RecoveryDialog> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final _codeController = TextEditingController();
  Timer? _expirationTimer;
  int _secondsRemaining = 600;

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
    _expirationTimer?.cancel();
    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = 'O código expirou. Por favor, solicite um novo.';
          });
        }
      }
    });
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.recoveryService.sendVerificationCode();
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _secondsRemaining = 600;
        });
        _startExpirationTimer();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao enviar código: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

      if (mounted) {
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
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao verificar código: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final userEmail = widget.recoveryService.userEmail ?? 'seu email';

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentRecoveryView(
        currentStep: _currentStep,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        codeController: _codeController,
        passwordController: _passwordController,
        confirmController: _confirmController,
        formattedTime: _formattedTime,
        secondsRemaining: _secondsRemaining,
        userEmail: userEmail,
        onSendCode: _sendCode,
        onVerifyCode: _verifyCode,
        onSubmitNewPassword: _submitNewPassword,
        onCancel: () => Navigator.of(context).pop(),
      );
    } else {
      return MaterialRecoveryView(
        currentStep: _currentStep,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        codeController: _codeController,
        passwordController: _passwordController,
        confirmController: _confirmController,
        formattedTime: _formattedTime,
        secondsRemaining: _secondsRemaining,
        userEmail: userEmail,
        obscurePassword: _obscurePassword,
        obscureConfirm: _obscureConfirm,
        onSendCode: _sendCode,
        onVerifyCode: _verifyCode,
        onSubmitNewPassword: _submitNewPassword,
        onCancel: () => Navigator.of(context).pop(),
        onToggleObscurePassword: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onToggleObscureConfirm: () =>
            setState(() => _obscureConfirm = !_obscureConfirm),
      );
    }
  }
}
