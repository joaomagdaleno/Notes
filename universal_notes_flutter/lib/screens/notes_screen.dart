import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/empty_state.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/quick_note_editor.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';
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
  SortOrder _sortOrder = SortOrder.dateDesc;
  final SyncService _syncService = SyncService.instance;
  late final UpdateService _updateService;
  late Stream<List<Note>> _notesStream;

  final _searchController = TextEditingController();
  final _viewModeNotifier = ValueNotifier<String>('grid_medium');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Removed direct FirestoreRepository usage
    _updateService = widget.updateService ?? UpdateService();
    _notesStream = _syncService.notesStream; // Point to sync service stream
    windowManager.addListener(this);
    // _scrollController.addListener(_onScroll); // Disabled pagination listener
    _updateNotesStream(); // Initial fetch
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _scrollController.dispose();
    _searchController.dispose();
    _viewModeNotifier.dispose();
    super.dispose();
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

    // Trigger refresh of local data into the stream
    _syncService.refreshLocalData(
      folderId: folderId,
      tagId: tagId,
      isFavorite: isFavorite,
      isInTrash: isInTrash,
    );
  }

  void _onSelectionChanged(SidebarSelection selection) {
    setState(() {
      _selection = selection;
      _updateNotesStream();
    });
    Navigator.of(context).pop();
  }

  Future<void> _createNewNote() async {
    final newNote = await _firestoreRepository.addNote(
      title: 'Nova Nota',
      content: '',
    );
    unawaited(_openNoteEditor(newNote));
  }

  Future<void> _openNoteEditor(Note note) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => NoteEditorScreen(
          note: note,
          onSave: (updatedNote) async {
            await _firestoreRepository.updateNote(updatedNote);
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

  Widget _buildNotesList(List<Note> notes) {
    final isTrashView = _selection.type == SidebarItemType.trash;

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      notes = notes.where((note) {
        return note.title.toLowerCase().contains(query) ||
            note.content.toLowerCase().contains(query);
      }).toList();
    }

    // Apply client-side sorting
    notes.sort((a, b) {
      switch (_sortOrder) {
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

    if (notes.isEmpty) {
      return const EmptyState(
        icon: Icons.note_add,
        message: 'No notes yet. Create one!',
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: _getGridDelegate(_viewModeNotifier.value),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Dismissible(
          key: Key(note.id),
          background: Container(
            color: isTrashView ? Colors.blue : Colors.green,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              isTrashView ? Icons.restore_from_trash : Icons.favorite,
              color: Colors.white,
            ),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(
              isTrashView ? Icons.delete_forever : Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) {
            if (isTrashView) {
              if (direction == DismissDirection.startToEnd) {
                unawaited(_restoreNote(note));
              } else {
                unawaited(_deletePermanently(note));
              }
            } else {
              if (direction == DismissDirection.startToEnd) {
                unawaited(_toggleFavorite(note));
              } else {
                unawaited(_moveToTrash(note));
              }
            }
          },
          child: NoteCard(
            note: note,
            onTap: () => unawaited(_openNoteEditor(note)),
            onSave: (note) async {
              final noteRepository = NoteRepository.instance;
              await noteRepository.updateNote(note);
              await _syncService.refreshLocalData();
              return note;
            },
            onDelete: _deletePermanently,
          ),
        );
      },
    );
  }

  Widget _buildMaterialUI() {
    final isTrashView = _selection.type == SidebarItemType.trash;
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () => _viewModeNotifier.value = 'grid_medium',
          ),
          IconButton(
            icon: const Icon(Icons.view_comfy),
            onPressed: () => _viewModeNotifier.value = 'grid_large',
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => _viewModeNotifier.value = 'list',
          ),
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () => unawaited(_updateService.checkForUpdate()),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              unawaited(
                Provider.of<ThemeService>(context, listen: false).toggleTheme(),
              );
            },
          ),
          PopupMenuButton<SortOrder>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOrder result) {
              setState(() {
                _sortOrder = result;
              });
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
                hintText: 'Search titles & snippets...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
              enabled: true,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: _notesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
    final isTrashView = _selection.type == SidebarItemType.trash;
    return fluent.NavigationView(
      appBar: fluent.NavigationAppBar(
        title: Text(_getAppBarTitle()),
        actions: fluent.Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            fluent.DropDownButton(
              title: const Icon(fluent.FluentIcons.sort),
              items: [
                fluent.MenuFlyoutItem(
                  text: const Text('Data (Mais Recentes)'),
                  onPressed: () =>
                      setState(() => _sortOrder = SortOrder.dateDesc),
                ),
                fluent.MenuFlyoutItem(
                  text: const Text('Data (Mais Antigas)'),
                  onPressed: () =>
                      setState(() => _sortOrder = SortOrder.dateAsc),
                ),
                fluent.MenuFlyoutItem(
                  text: const Text('Título (A-Z)'),
                  onPressed: () =>
                      setState(() => _sortOrder = SortOrder.titleAsc),
                ),
                fluent.MenuFlyoutItem(
                  text: const Text('Título (Z-A)'),
                  onPressed: () =>
                      setState(() => _sortOrder = SortOrder.titleDesc),
                ),
              ],
            ),
            fluent.CommandBar(
              primaryItems: [
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.view_all),
                  onPressed: () => _viewModeNotifier.value = 'grid_medium',
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.grid_view_large),
                  onPressed: () => _viewModeNotifier.value = 'grid_large',
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.list),
                  onPressed: () => _viewModeNotifier.value = 'list',
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.update_restore),
                  onPressed: () => unawaited(_updateService.checkForUpdate()),
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.brightness),
                  onPressed: () => Provider.of<ThemeService>(
                    context,
                    listen: false,
                  ).toggleTheme(),
                ),
              ],
            ),
          ],
        ),
      ),
      pane: fluent.NavigationPane(
        displayMode: fluent.PaneDisplayMode.compact,
        header: Sidebar(onSelectionChanged: _onSelectionChanged),
      ),
      content: fluent.ScaffoldPage(
        header: Padding(
          padding: const EdgeInsets.all(8),
          child: fluent.TextBox(
            controller: _searchController,
            placeholder: 'Search is temporarily disabled...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(fluent.FluentIcons.search),
            ),
            enabled: false,
          ),
        ),
        content: StreamBuilder<List<Note>>(
          stream: _notesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: fluent.ProgressRing());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyState(
                icon: fluent.FluentIcons.note_forward,
                message: 'No notes here. Try creating one!',
              );
            }
            return _buildNotesList(snapshot.data!);
          },
        ),
        bottomBar: isTrashView
            ? null
            : Padding(
                padding: const EdgeInsets.all(16),
                child: fluent.Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    fluent.FilledButton(
                      onPressed: _createNewNote,
                      child: const fluent.Row(
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
                      child: const fluent.Row(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder is used to rebuild the grid when view mode changes
    return ValueListenableBuilder<String>(
      valueListenable: _viewModeNotifier,
      builder: (context, viewMode, child) {
        if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
          return _buildMaterialUI();
        } else if (Platform.isWindows) {
          return _buildFluentUI();
        } else {
          return _buildMaterialUI();
        }
      },
    );
  }
}
