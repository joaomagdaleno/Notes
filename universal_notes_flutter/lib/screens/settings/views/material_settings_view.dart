import 'package:flutter/material.dart';

/// Material Design view for SettingsScreen
class MaterialSettingsView extends StatelessWidget {
  /// Creates a [MaterialSettingsView].
  const MaterialSettingsView({
    required this.isLoadingInfo,
    required this.onOpenAbout,
    super.key,
  });

  /// Whether the app is currently loading package information.
  final bool isLoadingInfo;
  /// Callback for opening the about screen.
  final VoidCallback onOpenAbout;

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
