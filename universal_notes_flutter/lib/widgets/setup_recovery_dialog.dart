import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/services/encryption_service.dart';
import 'package:universal_notes_flutter/services/recovery_service.dart';
import 'package:universal_notes_flutter/widgets/recovery/fluent_setup_recovery_view.dart';
import 'package:universal_notes_flutter/widgets/recovery/material_setup_recovery_view.dart';

/// A dialog to set up password recovery before enabling note encryption.
///
/// This widget acts as a controller, managing state and logic,
/// while delegating the UI to platform-specific view widgets.
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
    bool? result;
    if (defaultTargetPlatform == TargetPlatform.windows) {
      result = await fluent.showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SetupRecoveryDialog(
          recoveryService: recoveryService,
          password: password,
        ),
      );
    } else {
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => SetupRecoveryDialog(
          recoveryService: recoveryService,
          password: password,
        ),
      );
    }
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
      final recoveryKey = EncryptionService.generateRecoveryKey();
      final encryptedRecoveryKey = await EncryptionService.encryptRecoveryKey(
        recoveryKey,
        widget.password,
      );
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

  void _verifyEmail() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      fluent.displayInfoBar(
        context,
        builder: (context, close) => fluent.InfoBar(
          title: const Text('Email enviado'),
          content: const Text('Verifique seu email para confirmar'),
          severity: fluent.InfoBarSeverity.info,
          onClose: close,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifique seu email para confirmar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSetup = widget.recoveryService.canSetupRecovery;
    final email = widget.recoveryService.userEmail;

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return FluentSetupRecoveryView(
        canSetup: canSetup,
        email: email,
        understood: _understood,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onUnderstoodChanged: (value) => setState(() => _understood = value ?? false),
        onSetupRecovery: _setupRecovery,
        onCancel: () => Navigator.of(context).pop(false),
        onVerifyEmail: _verifyEmail,
      );
    } else {
      return MaterialSetupRecoveryView(
        canSetup: canSetup,
        email: email,
        understood: _understood,
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onUnderstoodChanged: (value) => setState(() => _understood = value ?? false),
        onSetupRecovery: _setupRecovery,
        onCancel: () => Navigator.of(context).pop(false),
        onVerifyEmail: _verifyEmail,
      );
    }
  }
}
