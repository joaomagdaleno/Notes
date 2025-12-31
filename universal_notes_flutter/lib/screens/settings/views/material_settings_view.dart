import 'package:flutter/material.dart';

/// Material Design view for SettingsScreen
class MaterialSettingsView extends StatelessWidget {
  final bool isLoadingInfo;
  final VoidCallback onOpenAbout;

  const MaterialSettingsView({
    super.key,
    required this.isLoadingInfo,
    required this.onOpenAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Sobre'),
            leading: const Icon(Icons.info_outline),
            onTap: isLoadingInfo ? null : onOpenAbout,
            trailing: isLoadingInfo
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
