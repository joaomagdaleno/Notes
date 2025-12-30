import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide MenuAnchor, MenuBar, MenuItemButton, SearchBar;
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
import 'package:universal_notes_flutter/screens/notes/views/fluent_notes_view.dart';
import 'package:universal_notes_flutter/screens/notes/views/material_notes_view.dart';
import 'package:universal_notes_flutter/screens/notes/widgets/dashboard_card.dart';

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
        '🎬 NotesScreen.initState starting after super.initState',
    ),);
    try {
      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: assigning _updateService...',
      ),);
      _updateService = widget.updateService ?? UpdateService();
      unawaited(StartupLogger.log(
          '✅ NotesScreen.initState: _updateService assigned',
      ),);

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initstate: connecting to notesStream...',
      ),);
      _notesStream = _syncService.notesStream;

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: adding windowManager listener...',
      ),);
      windowManager.addListener(this);

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: calling _updateNotesStream()...',
      ),);
      _updateNotesStream();

      unawaited(StartupLogger.log(
          '⏳ NotesScreen.initState: adding searchController listener...',
      ),);
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
                DashboardCard(
                  title: 'Architect',
                  subtitle: 'Nova Nota',
                  icon: Icons.edit_note,
                  color: Colors.blue,
                  onTap: () =>
                      _createNewNoteWithPersona(EditorPersona.architect),
                ),
                DashboardCard(
                  title: 'Writer',
                  subtitle: 'Novo Documento',
                  icon: Icons.description,
                  color: Colors.orange,
                  onTap: () => _createNewNoteWithPersona(
                    EditorPersona.writer,
                    'Novo Documento',
                  ),
                ),
                DashboardCard(
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
      return FluentNotesView(
        sidebar: Material(
          key: const ValueKey('sidebar_material_wrapper'),
          type: MaterialType.transparency,
          child: Sidebar(
            key: const ValueKey('fluent_sidebar'),
            onSelectionChanged: _onSelectionChanged,
          ),
        ),
        title: _getAppBarTitle(),
        viewModeNotifier: _viewModeNotifier,
        onCycleViewMode: _cycleViewMode,
        nextViewModePropsGetter: (mode) =>
            _getNextViewModeProperties(mode, isFluent: true),
        onToggleTheme: () {
          if (mounted) {
            unawaited(
              Provider.of<ThemeService>(
                context,
                listen: false,
              ).toggleTheme(),
            );
          }
        },
        onCheckUpdate: () => unawaited(_updateService.checkForUpdate()),
        onOpenSettings: () {
          unawaited(
            Navigator.of(context).push(
              fluent.FluentPageRoute<void>(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          );
        },
        searchController: _searchController,
        content: Material(
          type: MaterialType.transparency,
          child: _buildContent(),
        ),
        isTrashView: _selection.type == SidebarItemType.trash,
        onCreateNote: _createNewNote,
        onOpenQuickEditor: _abrirEditorRapido,
      );
    }
    unawaited(
      StartupLogger.log(
        '🎨 [BUILD] NotesScreen returning MaterialUI (mobile)',
      ),
    );
    return MaterialNotesView(
      sidebar: Sidebar(onSelectionChanged: _onSelectionChanged),
      title: _getAppBarTitle(),
      viewModeNotifier: _viewModeNotifier,
      onCycleViewMode: _cycleViewMode,
      nextViewModePropsGetter: _getNextViewModeProperties,
      onToggleTheme: () {
        if (mounted) {
          unawaited(
            Provider.of<ThemeService>(
              context,
              listen: false,
            ).toggleTheme(),
          );
        }
      },
      onCheckUpdate: () => unawaited(_updateService.checkForUpdate()),
      onOpenSettings: () {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const SettingsScreen(),
            ),
          ),
        );
      },
      sortOrderNotifier: _sortOrderNotifier,
      onSortOrderChanged: (result) {
        _sortOrderNotifier.value = result as SortOrder;
      },
      sortOrderItems: <PopupMenuEntry<SortOrder>>[
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
      searchController: _searchController,
      isSearchingNotifier: _isSearchingNotifier,
      content: _buildContent(),
      isTrashView: _selection.type == SidebarItemType.trash,
      onCreateNote: _createNewNote,
      onOpenQuickEditor: _abrirEditorRapido,
    );
  }
}

