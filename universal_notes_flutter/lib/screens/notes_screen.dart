import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide MenuBar, MenuAnchor, MenuItemButton, SearchBar;
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/persona_model.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';
import 'package:universal_notes_flutter/services/startup_logger.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/empty_state.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/quick_note_editor.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

/// The main screen displaying the list of notes.
class NotesScreen extends StatefulWidget {
  /// Creates a new instance of [NotesScreen].
  const NotesScreen({
    super.key,
    this.updateService,
  });

  /// The service for checking app updates.
  final UpdateService? updateService;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

/// The order in which notes are sorted.
enum SortOrder {
  /// Sort by date, descending (newest first).
  dateDesc,

  /// Sort by date, ascending (oldest first).
  dateAsc,

  /// Sort by title, ascending (A-Z).
  titleAsc,

  /// Sort by title, descending (Z-A).
  titleDesc,
}

class _NotesScreenState extends State<NotesScreen> with WindowListener {
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final _sortOrderNotifier = ValueNotifier<SortOrder>(SortOrder.dateDesc);
  final SyncService _syncService = SyncService.instance;
  late final UpdateService _updateService;
  late Stream<List<Note>> _notesStream;

  final _searchController = TextEditingController();
  final _viewModeNotifier = ValueNotifier<String>('grid_medium');
  final ScrollController _scrollController = ScrollController();

  // ⚡ Bolt: Use ValueNotifiers for search state to prevent full-screen
  // rebuilds. Only widgets wrapped in ValueListenableBuilder will update.
  final _searchResultsNotifier = ValueNotifier<List<Note>?>(null);
  final _isSearchingNotifier = ValueNotifier<bool>(false);

  // 🎨 Palette: Cycle through view modes to provide a dynamic button.
  void _cycleViewMode() {
    const modes = ['grid_medium', 'grid_large', 'list'];
    final currentMode = _viewModeNotifier.value;
    final nextIndex = (modes.indexOf(currentMode) + 1) % modes.length;
    _viewModeNotifier.value = modes[nextIndex];
  }

  // 🎨 Palette: Get the icon and tooltip for the *next* view mode.
  ({IconData icon, String tooltip}) _getNextViewModeProperties(
    String currentMode, {
    bool isFluent = false,
  }) {
    if (isFluent) {
      switch (currentMode) {
        case 'grid_medium':
          return (
            icon: fluent.FluentIcons.grid_view_large,
            tooltip: 'Grid View (Large)'
          );
        case 'grid_large':
          return (icon: fluent.FluentIcons.list, tooltip: 'List View');
        case 'list':
          return (
            icon: fluent.FluentIcons.view_all,
            tooltip: 'Grid View (Medium)'
          );
      }
    } else {
      switch (currentMode) {
        case 'grid_medium':
          return (icon: Icons.view_comfy, tooltip: 'Grid View (Large)');
        case 'grid_large':
          return (icon: Icons.view_list, tooltip: 'List View');
        case 'list':
          return (icon: Icons.view_module, tooltip: 'Grid View (Medium)');
      }
    }
    // Default fallback
    return (
      icon: isFluent ? fluent.FluentIcons.view_all : Icons.view_module,
      tooltip: 'Grid View (Medium)'
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(StartupLogger.log(
        '🎬 NotesScreen.initState starting after super.initState'));
    try {
      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: assigning _updateService...'));
      _updateService = widget.updateService ?? UpdateService();
      unawaited(StartupLogger.log(
          '✅ NotesScreen.initState: _updateService assigned'));

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initstate: connecting to notesStream...'));
      _notesStream = _syncService.notesStream;

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: adding windowManager listener...'));
      windowManager.addListener(this);

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: calling _updateNotesStream()...'));
      _updateNotesStream();

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: adding searchController listener...'));
      _searchController.addListener(_onSearchChanged);

      unawaited(StartupLogger.log('✅ NotesScreen.initState complete'));
    } on Exception catch (e, stack) {
      unawaited(StartupLogger.log('🔥 CRASH in NotesScreen.initState: $e'));
      unawaited(StartupLogger.log(stack.toString()));
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _scrollController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _viewModeNotifier.dispose();
    _sortOrderNotifier.dispose();
    _searchResultsNotifier.dispose();
    _isSearchingNotifier.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Handles search input changes with debounce.
  Timer? _searchDebounce;
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text;

    if (query.isEmpty) {
      // ⚡ Bolt: No setState(), just update the notifier's value.
      _searchResultsNotifier.value = null;
      _isSearchingNotifier.value = false;
      return;
    }

    // ⚡ Bolt: No setState(), just update the notifier's value.
    _isSearchingNotifier.value = true;

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await NoteRepository.instance.searchNotes(query);
      // ⚡ Bolt: No need for context.mounted or setState. The
      // ValueListenableBuilder will handle the update automatically.
      _searchResultsNotifier.value = results;
      _isSearchingNotifier.value = false;
    });
  }

