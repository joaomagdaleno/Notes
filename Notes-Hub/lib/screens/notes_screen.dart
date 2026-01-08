import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide MenuAnchor, MenuBar, MenuItemButton, SearchBar;
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/persona_model.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/screens/note_editor_screen.dart';
import 'package:notes_hub/screens/notes/views/fluent_notes_view.dart';
import 'package:notes_hub/screens/notes/views/material_notes_view.dart';
import 'package:notes_hub/screens/notes/widgets/dashboard_card.dart';
import 'package:notes_hub/screens/settings_screen.dart';
import 'package:notes_hub/services/startup_logger.dart';
import 'package:notes_hub/services/sync_service.dart';
import 'package:notes_hub/services/theme_service.dart';
import 'package:notes_hub/services/update_service.dart';
import 'package:notes_hub/widgets/empty_state.dart';
import 'package:notes_hub/widgets/note_card.dart';
import 'package:notes_hub/widgets/quick_note_editor.dart';
import 'package:notes_hub/widgets/sidebar.dart';
import 'package:provider/provider.dart';
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
  // ⚡ Bolt: Cache SliverGridDelegates to avoid re-creating them on every
  // build. This is a significant performance win for list scrolling.
  static const _gridDelegateLarge = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 300,
    childAspectRatio: 3 / 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  );
  static const _gridDelegateList = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 1,
    childAspectRatio: 5 / 1,
  );
  static const _gridDelegateMedium = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,
    childAspectRatio: 3 / 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  );

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

  // ⚡ Bolt: Cache TextStyles to avoid expensive Theme lookups on every build.
  TextStyle? _dashboardTitleStyle;
  TextStyle? _dashboardSubtitleStyle;

  // ⚡ Bolt: Cache the Dashboard widget itself.
  // This prevents the dashboard from being rebuilt every time the note list
  // changes, as the widget instance remains identical. It's only rebuilt in
  // didChangeDependencies when the theme changes.
  Widget? _dashboard;

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
            tooltip: 'Grid View (Large)',
          );
        case 'grid_large':
          return (icon: fluent.FluentIcons.list, tooltip: 'List View');
        case 'list':
          return (
            icon: fluent.FluentIcons.view_all,
            tooltip: 'Grid View (Medium)',
          );
      }
    } else {
      switch (currentMode) {
        case 'grid_medium':
          return (
            icon: Icons.view_comfy,
            tooltip: 'Grid View (Large)',
          );
        case 'grid_large':
          return (icon: Icons.view_list, tooltip: 'List View');
        case 'list':
          return (
            icon: Icons.view_module,
            tooltip: 'Grid View (Medium)',
          );
      }
    }
    // Default fallback
    return (
      icon: isFluent ? fluent.FluentIcons.view_all : Icons.view_module,
      tooltip: 'Grid View (Medium)',
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(
      StartupLogger.log(
        '🎬 NotesScreen.initState starting after super.initState',
      ),
    );
    try {
      unawaited(
        StartupLogger.log(
          '⏳ NotesScreen.initState: assigning _updateService...',
        ),
      );
      _updateService = widget.updateService ?? UpdateService();
      unawaited(
        StartupLogger.log(
          '✅ NotesScreen.initState: _updateService assigned',
        ),
      );

      unawaited(
        StartupLogger.log(
          '⏳ NotesScreen.initstate: connecting to notesStream...',
        ),
      );
      _notesStream = _syncService.notesStream;

      unawaited(
        StartupLogger.log(
          '⏳ NotesScreen.initState: adding windowManager listener...',
        ),
      );
      windowManager.addListener(this);

      unawaited(
        StartupLogger.log(
          '⏳ NotesScreen.initState: calling _updateNotesStream()...',
        ),
      );
      _updateNotesStream();

      unawaited(
        StartupLogger.log(
          '⏳ NotesScreen.initState: adding searchController listener...',
        ),
      );
      _searchController.addListener(_onSearchChanged);

      unawaited(StartupLogger.log('✅ NotesScreen.initState complete'));
    } on Exception catch (e, stack) {
      unawaited(StartupLogger.log('🔥 CRASH in NotesScreen.initState: $e'));
      unawaited(StartupLogger.log(stack.toString()));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ⚡ Bolt: Initialize styles here. This is called once when dependencies
    // change (like theme), which is more efficient than in the build method.
    _dashboardTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );
    _dashboardSubtitleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.grey.shade600,
        );
    _dashboard = _Dashboard(
      dashboardTitleStyle: _dashboardTitleStyle,
      dashboardSubtitleStyle: _dashboardSubtitleStyle,
      onCreateNewNoteWithPersona: _createNewNoteWithPersona,
    );
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
    // Don't pop on Windows as we use NavigationView which is persistent
    if (defaultTargetPlatform != TargetPlatform.windows && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createNewFolder() async {
    final controller = TextEditingController();
    String? name;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      name = await fluent.showDialog<String>(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('New Folder'),
          content: fluent.TextBox(
            controller: controller,
            placeholder: 'Folder Name',
            autofocus: true,
          ),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            fluent.FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Create'),
            ),
          ],
        ),
      );
    } else {
      name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('New Folder'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Folder Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Create'),
            ),
          ],
        ),
      );
    }

    if (name != null && name.trim().isNotEmpty) {
      await NoteRepository.instance.createFolder(name.trim());
      await _syncService.refreshLocalData();
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    if (_selection.type == SidebarItemType.folder &&
        _selection.folder?.id == folderId) {
      const newSelection = SidebarSelection(SidebarItemType.all);
      setState(() => _selection = newSelection);
      _onSelectionChanged(newSelection);
    }
    await NoteRepository.instance.deleteFolder(folderId);
    await _syncService.refreshLocalData();
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
          onSave: (Note updatedNote) async {
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
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
          return fluent.ContentDialog(
            title: const Text('Delete Permanently?'),
            content: const Text(
              'This action cannot be undone. Are you sure you want to '
              'permanently delete this note?',
            ),
            actions: [
              fluent.Button(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              fluent.FilledButton(
                style: fluent.ButtonStyle(
                  backgroundColor: fluent.WidgetStateProperty.all(
                    Colors.red[700],
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          );
        }
        return AlertDialog(
          title: const Text('Delete Permanently?'),
          content: const Text(
            'This action cannot be undone. Are you sure you want to '
            'permanently delete this note?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete ?? false) {
      final noteRepository = NoteRepository.instance;
      await noteRepository.deleteNotePermanently(note.id);
      await _syncService.refreshLocalData();
    }
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
        // ⚡ Bolt: No synchronous filtering needed here. The search results
        // are handled by a separate ValueListenableBuilder (_buildContent).
        // This was causing redundant work on the UI thread.
        final displayNotes = List<Note>.from(notes)
          ..sort((a, b) {
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
                _searchController.text.isEmpty &&
                _dashboard != null)
              _dashboard!,
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
                        onSave: (Note note) async {
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

  SliverGridDelegate _getGridDelegate(String viewMode) {
    switch (viewMode) {
      case 'grid_large':
        return _gridDelegateLarge;
      case 'list':
        return _gridDelegateList;
      default: // grid_medium
        return _gridDelegateMedium;
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
        selection: _selection,
        onSelectionChanged: _onSelectionChanged,
        foldersStream: _syncService.foldersStream,
        tagsStream: _syncService.tagsStream,
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
        content: _buildContent(),
        isTrashView: _selection.type == SidebarItemType.trash,
        onCreateNote: _createNewNote,
        onOpenQuickEditor: _abrirEditorRapido,
        onCreateFolder: _createNewFolder,
        onDeleteFolder: _deleteFolder,
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
      sortOrderItems: const <PopupMenuEntry<SortOrder>>[
        PopupMenuItem<SortOrder>(
          value: SortOrder.dateDesc,
          child: Text('Data (Mais Recentes)'),
        ),
        PopupMenuItem<SortOrder>(
          value: SortOrder.dateAsc,
          child: Text('Data (Mais Antigas)'),
        ),
        PopupMenuItem<SortOrder>(
          value: SortOrder.titleAsc,
          child: Text('Título (A-Z)'),
        ),
        PopupMenuItem<SortOrder>(
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

// ⚡ Bolt: Refactored dashboard into a stateless widget.
// By making it a separate widget, we can instantiate it,
// preventing it from rebuilding unnecessarily when the parent `NotesScreen`
// state changes (e.g., when sorting or filtering notes). This is a pure UI
// component that doesn't need to be part of the larger stateful widget tree.
class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.dashboardTitleStyle,
    required this.dashboardSubtitleStyle,
    required this.onCreateNewNoteWithPersona,
  });

  final TextStyle? dashboardTitleStyle;
  final TextStyle? dashboardSubtitleStyle;
  final void Function(EditorPersona, [String]) onCreateNewNoteWithPersona;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Start',
            style: dashboardTitleStyle,
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
                      onCreateNewNoteWithPersona(EditorPersona.architect),
                ),
                DashboardCard(
                  title: 'Writer',
                  subtitle: 'Novo Documento',
                  icon: Icons.description,
                  color: Colors.orange,
                  onTap: () => onCreateNewNoteWithPersona(
                    EditorPersona.writer,
                    'Novo Documento',
                  ),
                ),
                DashboardCard(
                  title: 'Brainstorm',
                  subtitle: 'Novo Quadro',
                  icon: Icons.dashboard,
                  color: Colors.purple,
                  onTap: () => onCreateNewNoteWithPersona(
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
            style: dashboardSubtitleStyle,
          ),
        ],
      ),
    );
  }
}
