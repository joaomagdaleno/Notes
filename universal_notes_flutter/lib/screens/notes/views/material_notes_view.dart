import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MaterialNotesView extends StatelessWidget {
  const MaterialNotesView({
    required this.sidebar,
    required this.title,
    required this.viewModeNotifier,
    required this.onCycleViewMode,
    required this.nextViewModePropsGetter,
    required this.onToggleTheme,
    required this.onCheckUpdate,
    required this.onOpenSettings,
    required this.sortOrderNotifier,
    required this.onSortOrderChanged,
    required this.searchController,
    required this.isSearchingNotifier,
    required this.content,
    required this.isTrashView,
    required this.onCreateNote,
    required this.onOpenQuickEditor,
    required this.sortOrderItems,
    super.key,
  });

  final Widget sidebar;
  final String title;
  final ValueListenable<String> viewModeNotifier;
  final VoidCallback onCycleViewMode;
  final ({IconData icon, String tooltip}) Function(String) nextViewModePropsGetter;
  final VoidCallback onToggleTheme;
  final VoidCallback onCheckUpdate;
  final VoidCallback onOpenSettings;
  final ValueListenable<dynamic> sortOrderNotifier;
  final ValueChanged<dynamic> onSortOrderChanged;
  final List<PopupMenuEntry<dynamic>> sortOrderItems;
  final TextEditingController searchController;
  final ValueListenable<bool> isSearchingNotifier;
  final Widget content;
  final bool isTrashView;
  final VoidCallback onCreateNote;
  final VoidCallback onOpenQuickEditor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ValueListenableBuilder<String>(
            valueListenable: viewModeNotifier,
            builder: (context, currentMode, child) {
              final props = nextViewModePropsGetter(currentMode);
              return IconButton(
                icon: Icon(props.icon),
                tooltip: props.tooltip,
                onPressed: onCycleViewMode,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.update),
            tooltip: 'Check for Updates',
            onPressed: onCheckUpdate,
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: onOpenSettings,
          ),
          PopupMenuButton<dynamic>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Order',
            onSelected: onSortOrderChanged,
            itemBuilder: (BuildContext context) => sortOrderItems,
          ),
        ],
      ),
      drawer: sidebar,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Buscar em todas as notas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<bool>(
                  valueListenable: isSearchingNotifier,
                  builder: (context, isSearching, child) {
                    if (isSearching) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return ValueListenableBuilder(
                      valueListenable: searchController,
                      builder: (context, text, child) {
                        return searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: searchController.clear,
                              )
                            : const SizedBox.shrink();
                      },
                    );
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
      floatingActionButton: isTrashView
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: onCreateNote,
                  tooltip: 'Nova Nota',
                  heroTag: 'add_note',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.large(
                  onPressed: onOpenQuickEditor,
                  heroTag: 'quick_note',
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note_add),
                      Text('Nota Rápida', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
