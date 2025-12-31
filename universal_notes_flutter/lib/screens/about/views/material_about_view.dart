import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Material Design view for AboutScreen
class MaterialAboutView extends StatelessWidget {
  final PackageInfo packageInfo;
  final bool isChecking;
  final VoidCallback onCheckUpdate;

  const MaterialAboutView({
    super.key,
    required this.packageInfo,
    required this.isChecking,
    required this.onCheckUpdate,
  });

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
