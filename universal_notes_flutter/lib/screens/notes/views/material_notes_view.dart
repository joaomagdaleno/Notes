import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A Material Design view for the notes list screen.
class MaterialNotesView extends StatelessWidget {
  /// Creates a [MaterialNotesView].
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

  /// Sidebar widget (typically a Drawer).
  final Widget sidebar;

  /// The title of the current view.
  final String title;

  /// Notifier for the current view mode.
  final ValueListenable<String> viewModeNotifier;

  /// Callback to cycle view modes.
  final VoidCallback onCycleViewMode;

  /// Function to get next view mode properties.
  final ({IconData icon, String tooltip}) Function(String)
      nextViewModePropsGetter;

  /// Callback to toggle theme.
  final VoidCallback onToggleTheme;

  /// Callback to check for updates.
  final VoidCallback onCheckUpdate;

  /// Callback to open settings.
  final VoidCallback onOpenSettings;

  /// Notifier for the current sort order.
  final ValueListenable<dynamic> sortOrderNotifier;

  /// Callback when sort order is changed.
  final ValueChanged<dynamic> onSortOrderChanged;

  /// Items to display in the sort order menu.
  final List<PopupMenuEntry<dynamic>> sortOrderItems;

  /// Controller for the search field.
  final TextEditingController searchController;

  /// Notifier for whether a search is currently in progress.
  final ValueListenable<bool> isSearchingNotifier;

  /// The main content widget.
  final Widget content;

  /// Whether we are currently in trash view.
  final bool isTrashView;

  /// Callback to create a note.
  final VoidCallback onCreateNote;

  /// Callback to open quick editor.
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
