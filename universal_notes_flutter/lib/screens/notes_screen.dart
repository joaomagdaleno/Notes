import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/quick_note_editor.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

class NotesScreen extends StatefulWidget {
  final NoteRepository? noteRepository;
  final UpdateService? updateService;

  const NotesScreen({
    super.key,
    this.noteRepository,
    this.updateService,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

enum SortOrder { dateDesc, dateAsc, titleAsc, titleDesc }

class _NotesScreenState extends State<NotesScreen> with WindowListener {
  List<Note> _notes = [];
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  SortOrder _sortOrder = SortOrder.dateDesc;
  late final NoteRepository _noteRepository;
  late final UpdateService _updateService;
  final BackupService _backupService = BackupService();

  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchTerm = '';

  String _viewMode = 'grid_medium';

  @override
  void initState() {
    super.initState();
    _noteRepository = widget.noteRepository ?? NoteRepository.instance;
    _updateService = widget.updateService ?? UpdateService();
    windowManager.addListener(this);
    _loadNotes();
    _runAutoBackupIfNeeded();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchTerm != _searchController.text) {
        setState(() {
          _searchTerm = _searchController.text;
        });
        _loadNotes();
      }
    });
  }

  Future<void> _loadNotes() async {
    List<Note> notes;
    if (_searchTerm.isNotEmpty) {
      notes = await _noteRepository.searchAllNotes(_searchTerm);
    } else {
      switch (_selection.type) {
        case SidebarItemType.all:
          notes = await _noteRepository.getAllNotes();
        case SidebarItemType.favorites:
          notes = await _noteRepository.getAllNotes(isFavorite: true);
        case SidebarItemType.trash:
          notes = await _noteRepository.getAllNotes(isInTrash: true);
        case SidebarItemType.folder:
          notes = await _noteRepository.getAllNotes(
            folderId: _selection.folder!.id,
          );
      }
    }

    // --- Sorting ---
    notes.sort((a, b) {
      switch (_sortOrder) {
        case SortOrder.dateAsc:
          return a.date.compareTo(b.date);
        case SortOrder.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortOrder.titleDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        default: // dateDesc
          return b.date.compareTo(a.date);
      }
    });

    setState(() {
      _notes = notes;
    });
  }

  void _onSelectionChanged(SidebarSelection selection) {
    setState(() {
      _selection = selection;
    });
    _loadNotes();
    Navigator.of(context).pop(); // Close the drawer
  }

  void _createNewNote() {
    final folderId = _selection.type == SidebarItemType.folder
        ? _selection.folder?.id
        : null;
    final newNote = Note(
      id: const Uuid().v4(),
      title: '',
      content: '',
      date: DateTime.now(),
      folderId: folderId,
    );
    _openNoteEditor(newNote);
  }