  void _updateNotesStream() {
    unawaited(StartupLogger.log('🌊 NotesScreen._updateNotesStream starting'));
    try {
      bool? isFavorite;
      bool? isInTrash;
      String? folderId;
      String? tagId;

      switch (_selection.type) {
        case SidebarItemType.all:
          isInTrash = false;
        case SidebarItemType.favorites:
          isFavorite = true;
          isInTrash = false;
        case SidebarItemType.trash:
          isInTrash = true;
        case SidebarItemType.folder:
          if (_selection.folder != null) {
            folderId = _selection.folder!.id;
            isInTrash = false;
          }
        case SidebarItemType.tag:
          tagId = _selection.tag;
          isInTrash = false;
      }

      unawaited(
        StartupLogger.log(
          '🌊 NotesScreen._updateNotesStream: filter params - '
          'folderId: $folderId, tagId: $tagId, isFavorite: $isFavorite, '
          'isInTrash: $isInTrash',
        ),
      );

      // Trigger refresh of local data into the stream
      unawaited(
        _syncService.refreshLocalData(
          folderId: folderId,
          tagId: tagId,
          isFavorite: isFavorite,
          isInTrash: isInTrash,
        ),
      );
    } on Exception catch (e, stack) {
      unawaited(StartupLogger.log('🔥 ERROR in _updateNotesStream: $e'));
      unawaited(StartupLogger.log(stack.toString()));
    }
  }

  void _onSelectionChanged(SidebarSelection selection) {
    setState(() {
      _selection = selection;
      _updateNotesStream();
    });
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createNewNote() async {
    final note = Note(
      id: const Uuid().v4(),
      title: 'Nova Nota',
      content: '', // Use empty string for new notes
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user', // Default user
    );
    await NoteRepository.instance.insertNote(note);
    await _syncService.refreshLocalData();
    if (context.mounted) {
      unawaited(_openNoteEditor(note));
    }
  }

  Future<void> _createNewNoteWithPersona(
    EditorPersona persona, [
    String title = 'Nova Nota',
  ]) async {
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      content: '',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user',
    );
    await NoteRepository.instance.insertNote(note);
    await _syncService.refreshLocalData();
    if (context.mounted) {
      unawaited(_openNoteEditor(note, persona));
    }
  }

