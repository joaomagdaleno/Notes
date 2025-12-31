import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Fluent UI view for AboutScreen - WinUI 3 styling
class FluentAboutView extends StatelessWidget {
  final PackageInfo packageInfo;
  final bool isChecking;
  final String updateStatus;
  final VoidCallback onCheckUpdate;
  final VoidCallback onBack;

  const FluentAboutView({
    super.key,
    required this.packageInfo,
    required this.isChecking,
    required this.updateStatus,
    required this.onCheckUpdate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Sobre'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: onBack,
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Universal Notes',
                  style: theme.typography.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'Versão atual: ${packageInfo.version}',
                  style: theme.typography.body,
                ),
                const Divider(
                  style: DividerThemeData(
                    horizontalMargin: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                Row(
                  children: [
                    FilledButton(
                      onPressed: isChecking ? null : onCheckUpdate,
                      child: isChecking
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: ProgressRing(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Verificar Atualizações'),
                    ),
                    const SizedBox(width: 16),
                    if (updateStatus.isNotEmpty)
                      Expanded(
                        child: Text(
                          updateStatus,
                          style: theme.typography.caption,
                        ),
                      ),
                  ],
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
    );
  }
}
