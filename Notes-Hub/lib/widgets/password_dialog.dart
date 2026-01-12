import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A dialog for entering or creating a password to lock/unlock notes.
class PasswordDialog extends StatefulWidget {
  /// Creates a new [PasswordDialog].
  const PasswordDialog({
    required this.title,
    this.isCreatingPassword = false,
    this.onForgotPassword,
    super.key,
  });

  /// The title to display in the dialog.
  final String title;

  /// Whether this dialog is for creating a new password (shows confirmation).
  final bool isCreatingPassword;

  /// Callback when user taps "Forgot password".
  final VoidCallback? onForgotPassword;

  /// Shows the dialog and returns the entered password, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    bool isCreatingPassword = false,
    VoidCallback? onForgotPassword,
  }) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return fluent.showDialog<String>(
        context: context,
        builder: (context) => PasswordDialog(
          title: title,
          isCreatingPassword: isCreatingPassword,
          onForgotPassword: onForgotPassword,
        ),
      );
    } else {
      return showDialog<String>(
        context: context,
        builder: (context) => PasswordDialog(
          title: title,
          isCreatingPassword: isCreatingPassword,
          onForgotPassword: onForgotPassword,
        ),
      );
    }
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _rememberForSession = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite uma senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentDialog(context);
    } else {
      return _buildMaterialDialog(context);
    }
  }

  Widget _buildFluentDialog(BuildContext context) {
    return fluent.ContentDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            fluent.InfoLabel(
              label: 'Senha',
              child: fluent.PasswordBox(
                controller: _passwordController,
                placeholder: 'Digite sua senha',
                revealMode: _obscurePassword
                    ? fluent.PasswordRevealMode.hidden
                    : fluent.PasswordRevealMode.visible,
              ),
            ),
            if (widget.isCreatingPassword) ...[
              const SizedBox(height: 16),
              fluent.InfoLabel(
                label: 'Confirmar senha',
                child: fluent.PasswordBox(
                  controller: _confirmController,
                  placeholder: 'Confirme sua senha',
                  revealMode: _obscureConfirm
                      ? fluent.PasswordRevealMode.hidden
                      : fluent.PasswordRevealMode.visible,
                ),
              ),
            ],
            const SizedBox(height: 16),
            fluent.Checkbox(
              checked: _rememberForSession,
              onChanged: (value) {
                setState(() {
                  _rememberForSession = value ?? false;
                });
              },
              content: const Text('Lembrar durante esta sessão'),
            ),
            if (!widget.isCreatingPassword && widget.onForgotPassword != null)
              Align(
                alignment: Alignment.centerLeft,
                child: fluent.HyperlinkButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onForgotPassword!();
                  },
                  child: const Text('Esqueci minha senha'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        fluent.Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        fluent.FilledButton(
          onPressed: _submit,
          child: Text(widget.isCreatingPassword ? 'Criar' : 'Desbloquear'),
        ),
      ],
    );
  }

  Widget _buildMaterialDialog(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Senha',
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
              validator: _validatePassword,
              onFieldSubmitted:
                  widget.isCreatingPassword ? null : (_) => _submit(),
            ),
            if (widget.isCreatingPassword) ...[
              const SizedBox(height: 16),
              TextFormField(
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
                validator: _validateConfirmPassword,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _rememberForSession,
              onChanged: (value) {
                setState(() {
                  _rememberForSession = value ?? false;
                });
              },
              title: const Text('Lembrar durante esta sessão'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (!widget.isCreatingPassword && widget.onForgotPassword != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onForgotPassword!();
                  },
                  child: const Text('Esqueci minha senha'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.isCreatingPassword ? 'Criar' : 'Desbloquear'),
        ),
      ],
    );
  }
}
