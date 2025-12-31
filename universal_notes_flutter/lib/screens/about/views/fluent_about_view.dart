import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Fluent UI view for AboutScreen - WinUI 3 styling
/// Fluent UI view for AboutScreen - WinUI 3 styling
class FluentAboutView extends StatelessWidget {
  /// Creates a [FluentAboutView].
  const FluentAboutView({
    required this.packageInfo,
    required this.isChecking,
    required this.updateStatus,
    required this.onCheckUpdate,
    required this.onBack,
    super.key,
  });

  /// The information about the package.
  final PackageInfo packageInfo;
  /// Whether the app is currently checking for updates.
  final bool isChecking;
  /// The current update status message.
  final String updateStatus;
  /// Callback for checking updates.
  final VoidCallback onCheckUpdate;
  /// Callback for navigating back.
  final VoidCallback onBack;

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
