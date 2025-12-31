import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    hide MenuAnchor, MenuBar, MenuItemButton, SearchBar;
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/persona_model.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/editor/editor_screen.dart';
import 'package:universal_notes_flutter/screens/notes/views/fluent_notes_view.dart';
import 'package:universal_notes_flutter/screens/notes/views/material_notes_view.dart';
import 'package:universal_notes_flutter/screens/notes/widgets/dashboard_card.dart';
import 'package:universal_notes_flutter/screens/settings/settings_screen.dart';
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

  final _searchResultsNotifier = ValueNotifier<List<Note>?>(null);
  final _isSearchingNotifier = ValueNotifier<bool>(false);

  void _cycleViewMode() {
    const modes = ['grid_medium', 'grid_large', 'list'];
    final currentMode = _viewModeNotifier.value;
    final nextIndex = (modes.indexOf(currentMode) + 1) % modes.length;
    _viewModeNotifier.value = modes[nextIndex];
  }

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
    return (
      icon: isFluent ? fluent.FluentIcons.view_all : Icons.view_module,
      tooltip: 'Grid View (Medium)',
    );
  }

  @override
  void initState() {
    super.initState();
    _updateService = widget.updateService ?? UpdateService();
    _notesStream = _syncService.notesStream;
    windowManager.addListener(this);
    _updateNotesStream();
    _searchController.addListener(_onSearchChanged);
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

  Timer? _searchDebounce;
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text;

    if (query.isEmpty) {
      _searchResultsNotifier.value = null;
      _isSearchingNotifier.value = false;
      return;
    }

    _isSearchingNotifier.value = true;

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await NoteRepository.instance.searchNotes(query);
      _searchResultsNotifier.value = results;
      _isSearchingNotifier.value = false;
    });
  }

  void _updateNotesStream() {
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
      _syncService.refreshLocalData(
        folderId: folderId,
        tagId: tagId,
        isFavorite: isFavorite,
        isInTrash: isInTrash,
      ),
    );
  }

  void _onSelectionChanged(SidebarSelection selection) {
    setState(() {
      _selection = selection;
      _updateNotesStream();
    });
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
      content: '',
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      ownerId: 'user',
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

  Widget _buildContent() {
    return ValueListenableBuilder<List<Note>?>(
      valueListenable: _searchResultsNotifier,
      builder: (context, searchResults, child) {
        if (searchResults != null) {
          if (searchResults.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              message: 'Nenhum resultado encontrado.',
            );
          }
          return _buildSearchResults(searchResults);
        }
        return child!;
      },
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

    return ValueListenableBuilder<SortOrder>(
      valueListenable: _sortOrderNotifier,
      builder: (context, sortOrder, child) {
        final query = _searchController.text.toLowerCase();
        var displayNotes = notes;
        if (query.isNotEmpty) {
          displayNotes = notes.where((note) {
            return note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query);
          }).toList();
        }

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
      default:
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
        isSearchingNotifier: _isSearchingNotifier,
        content: _buildContent(),
        isTrashView: _selection.type == SidebarItemType.trash,
        onCreateNote: _createNewNote,
        onOpenQuickEditor: _abrirEditorRapido,
        onCreateFolder: _createNewFolder,
        onDeleteFolder: _deleteFolder,
      );
    }
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
