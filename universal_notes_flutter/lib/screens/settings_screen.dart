import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';

/// The screen that displays the application settings.
class SettingsScreen extends StatefulWidget {
  /// Creates a new instance of [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
        children: [
          fluent.ListTile.selectable(
            title: const Text('Sobre'),
            leading: const fluent.Icon(fluent.FluentIcons.info),
            onPressed: _packageInfo == null
                ? null
                : () async {
                    await Navigator.of(context).push(
                      fluent.FluentPageRoute<void>(
                        builder: (context) => MaterialApp(
                          title: 'Sobre',
                          home: AboutScreen(packageInfo: _packageInfo!),
                          debugShowCheckedModeBanner: false,
                        ),
                      ),
                    );
                  },
            trailing: _packageInfo == null
                ? const fluent.ProgressRing(
                    strokeWidth: 2,
                  )
                : null,
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
          ListTile(
            title: const Text('Sobre'),
            leading: const Icon(Icons.info_outline),
            onTap: _packageInfo == null
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            AboutScreen(packageInfo: _packageInfo!),
                      ),
                    );
                  },
            trailing: _packageInfo == null
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
