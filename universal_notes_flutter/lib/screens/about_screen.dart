import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'package:universal_notes_flutter/utils/windows_update_helper.dart';

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
  bool _isChecking = false;
  String _updateStatus = '';

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
    });

    if (!mounted) return;
    await UpdateHelper.checkForUpdate(
      context,
      isManual: true,
      updateService: widget.updateService,
    );

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _checkForUpdateWindows() async {
    setState(() {
      _isChecking = true;
      _updateStatus = '';
    });
    await WindowsUpdateHelper.checkForUpdate(
      onStatusChange: (message) {
        if (mounted) setState(() => _updateStatus = message);
      },
      onError: (message) {
        if (mounted) setState(() => _updateStatus = message);
      },
      onNoUpdate: () {
        if (mounted) {
          setState(
            () => _updateStatus = 'Você já está na versão mais recente.',
          );
        }
      },
      onCheckFinished: () {
        if (mounted) setState(() => _isChecking = false);
      },
      updateService: widget.updateService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWindows = widget.debugPlatform != null
        ? widget.debugPlatform == TargetPlatform.windows
        : Platform.isWindows;

    if (isWindows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    return Semantics(
      label: 'About Universal Notes',
      child: fluent.ScaffoldPage(
        header: fluent.PageHeader(
          title: const Text('Sobre'),
          leading: fluent.CommandBar(
            overflowBehavior: fluent.CommandBarOverflowBehavior.noWrap,
            primaryItems: [
              fluent.CommandBarButton(
                icon: const fluent.Icon(fluent.FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Versão atual: ${widget.packageInfo.version}'),
              const SizedBox(height: 20),
              fluent.FilledButton(
                onPressed: _isChecking ? null : _checkForUpdateWindows,
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: fluent.ProgressRing(
                          key: Key('loading_indicator'),
                        ),
                      )
                    : const Text('Verificar Atualizações'),
              ),
              if (_updateStatus.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(_updateStatus, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    return Semantics(
      label: 'About Universal Notes',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sobre'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Versão atual: ${widget.packageInfo.version}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isChecking ? null : _checkForUpdate,
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          key: Key('loading_indicator'),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Verificar Atualizações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
