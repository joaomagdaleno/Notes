import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Material Design view for AboutScreen
/// Material Design view for AboutScreen
class MaterialAboutView extends StatelessWidget {
  /// Creates a [MaterialAboutView].
  const MaterialAboutView({
    required this.packageInfo,
    required this.isChecking,
    required this.onCheckUpdate,
    super.key,
  });

  /// The information about the package.
  final PackageInfo packageInfo;
  /// Whether the app is currently checking for updates.
  final bool isChecking;
  /// Callback for checking updates.
  final VoidCallback onCheckUpdate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Versão atual: ${packageInfo.version}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isChecking ? null : onCheckUpdate,
              child: isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Verificar Atualizações'),
            ),
          ],
        ),
      ),
    );
  }
}
