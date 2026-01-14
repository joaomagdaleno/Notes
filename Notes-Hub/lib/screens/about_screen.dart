import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/services/update_service.dart';
import 'package:notes_hub/utils/update_helper.dart';
import 'package:notes_hub/utils/windows_update_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The screen that displays information about the application.
class AboutScreen extends StatefulWidget {
  /// Creates a new instance of [AboutScreen].
  const AboutScreen({
    required this.packageInfo,
    super.key,
    this.debugPlatform,
    this.updateService,
  });

  /// The package information.
  final PackageInfo packageInfo;

  /// Optional platform override for testing purposes.
  /// If provided, this will be used instead of the actual platform.
  final TargetPlatform? debugPlatform;

  /// Optional update service for testing purposes.
  final UpdateService? updateService;

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final _isChecking = ValueNotifier<bool>(false);
  final _updateStatus = ValueNotifier<String>('');

  @override
  void dispose() {
    _isChecking.dispose();
    _updateStatus.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    _isChecking.value = true;
    _updateStatus.value = '';

    if (!mounted) return;
    await UpdateHelper.checkForUpdate(
      context,
      isManual: true,
      updateService: widget.updateService,
    );

    if (mounted) {
      _isChecking.value = false;
    }
  }

  Future<void> _checkForUpdateWindows() async {
    _isChecking.value = true;
    _updateStatus.value = '';
    await WindowsUpdateHelper.checkForUpdate(
      onStatusChange: (message) {
        if (mounted) _updateStatus.value = message;
      },
      onError: (message) {
        if (mounted) _updateStatus.value = message;
      },
      onNoUpdate: () {
        if (mounted) {
          _updateStatus.value = 'Você já está na versão mais recente.';
        }
      },
      onCheckFinished: () {
        if (mounted) _isChecking.value = false;
      },
      updateService: widget.updateService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = widget.debugPlatform != null
        ? widget.debugPlatform == TargetPlatform.windows
        : defaultTargetPlatform == TargetPlatform.windows;

    if (isWindows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);
    return Semantics(
      label: 'About Notes Hub',
      child: fluent.ScaffoldPage(
        header: fluent.PageHeader(
          title: const Text('Sobre'),
          leading: fluent.IconButton(
            icon: const fluent.Icon(fluent.FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        content: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            fluent.Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes Hub',
                    style: theme.typography.subtitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Versão atual: ${widget.packageInfo.version}',
                    style: theme.typography.body,
                  ),
                  const fluent.Divider(
                    style: fluent.DividerThemeData(
                      horizontalMargin: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isChecking,
                    builder: (context, isChecking, child) {
                      return Row(
                        children: [
                          fluent.FilledButton(
                            onPressed:
                                isChecking ? null : _checkForUpdateWindows,
                            child: isChecking
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: fluent.ProgressRing(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verificar Atualizações'),
                          ),
                          const SizedBox(width: 16),
                          ValueListenableBuilder<String>(
                            valueListenable: _updateStatus,
                            builder: (context, updateStatus, child) {
                              if (updateStatus.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Expanded(
                                child: Text(
                                  updateStatus,
                                  style: theme.typography.caption,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '© 2024 Google DeepMind - Advanced Agentic Coding Team',
              style: theme.typography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    return Semantics(
      label: 'About Notes Hub',
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Sobre'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Versão atual: ${widget.packageInfo.version}'),
              const SizedBox(height: 20),
              // 🎨 Palette: Using ValueListenableBuilder to rebuild only the
              // button when the `_isChecking` state changes. This is more
              // efficient than rebuilding the entire screen with `setState`.
              ValueListenableBuilder<bool>(
                valueListenable: _isChecking,
                builder: (context, isChecking, child) {
                  return ElevatedButton(
                    onPressed: isChecking ? null : _checkForUpdate,
                    child: isChecking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              key: Key('loading_indicator'),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Verificar Atualizações'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
