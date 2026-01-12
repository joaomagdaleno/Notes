import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:notes_hub/screens/about_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The screen that displays the application settings.
class SettingsScreen extends StatefulWidget {
  /// Creates a new instance of [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ⚡ Bolt: Cache PackageInfo to avoid repeated platform calls.
  // Fetched once in initState for instant access later.
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    unawaited(_initPackageInfo());
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentUI(context);
    } else {
      return _buildMaterialUI(context);
    }
  }

  Widget _buildFluentUI(BuildContext context) {
    return fluent.ScaffoldPage(
      header: const fluent.PageHeader(
        title: Text('Configurações'),
      ),
      content: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          fluent.Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                fluent.ListTile(
                  title: const Text('Sobre'),
                  leading: const fluent.Icon(fluent.FluentIcons.info),
                  onPressed: _packageInfo == null
                      ? null
                      : () {
                          unawaited(
                            Navigator.of(context).push(
                              fluent.FluentPageRoute<void>(
                                builder: (context) =>
                                    AboutScreen(packageInfo: _packageInfo!),
                              ),
                            ),
                          );
                        },
                  trailing: _packageInfo == null
                      ? const fluent.ProgressRing(
                          strokeWidth: 2,
                        )
                      : const fluent.Icon(fluent.FluentIcons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          _MaterialSettingsItem(packageInfo: _packageInfo),
        ],
      ),
    );
  }
}

class _MaterialSettingsItem extends StatelessWidget {
  const _MaterialSettingsItem({required this.packageInfo});
  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Sobre'),
      leading: const Icon(Icons.info_outline),
      onTap: packageInfo == null
          ? null
          : () {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        AboutScreen(packageInfo: packageInfo!),
                  ),
                ),
              );
            },
      trailing: packageInfo == null
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}
