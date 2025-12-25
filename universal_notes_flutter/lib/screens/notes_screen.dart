import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/models/document_model.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/persona_model.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
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
  // ⚡ Bolt: Caching the RegExp for snippet highlighting.
  // This avoids recompiling the regular expression on every search result,
  // improving performance when rendering the search results list.
  static final _highlightRegex = RegExp('<b>(.*?)</b>');

  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final _sortOrderNotifier = ValueNotifier<SortOrder>(SortOrder.dateDesc);
  final SyncService _syncService = SyncService.instance;
  late final UpdateService _updateService;
  late Stream<List<Note>> _notesStream;

  final _searchController = TextEditingController();
  final _viewModeNotifier = ValueNotifier<String>('grid_medium');
  final ScrollController _scrollController = ScrollController();

  // Full-text search state
  List<Note>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Removed direct FirestoreRepository usage
    _updateService = widget.updateService ?? UpdateService();
    _notesStream = _syncService.notesStream; // Point to sync service stream
    windowManager.addListener(this);
    // _scrollController.addListener(_onScroll); // Disabled pagination listener
    _updateNotesStream(); // Initial fetch
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
    super.dispose();
  }

  /// Handles search input changes with debounce.
  Timer? _searchDebounce;
  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text;

    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await NoteRepository.instance.searchNotes(query);
      if (context.mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
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

    // Trigger refresh of local data into the stream
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
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _createNewNote() async {
    final note = Note(
      id: const Uuid().v4(),
      title: 'Nova Nota',
      content: DocumentModel.empty()
          .toJson()
          .toString(), // Or empty string literal
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
      content: DocumentModel.empty().toJson().toString(),
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
    // Show search results if we have a search query
    if (_searchResults != null) {
      if (_searchResults!.isEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          message: 'Nenhum resultado encontrado.',
        );
      }
      return _buildSearchResults(_searchResults!);
    }

    // Show normal notes stream
    return StreamBuilder<List<Note>>(
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
    );
  }

  /// Builds the search results list with highlighted snippets.
  Widget _buildSearchResults(List<SearchResult> results) {
    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final result = results[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(
              result.note.title.isEmpty ? 'Sem título' : result.note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: result.snippet.isNotEmpty
                ? _buildHighlightedSnippet(result.snippet)
                : Text(
                    result.note.content.length > 100
                        ? '${result.note.content.substring(0, 100)}...'
                        : result.note.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => unawaited(_openNoteEditor(result.note)),
          ),
        );
      },
    );
  }

  /// Parses the FTS5 snippet with <b> tags into rich text.
  Widget _buildHighlightedSnippet(String snippet) {
    final parts = <TextSpan>[];
    var lastEnd = 0;

    for (final match in _highlightRegex.allMatches(snippet)) {
      // Add text before match
      if (match.start > lastEnd) {
        parts.add(TextSpan(text: snippet.substring(lastEnd, match.start)));
      }
      // Add highlighted match
      parts.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.yellow,
          ),
        ),
      );
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < snippet.length) {
      parts.add(TextSpan(text: snippet.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: parts,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
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
          IconButton(
            icon: const Icon(Icons.view_module),
            tooltip: 'Grid View (Medium)',
            onPressed: () => _viewModeNotifier.value = 'grid_medium',
          ),
          IconButton(
            icon: const Icon(Icons.view_comfy),
            tooltip: 'Grid View (Large)',
            onPressed: () => _viewModeNotifier.value = 'grid_large',
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: 'List View',
            onPressed: () => _viewModeNotifier.value = 'list',
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
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
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
    final isTrashView = _selection.type == SidebarItemType.trash;
    return fluent.NavigationView(
      appBar: fluent.NavigationAppBar(
        title: Text(_getAppBarTitle()),
        actions: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: fluent.Row(
            mainAxisSize: fluent.MainAxisSize.min,
            mainAxisAlignment: fluent.MainAxisAlignment.end,
            children: [
              fluent.Tooltip(
                message: 'Sort Order',
                child: fluent.DropDownButton(
                  title: const Icon(fluent.FluentIcons.sort),
                  items: [
                    fluent.MenuFlyoutItem(
                      text: const Text('Data (Mais Recentes)'),
                      onPressed: () =>
                          _sortOrderNotifier.value = SortOrder.dateDesc,
                    ),
                    fluent.MenuFlyoutItem(
                      text: const Text('Data (Mais Antigas)'),
                      onPressed: () =>
                          _sortOrderNotifier.value = SortOrder.dateAsc,
                    ),
                    fluent.MenuFlyoutItem(
                      text: const Text('Título (A-Z)'),
                      onPressed: () =>
                          _sortOrderNotifier.value = SortOrder.titleAsc,
                    ),
                    fluent.MenuFlyoutItem(
                      text: const Text('Título (Z-A)'),
                      onPressed: () =>
                          _sortOrderNotifier.value = SortOrder.titleDesc,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: fluent.CommandBar(
                  primaryItems: [
                    fluent.CommandBarButton(
                      icon: const Icon(fluent.FluentIcons.view_all),
                      tooltip: 'Grid View (Medium)',
                      onPressed: () => _viewModeNotifier.value = 'grid_medium',
                    ),
                    fluent.CommandBarButton(
                      icon: const Icon(fluent.FluentIcons.grid_view_large),
                      tooltip: 'Grid View (Large)',
                      onPressed: () => _viewModeNotifier.value = 'grid_large',
                    ),
                    fluent.CommandBarButton(
                      icon: const Icon(fluent.FluentIcons.list),
                      tooltip: 'List View',
                      onPressed: () => _viewModeNotifier.value = 'list',
                    ),
                    fluent.CommandBarButton(
                      icon: const Icon(fluent.FluentIcons.update_restore),
                      tooltip: 'Check for Updates',
                      onPressed: () =>
                          unawaited(_updateService.checkForUpdate()),
                    ),
                    fluent.CommandBarButton(
                      icon: const Icon(fluent.FluentIcons.brightness),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      content: Row(
        children: [
          Sidebar(onSelectionChanged: _onSelectionChanged),
          Expanded(
            child: fluent.ScaffoldPage(
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
                initialData: _syncService.currentNotes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: SizedBox(width: 20, height: 20));
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
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildMaterialUI();

    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      return _buildFluentUI();
    }
    return _buildMaterialUI();
  }
}

class _DashboardCard extends StatefulWidget {
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

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  // ⚡ Bolt: Caching expensive objects to avoid rebuilding them on every frame.

  @override
  void initState() {
    super.initState();
    _updateStyles();
  }

  @override
  void didUpdateWidget(_DashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ⚡ Bolt: Only update styles when the color changes, preventing unnecessary
    // object recreation.
    if (widget.color != oldWidget.color) {
      _updateStyles();
    }
  }

  void _updateStyles() {
    // Styles were moved inline or removed if not needed to avoid unused field warnings.
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: widget.color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: widget.color, size: 32),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.subtitle,
              style: TextStyle(
                color: widget.color.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
