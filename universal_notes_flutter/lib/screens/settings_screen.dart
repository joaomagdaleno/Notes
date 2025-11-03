import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'about_screen.dart';
import 'dart:io' show Platform;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:universal_notes_flutter/utils/windows_update_helper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
      header: const fluent.PageHeader(
        title: Text('Configurações'),
      ),
      content: ListView(
        children: [
          fluent.Button(
            style: fluent.ButtonStyle(
              backgroundColor: fluent.WidgetStateProperty.all(fluent.Colors.transparent),
              padding: fluent.WidgetStateProperty.all(EdgeInsets.zero),
            ),
            onPressed: () {
              Navigator.push(
                context,
                fluent.FluentPageRoute(builder: (_) => const AboutScreen()),
              );
            },
            child: const fluent.ListTile(
              leading: fluent.Icon(fluent.FluentIcons.info),
              title: Text('Sobre'),
            ),
          ),
          fluent.Button(
            style: fluent.ButtonStyle(
              backgroundColor: fluent.WidgetStateProperty.all(fluent.Colors.transparent),
              padding: fluent.WidgetStateProperty.all(EdgeInsets.zero),
            ),
            onPressed: () => WindowsUpdateHelper.checkForUpdate(context),
            child: const fluent.ListTile(
              leading: fluent.Icon(fluent.FluentIcons.update_restore),
              title: Text('Verificar atualizações'),
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
          ListTile(
            title: const Text('Sobre'),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Verificar atualizações'),
            leading: const Icon(Icons.update),
            onTap: () => UpdateHelper.checkForUpdate(context, isManual: true),
          ),
        ],
      ),
    );
  }
}