  Future<void> _openNoteEditor(Note note) async {
    final noteWithContent = await _noteRepository.getNoteWithContent(note.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: noteWithContent,
          onSave: (updatedNote) async {
            // When a draft is properly saved, it's no longer a draft.
            await _noteRepository.insertNote(
              updatedNote.copyWith(isDraft: false),
            );
            _loadNotes();
            return updatedNote;
          },
        ),
      ),
    );
  }

  void _abrirEditorRapido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => QuickNoteEditor(
        onSave: _processarNotaRapida,
      ),
    );
  }

  Future<void> _processarNotaRapida(String content) async {
    final newNote = Note(
      id: const Uuid().v4(),
      title: content.split('\n').first,
      content: content,
      date: DateTime.now(),
      isDraft: true,
      folderId: _selection.type == SidebarItemType.folder
          ? _selection.folder?.id
          : null,
    );
    await _noteRepository.insertNote(newNote);
    _loadNotes();
  }

  Future<void> _runAutoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupMillis = prefs.getInt('last_backup_date') ?? 0;
    final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(
      lastBackupMillis,
    );

    if (DateTime.now().difference(lastBackupDate).inHours >= 24) {
      try {
        await _backupService.exportDatabaseToJson();
        await prefs.setInt(
          'last_backup_date',
          DateTime.now().millisecondsSinceEpoch,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Automatic backup completed.')),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('Auto backup failed: $e');
        }
      }
    }
  }

  @override
  Future<void> onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await _noteRepository.close();
      windowManager.hide();
    }
    super.onWindowClose();
  }

  Future<void> _toggleFavorite(Note note) async {
    await _noteRepository.updateNote(
      note.copyWith(isFavorite: !note.isFavorite),
    );
    _loadNotes();
  }

  Future<void> _moveToTrash(Note note) async {
    await _noteRepository.updateNote(note.copyWith(isInTrash: true));
    _loadNotes();
  }

  Future<void> _restoreNote(Note note) async {
    await _noteRepository.restoreNoteFromTrash(note.id);
    _loadNotes();
  }

  Future<void> _deletePermanently(Note note) async {
    await _noteRepository.deleteNotePermanently(note.id);
    _loadNotes();
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
    }
  }

  Widget _buildMaterialUI() {
    final isTrashView = _selection.type == SidebarItemType.trash;
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () => setState(() => _viewMode = 'grid_medium'),
          ),
          IconButton(
            icon: const Icon(Icons.view_comfy),
            onPressed: () => setState(() => _viewMode = 'grid_large'),
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () => setState(() => _viewMode = 'list'),
          ),
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () => _updateService.checkForUpdate(),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeService>(context, listen: false).toggleTheme();
            },
          ),
          PopupMenuButton<SortOrder>(
            icon: const Icon(Icons.sort),
            onSelected: (SortOrder result) {
              setState(() {
                _sortOrder = result;
              });
              _loadNotes();
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
                suffixIcon: _searchTerm.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: _getGridDelegate(),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
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
                        _restoreNote(note);
                      } else {
                        _deletePermanently(note);
                      }
                    } else {
                      if (direction == DismissDirection.startToEnd) {
                        _toggleFavorite(note);
                      } else {
                        _moveToTrash(note);
                      }
                    }
                  },
                  child: NoteCard(
                    note: note,
                    onTap: () => _openNoteEditor(note),
                    onSave: (note) async {
                      await _noteRepository.updateNote(note);
                      _loadNotes();
                      return note;
                    },
                    onDelete: (note) {
                      _deletePermanently(note);
                    },
                  ),
                );
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

  SliverGridDelegate _getGridDelegate() {
    switch (_viewMode) {
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
                  onPressed: () => setState(() {
                    _sortOrder = SortOrder.dateDesc;
                    _loadNotes();
                  }),
                ),
                fluent.MenuFlyoutItem(
                  text: const Text('Data (Mais Antigas)'),
                  onPressed: () => setState(() {
                    _sortOrder = SortOrder.dateAsc;
                    _loadNotes();
                  }),
                ),
                fluent.MenuFlyoutItem(
                  text: const Text('Título (A-Z)'),
                  onPressed: () => setState(() {
                    _sortOrder = SortOrder.titleAsc;
                    _loadNotes();
                  }),
                ),
                fluent.MenuFlyoutItem(
                  text: const Text('Título (Z-A)'),
                  onPressed: () => setState(() {
                    _sortOrder = SortOrder.titleDesc;
                    _loadNotes();
                  }),
                ),
              ],
            ),
            fluent.CommandBar(
              primaryItems: [
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.view_all),
                  onPressed: () => setState(() => _viewMode = 'grid_medium'),
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.grid_view_large),
                  onPressed: () => setState(() => _viewMode = 'grid_large'),
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.list),
                  onPressed: () => setState(() => _viewMode = 'list'),
                ),
                fluent.CommandBarButton(
                  icon: const Icon(fluent.FluentIcons.update_restore),
                  onPressed: () => _updateService.checkForUpdate(),
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
            placeholder: 'Buscar em todas as notas...',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(fluent.FluentIcons.search),
            ),
            suffix: _searchTerm.isNotEmpty
                ? fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.clear),
                    onPressed: _searchController.clear,
                  )
                : null,
          ),
        ),
        content: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: _getGridDelegate(),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return NoteCard(
              note: note,
              onTap: () => _openNoteEditor(note),
              onSave: (note) async {
                await _noteRepository.updateNote(note);
                _loadNotes();
                return note;
              },
              onDelete: (note) {
                _deletePermanently(note);
              },
            );
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
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return _buildMaterialUI();
    } else if (Platform.isWindows) {
      return _buildFluentUI();
    } else {
      return _buildMaterialUI();
    }
  }
}
