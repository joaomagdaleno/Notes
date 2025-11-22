import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/coverage_report_screen.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'package:universal_notes_flutter/utils/windows_update_helper.dart';

/// The screen that displays information about the application.
class AboutScreen extends StatefulWidget {
  /// Creates a new instance of [AboutScreen].
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _currentVersion = '...';
  bool _isChecking = false;
  String _updateStatus = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadVersion());
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _currentVersion = packageInfo.version;
    });
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
    });

    await UpdateHelper.checkForUpdate(context, isManual: true);

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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    return fluent.ScaffoldPage(
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
            Text('Versão atual: $_currentVersion'),
            const SizedBox(height: 20),
            if (_isChecking)
              const fluent.ProgressRing(),
            if (!_isChecking)
              fluent.FilledButton(
                onPressed: _checkForUpdateWindows,
                child: const Text('Verificar Atualizações'),
              ),
            const SizedBox(height: 20),
            if (!_isChecking)
              fluent.FilledButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoverageReportScreen(),
                    ),
                  );
                },
                child: const Text('Ver Relatório de Cobertura'),
              ),
            if (_updateStatus.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_updateStatus, textAlign: TextAlign.center),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Versão atual: $_currentVersion'),
            const SizedBox(height: 20),
            if (_isChecking)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _checkForUpdate,
                child: const Text('Verificar Atualizações'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CoverageReportScreen(),
                    ),
                  );
                },
                child: const Text('Ver Relatório de Cobertura'),
              ),
          ],
        ),
      ),
    );
  }
}