  Future<void> _openNoteEditor(
    Note note, [
    EditorPersona? initialPersona,
  ]) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => NoteEditorScreen(
          note: note,
          initialPersona: initialPersona,
          onSave: (updatedNote) async {
            await NoteRepository.instance.updateNote(updatedNote);
            await _syncService.refreshLocalData();
            return updatedNote;
          },
        ),
      ),
    );
  }

  void _abrirEditorRapido() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => QuickNoteEditor(
          onSave: _processarNotaRapida,
        ),
      ),
    );
  }

  Future<void> _processarNotaRapida(String content) async {
    final noteRepository = NoteRepository.instance;
    final now = DateTime.now();
    final newNote = Note(
      id: now.millisecondsSinceEpoch.toString(),
      title: content.split('\n').first,
      content: content,
      createdAt: now,
      lastModified: now,
      ownerId: 'local_user',
    );
    await noteRepository.insertNote(newNote);
    await _syncService.refreshLocalData();
    unawaited(_openNoteEditor(newNote));
  }

  @override
  Future<void> onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
    super.onWindowClose();
  }

  Future<void> _toggleFavorite(Note note) async {
    final noteRepository = NoteRepository.instance;
    await noteRepository.updateNote(
      note.copyWith(isFavorite: !note.isFavorite),
    );
    await _syncService.refreshLocalData();
  }

  Future<void> _moveToTrash(Note note) async {
    final noteRepository = NoteRepository.instance;
    await noteRepository.updateNote(note.copyWith(isInTrash: true));
    await _syncService.refreshLocalData();
  }

  Future<void> _restoreNote(Note note) async {
    final noteRepository = NoteRepository.instance;
    await noteRepository.updateNote(note.copyWith(isInTrash: false));
    await _syncService.refreshLocalData();
  }

  Future<void> _deletePermanently(Note note) async {
    final noteRepository = NoteRepository.instance;
    await noteRepository.deleteNotePermanently(note.id);
    await _syncService.refreshLocalData();
  }

  String _getAppBarTitle() {
    switch (_selection.type) {
      case SidebarItemType.all:
        return 'All Notes';
      case SidebarItemType.favorites:
        return 'Favorites';
      case SidebarItemType.trash:
        return 'Trash';
      case SidebarItemType.folder:
        return _selection.folder?.name ?? 'Folder';
      case SidebarItemType.tag:
        return 'Tag: ${_selection.tag ?? ''}';
    }
  }

  /// Builds the main content area - search results or normal notes list.
  Widget _buildContent() {
    // ⚡ Bolt: This ValueListenableBuilder ensures that only the content area
    // rebuilds when search results change, not the entire NotesScreen.
    return ValueListenableBuilder<List<Note>?>(
      valueListenable: _searchResultsNotifier,
      builder: (context, searchResults, child) {
        // Show search results if we have them
        if (searchResults != null) {
          if (searchResults.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              message: 'Nenhum resultado encontrado.',
            );
          }
          return _buildSearchResults(searchResults);
        }

        // Otherwise, show the normal notes stream
        return child!;
      },
      // ⚡ Bolt: The StreamBuilder is passed as a child, so it's only built
      // once and not affected by search result updates.
      child: StreamBuilder<List<Note>>(
        stream: _notesStream,
        initialData: _syncService.currentNotes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyState(
              icon: Icons.note_add,
              message: 'No notes yet. Create one!',
            );
          }
          return _buildNotesList(snapshot.data!);
        },
      ),
    );
  }

  /// Builds the search results list with highlighted snippets.
  Widget _buildSearchResults(List<Note> results) {
    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              result.title.isEmpty ? 'Sem título' : result.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              result.content.length > 100
                  ? '${result.content.substring(0, 100)}...'
                  : result.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => unawaited(_openNoteEditor(result)),
          ),
        );
      },
    );
  }

  Widget _buildNotesList(List<Note> notes) {
    final isTrashView = _selection.type == SidebarItemType.trash;

    // ⚡ Bolt: Using ValueListenableBuilder to rebuild only the list when
    // sorting changes, preventing the whole screen from rebuilding.
    return ValueListenableBuilder<SortOrder>(
      valueListenable: _sortOrderNotifier,
      builder: (context, sortOrder, child) {
        // Filter by search query
        final query = _searchController.text.toLowerCase();
        var displayNotes = notes;
        if (query.isNotEmpty) {
          displayNotes = notes.where((note) {
            return note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query);
          }).toList();
        }

        // Apply client-side sorting
        displayNotes.sort((a, b) {
          switch (sortOrder) {
            case SortOrder.dateAsc:
              return a.lastModified.compareTo(b.lastModified);
            case SortOrder.titleAsc:
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            case SortOrder.titleDesc:
              return b.title.toLowerCase().compareTo(a.title.toLowerCase());
            case SortOrder.dateDesc:
              return b.lastModified.compareTo(a.lastModified);
          }
        });

        if (displayNotes.isEmpty) {
          return const EmptyState(
            icon: Icons.note_add,
            message: 'No notes yet. Create one!',
          );
        }

        // ⚡ Bolt: By nesting this ValueListenableBuilder, only the GridView
        // rebuilds when the view mode changes, not the entire screen.
        return Column(
          children: [
            if (_selection.type == SidebarItemType.all &&
                _searchController.text.isEmpty)
              _buildDashboard(),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _viewModeNotifier,
                builder: (context, viewMode, child) {
                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: _getGridDelegate(viewMode),
                    itemCount: displayNotes.length,
                    itemBuilder: (context, index) {
                      final note = displayNotes[index];
                      return NoteCard(
                        note: note,
                        onTap: () => unawaited(_openNoteEditor(note)),
                        onSave: (note) async {
                          final noteRepository = NoteRepository.instance;
                          await noteRepository.updateNote(note);
                          await _syncService.refreshLocalData();
                          return note;
                        },
                        onDelete: _deletePermanently,
                        onFavorite: isTrashView
                            ? (n) => unawaited(_restoreNote(n))
                            : (n) => unawaited(_toggleFavorite(n)),
                        onTrash: isTrashView
                            ? (n) => unawaited(_deletePermanently(n))
                            : (n) => unawaited(_moveToTrash(n)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Start',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DashboardCard(
                  title: 'Architect',
                  subtitle: 'Nova Nota',
                  icon: Icons.edit_note,
                  color: Colors.blue,
                  onTap: () =>
                      _createNewNoteWithPersona(EditorPersona.architect),
                ),
                _DashboardCard(
                  title: 'Writer',
                  subtitle: 'Novo Documento',
                  icon: Icons.description,
                  color: Colors.orange,
                  onTap: () => _createNewNoteWithPersona(
                    EditorPersona.writer,
                    'Novo Documento',
                  ),
                ),
                _DashboardCard(
                  title: 'Brainstorm',
                  subtitle: 'Novo Quadro',
                  icon: Icons.dashboard,
                  color: Colors.purple,
                  onTap: () => _createNewNoteWithPersona(
                    EditorPersona.brainstorm,
                    'Novo Quadro',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text(
            'Recent Notes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialUI() {
    final isTrashView = _selection.type == SidebarItemType.trash;
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          // 🎨 Palette: A single, dynamic button to cycle through view modes.
          ValueListenableBuilder<String>(
            valueListenable: _viewModeNotifier,
            builder: (context, currentMode, child) {
              final nextMode = _getNextViewModeProperties(currentMode);
              return IconButton(
                icon: Icon(nextMode.icon),
                tooltip: nextMode.tooltip,
                onPressed: _cycleViewMode,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.update),
            tooltip: 'Check for Updates',
            onPressed: () => unawaited(_updateService.checkForUpdate()),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: 'Toggle Theme',
            onPressed: () {
              if (context.mounted) {
                unawaited(
                  Provider.of<ThemeService>(
                    context,
                    listen: false,
                  ).toggleTheme(),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<SortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Order',
            onSelected: (SortOrder result) {
              // ⚡ Bolt: Update notifier directly, no setState needed.
              _sortOrderNotifier.value = result;
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOrder>>[
              const PopupMenuItem<SortOrder>(
                value: SortOrder.dateDesc,
                child: Text('Data (Mais Recentes)'),
              ),
              const PopupMenuItem<SortOrder>(
                value: SortOrder.dateAsc,
                child: Text('Data (Mais Antigas)'),
              ),
              const PopupMenuItem<SortOrder>(
                value: SortOrder.titleAsc,
                child: Text('Título (A-Z)'),
              ),
              const PopupMenuItem<SortOrder>(
                value: SortOrder.titleDesc,
                child: Text('Título (Z-A)'),
              ),
            ],
          ),
        ],
      ),
      drawer: Sidebar(onSelectionChanged: _onSelectionChanged),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar em todas as notas...',
                prefixIcon: const Icon(Icons.search),
                // ⚡ Bolt: Use a ValueListenableBuilder for the suffix icon
                // to ensure only the icon rebuilds, not the whole TextField.
                suffixIcon: ValueListenableBuilder<bool>(
                  valueListenable: _isSearchingNotifier,
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
                    // Use a second builder for the clear button to react to
                    // text changes without rebuilding the search indicator.
                    return ValueListenableBuilder(
                      valueListenable: _searchController,
                      builder: (context, text, child) {
                        return _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _searchController.clear,
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
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: isTrashView
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: _createNewNote,
                  tooltip: 'Nova Nota',
                  heroTag: 'add_note',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(width: 16),
                FloatingActionButton.large(
                  onPressed: _abrirEditorRapido,
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

  SliverGridDelegate _getGridDelegate(String viewMode) {
    switch (viewMode) {
      case 'grid_large':
        return const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        );
      case 'list':
        return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 5 / 1,
        );
      default: // grid_medium
        return const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        );
    }
  }

  Widget _buildFluentUI() {
    unawaited(StartupLogger.log('🧪 [HYBRID] _buildFluentUI: Reconstructing UI with Row + ScaffoldPage'));
    try {
      final isTrashView = _selection.type == SidebarItemType.trash;
      final title = _getAppBarTitle();

      unawaited(StartupLogger.log('🧪 [HYBRID] Rendering with title: $title'));

      final content = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar on the left
          Material(
            key: const ValueKey('sidebar_material_wrapper'),
            type: MaterialType.transparency,
            child: Sidebar(
              key: const ValueKey('fluent_sidebar'),
              onSelectionChanged: _onSelectionChanged,
            ),
          ),
          
          // Main content on the right
          Expanded(
            child: fluent.ScaffoldPage(
              header: fluent.PageHeader(
                padding: 12,
                title: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                commandBar: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Persona / View Mode (Discrete)
                    ValueListenableBuilder<String>(
                      valueListenable: _viewModeNotifier,
                      builder: (context, currentMode, child) {
                        final props = _getNextViewModeProperties(
                          currentMode,
                          isFluent: true,
                        );
                        return fluent.Tooltip(
                          message: 'Persona: ${props.tooltip}',
                          child: fluent.IconButton(
                            icon: Icon(props.icon, size: 16),
                            onPressed: _cycleViewMode,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    fluent.Tooltip(
                      message: 'Toggle Theme',
                      child: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.brightness, size: 16),
                        onPressed: () {
                          if (context.mounted) {
                            unawaited(
                              Provider.of<ThemeService>(
                                context,
                                listen: false,
                              ).toggleTheme(),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    fluent.Tooltip(
                      message: 'Check for Updates',
                      child: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.update_restore, size: 16),
                        onPressed: () => unawaited(_updateService.checkForUpdate()),
                      ),
                    ),
                    const SizedBox(width: 4),
                    fluent.Tooltip(
                      message: 'Settings',
                      child: fluent.IconButton(
                        icon: const Icon(fluent.FluentIcons.settings, size: 16),
                        onPressed: () {
                          unawaited(
                            Navigator.of(context).push(
                              fluent.FluentPageRoute<void>(
                                builder: (context) => const SettingsScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              content: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: fluent.TextBox(
                      controller: _searchController,
                      placeholder: 'Search notes...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(fluent.FluentIcons.search, size: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      type: MaterialType.transparency,
                      child: StreamBuilder<List<Note>>(
                        stream: _notesStream,
                        initialData: _syncService.currentNotes,
                        builder: (context, snapshot) {
                          unawaited(StartupLogger.log(
                              '🧪 [HYBRID] StreamBuilder pulse - hasData: '
                              '${snapshot.hasData}, items: ${snapshot.data?.length}'));
                          if (snapshot.connectionState == ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(child: fluent.ProgressRing());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const EmptyState(
                              icon: fluent.FluentIcons.note_forward,
                              message: 'No notes yet. Create one!',
                            );
                          }
                          return _buildNotesList(snapshot.data!);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              bottomBar: isTrashView
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          fluent.FilledButton(
                            onPressed: _createNewNote,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(fluent.FluentIcons.add),
                                SizedBox(width: 8),
                                Text('New Note'),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          fluent.Button(
                            onPressed: _abrirEditorRapido,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(fluent.FluentIcons.quick_note),
                                SizedBox(width: 8),
                                Text('Quick Note'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      );

      return fluent.FluentTheme(
        data: fluent.FluentThemeData.light(),
        child: content,
      );
    } catch (e, stack) {
      unawaited(StartupLogger.log('🔥 [CRASH] _buildFluentUI: $e'));
      unawaited(StartupLogger.log(stack.toString()));
      return Scaffold(body: Center(child: Text('UI Crash: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    unawaited(
      StartupLogger.log(
        '🎨 [BUILD] NotesScreen.build called - '
        'platform: $defaultTargetPlatform',
      ),
    );
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return _buildFluentUI();
    }
    unawaited(
      StartupLogger.log(
        '🎨 [BUILD] NotesScreen returning MaterialUI (mobile)',
      ),
    );
    return _buildMaterialUI();
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  // ⚡ Bolt: Hoist constant styles to prevent them from being recreated on
  // every build. `copyWith` is used to apply instance-specific colors.
  // This is more efficient than creating new TextStyle objects on each build.
  static const _titleTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  static const _subtitleTextStyle = TextStyle(
    fontSize: 12,
  );

  // being recreated on every build.
  static const _baseDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: _baseDecoration.copyWith(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: _titleTextStyle.copyWith(color: color),
            ),
            Text(
              subtitle,
              style: _subtitleTextStyle.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
