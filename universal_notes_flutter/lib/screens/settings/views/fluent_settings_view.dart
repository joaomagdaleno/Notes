import 'package:fluent_ui/fluent_ui.dart';

/// Fluent UI view for SettingsScreen - WinUI 3 styling
class FluentSettingsView extends StatelessWidget {
  final bool isLoadingInfo;
  final VoidCallback onOpenAbout;

  const FluentSettingsView({
    super.key,
    required this.isLoadingInfo,
    required this.onOpenAbout,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Configurações'),
      ),
      content: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Sobre'),
                  leading: const Icon(FluentIcons.info),
                  onPressed: isLoadingInfo ? null : onOpenAbout,
                  trailing: isLoadingInfo
                      ? const ProgressRing(
                          strokeWidth: 2,
                        )
                      : const Icon(FluentIcons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
