import 'dart:io' show Platform;

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'package:universal_notes_flutter/widgets/fluent_note_card.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';
import 'package:window_manager/window_manager.dart';

/// The different view modes for the notes screen.
enum ViewMode {
  /// A small grid view.
  gridSmall,

  /// A medium grid view.
  gridMedium,

  /// A large grid view.
  gridLarge,

  /// A list view.
  list,

  /// A simple list view.
  listSimple,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const _MyAppWithWindowListener());
}

class _MyAppWithWindowListener extends StatefulWidget {
  const _MyAppWithWindowListener();

  @override
  State<_MyAppWithWindowListener> createState() =>
      _MyAppWithWindowListenerState();
}

class _MyAppWithWindowListenerState extends State<_MyAppWithWindowListener>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Platform.isWindows ? const MyFluentApp() : const MyApp();
  }

  @override
  Future<void> onWindowClose() async {
    await NoteRepository.instance.close();
    await windowManager.destroy();
  }
}

/// The main application widget for the Fluent UI design.
class MyFluentApp extends StatelessWidget {
  /// Creates a new instance of [MyFluentApp].
  const MyFluentApp({
    super.key,
    this.noteRepository,
    this.updateService,
    this.navigatorObservers,
  });

  /// The repository for notes.
  final NoteRepository? noteRepository;

  /// The service for updates.
  final UpdateService? updateService;

  /// A list of navigator observers.
  final List<NavigatorObserver>? navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return fluent.FluentApp(
      title: 'Universal Notes',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: fluent.FluentThemeData(
        accentColor: fluent.Colors.blue,
      ),
      darkTheme: fluent.FluentThemeData(
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: NotesScreen(
        noteRepository: noteRepository,
        updateService: updateService,
      ),
      navigatorObservers: navigatorObservers ?? const [],
    );
  }
}

/// The main application widget for the Material Design.
class MyApp extends StatelessWidget {
  /// Creates a new instance of [MyApp].
  const MyApp({
    super.key,
    this.noteRepository,
    this.updateService,
    this.navigatorObservers,
  });

  /// The repository for notes.
  final NoteRepository? noteRepository;

  /// The service for updates.
  final UpdateService? updateService;

  /// A list of navigator observers.
  final List<NavigatorObserver>? navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Notes',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: NotesScreen(
        noteRepository: noteRepository,
        updateService: updateService,
      ),
      navigatorObservers: navigatorObservers ?? const [],
    );
  }
}

/// The main screen that displays the list of notes.
class NotesScreen extends StatefulWidget {
  /// Creates a new instance of [NotesScreen].
  NotesScreen({
    super.key,
    this.updateService,
    this.noteRepository,
    this.notesFuture,
    this.debugPlatform,
  });

  /// The service to use for checking for updates.
  final UpdateService? updateService;

  /// The repository to use for fetching notes.
  final NoteRepository? noteRepository;

  /// An optional future for the notes, used for testing.
  final Future<List<Note>>? notesFuture;

  /// Optional platform override for testing purposes.
  final TargetPlatform? debugPlatform;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late Future<List<Note>> _notesFuture;
  bool _isNavigationRailExpanded = false;
  int _selectedIndex = 0;
  ViewMode _viewMode = ViewMode.gridMedium;

  /// Returns whether the platform is Windows, considering debugPlatform
  /// override.
  bool get _isWindows => widget.debugPlatform != null
      ? widget.debugPlatform == TargetPlatform.windows
      : Platform.isWindows;

  NoteRepository get _noteRepository =>
      widget.noteRepository ?? NoteRepository.instance;

  @override
  void initState() {
    super.initState();
    _notesFuture = widget.notesFuture ?? _noteRepository.getAllNotes();
    // Use a post-frame callback to ensure the Scaffold is available.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check for updates on all platforms
      await UpdateHelper.checkForUpdate(
        context,
        updateService: widget.updateService,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<Note> _updateNote(Note note) async {
    // Check if the note already exists
    final notes = await _notesFuture;
    final index = notes.indexWhere((n) => n.id == note.id);
    Note savedNote;
    if (index != -1) {
      await _noteRepository.updateNote(note);
      savedNote = note;
    } else {
      final newId = await _noteRepository.insertNote(note);
      savedNote = note.copyWith(id: newId);
    }
    setState(() {
      _notesFuture = _noteRepository.getAllNotes();
    });
    return savedNote;
  }

  Future<void> _deleteNote(Note note) async {
    await _noteRepository.deleteNote(note.id);
    setState(() {
      _notesFuture = _noteRepository.getAllNotes();
    });
  }

  void _cycleViewMode() {
    setState(() {
      final nextIndex = (_viewMode.index + 1) % ViewMode.values.length;
      _viewMode = ViewMode.values[nextIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isWindows) {
      final notesBody = fluent.ScaffoldPage(
        header: fluent.CommandBar(
          mainAxisAlignment: fluent.MainAxisAlignment.end,
          primaryItems: [
            fluent.CommandBarButton(
              icon: const fluent.Icon(fluent.FluentIcons.add),
              label: const Text('Nova nota'),
              onPressed: () async {
                await Navigator.of(context).push(
                  fluent.FluentPageRoute<void>(
                    builder: (context) => NoteEditorScreen(onSave: _updateNote),
                  ),
                );
              },
            ),
            fluent.CommandBarButton(
              icon: const fluent.Icon(fluent.FluentIcons.view),
              label: const Text('Mudar Visualização'),
              onPressed: _cycleViewMode,
            ),
            fluent.CommandBarButton(
              icon: const fluent.Icon(fluent.FluentIcons.search),
              label: const Text('Pesquisar'),
              onPressed: () {},
            ),
            fluent.CommandBarButton(
              icon: const fluent.Icon(fluent.FluentIcons.sort),
              label: const Text('Ordenar'),
              onPressed: () {},
            ),
          ],
        ),
        content: _buildBody(),
      );

      return fluent.NavigationView(
        appBar: const fluent.NavigationAppBar(),
        pane: fluent.NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
          items: [
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.document),
              title: const Text('Todas as notas'),
              body: notesBody,
              onTap: () {},
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.favorite_star),
              title: const Text('Favoritos'),
              body: notesBody,
              onTap: () {},
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.lock),
              title: const Text('Notas bloqueadas'),
              body: notesBody,
              onTap: () {},
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.share),
              title: const Text('Notas compartilhadas'),
              body: notesBody,
              onTap: () {},
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.delete),
              title: const Text('Lixeira'),
              body: notesBody,
              onTap: () {},
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.folder_open),
              title: const Text('Pastas'),
              body: notesBody,
              onTap: () {},
            ),
          ],
          footerItems: [
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.settings),
              title: const Text('Configurações'),
              body: const SettingsScreen(),
              onTap: () {},
            ),
          ],
        ),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return Scaffold(
            appBar: AppBar(
              leading: isMobile
                  ? Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    )
                  : null,
              title: Center(
                child: Text(_getAppBarTitle()),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.view_agenda_outlined),
                  onPressed: _cycleViewMode,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {},
                  itemBuilder: (BuildContext context) {
                    return {'Ordenar por', 'Outra Ação'}.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
            drawer: isMobile
                ? Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        const DrawerHeader(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                          ),
                          child: Text('Universal Notes'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.notes_outlined),
                          title: const Text('Todas as notas'),
                          selected: _selectedIndex == 0,
                          onTap: () {
                            setState(() => _selectedIndex = 0);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.star_outline),
                          title: const Text('Favoritos'),
                          selected: _selectedIndex == 1,
                          onTap: () {
                            setState(() => _selectedIndex = 1);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.lock_outline),
                          title: const Text('Notas bloqueadas'),
                          selected: _selectedIndex == 2,
                          onTap: () {
                            setState(() => _selectedIndex = 2);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.share_outlined),
                          title: const Text('Notas compartilhadas'),
                          selected: _selectedIndex == 3,
                          onTap: () {
                            setState(() => _selectedIndex = 3);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('Lixeira'),
                          selected: _selectedIndex == 4,
                          onTap: () {
                            setState(() => _selectedIndex = 4);
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: const Text('Pastas'),
                          selected: _selectedIndex == 5,
                          onTap: () {
                            setState(() => _selectedIndex = 5);
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Configurações'),
                          onTap: () async {
                            Navigator.pop(context); // Close the drawer
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  )
                : null,
            body: isMobile
                ? _buildBody()
                : Row(
                    children: [
                      NavigationRail(
                        leading: IconButton(
                          icon: Icon(
                            _isNavigationRailExpanded
                                ? Icons.menu_open
                                : Icons.menu,
                          ),
                          onPressed: () {
                            setState(() {
                              _isNavigationRailExpanded =
                                  !_isNavigationRailExpanded;
                            });
                          },
                        ),
                        extended: _isNavigationRailExpanded,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (int index) async {
                          setState(() {
                            _selectedIndex = index;
                          });
                          if (index == 6) {
                            // Index of settings
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          }
                        },
                        destinations: const <NavigationRailDestination>[
                          NavigationRailDestination(
                            icon: const Icon(Icons.notes_outlined),
                            selectedIcon: const Icon(Icons.notes),
                            label: const Text('Todas as notas'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.star_outline),
                            selectedIcon: const Icon(Icons.star),
                            label: const Text('Favoritos'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.lock_outline),
                            selectedIcon: const Icon(Icons.lock),
                            label: const Text('Notas bloqueadas'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.share_outlined),
                            selectedIcon: const Icon(Icons.share),
                            label: const Text('Notas compartilhadas'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.delete_outline),
                            selectedIcon: const Icon(Icons.delete),
                            label: const Text('Lixeira'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.folder_outlined),
                            selectedIcon: const Icon(Icons.folder),
                            label: const Text('Pastas'),
                          ),
                          NavigationRailDestination(
                            icon: const Icon(Icons.settings_outlined),
                            selectedIcon: const Icon(Icons.settings),
                            label: const Text('Configurações'),
                          ),
                        ],
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                      Expanded(
                        child: _buildBody(),
                      ),
                    ],
                  ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => NoteEditorScreen(onSave: _updateNote),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          );
        },
      );
    }
  }

  Widget _buildBody() {
    return FutureBuilder<List<Note>>(
      future: _notesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Nenhuma nota encontrada.'));
        }

        final allNotes = snapshot.data!;
        List<Note> visibleNotes;

        switch (_selectedIndex) {
          case 1: // Favorites
            visibleNotes = allNotes
                .where((n) => n.isFavorite && !n.isInTrash)
                .toList();
          case 4: // Trash
            visibleNotes = allNotes.where((n) => n.isInTrash).toList();
          default: // All notes
            visibleNotes = allNotes.where((n) => !n.isInTrash).toList();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (_viewMode == ViewMode.list) {
              return _buildGridView(
                2,
                0.75,
                visibleNotes,
              ); // 2 columns, elongated aspect ratio
            } else if (_viewMode == ViewMode.listSimple) {
              return ListView.builder(
                itemCount: visibleNotes.length,
                itemBuilder: (context, index) {
                  return NoteSimpleListTile(
                    note: visibleNotes[index],
                    onSave: _updateNote,
                    onDelete: _deleteNote,
                  );
                },
              );
            } else {
              int crossAxisCount;
              double childAspectRatio;

              if (_isWindows) {
                // Windows-specific responsive logic
                if (_viewMode == ViewMode.gridSmall) {
                  crossAxisCount = (constraints.maxWidth / 320).floor().clamp(
                    1,
                    5,
                  );
                  childAspectRatio = 0.7;
                } else if (_viewMode == ViewMode.gridMedium) {
                  crossAxisCount = (constraints.maxWidth / 240).floor().clamp(
                    2,
                    7,
                  );
                  childAspectRatio = 0.7;
                } else {
                  // gridLarge
                  crossAxisCount = (constraints.maxWidth / 180).floor().clamp(
                    3,
                    10,
                  );
                  childAspectRatio = 0.7;
                }
              } else {
                // Existing logic for Android/other platforms
                if (_viewMode == ViewMode.gridSmall) {
                  crossAxisCount = (constraints.maxWidth / 300).floor().clamp(
                    2,
                    7,
                  );
                  childAspectRatio = 0.75;
                } else if (_viewMode == ViewMode.gridMedium) {
                  crossAxisCount = (constraints.maxWidth / 200).floor().clamp(
                    2,
                    7,
                  );
                  childAspectRatio = 1 / 1.414;
                } else {
                  // gridLarge
                  crossAxisCount = (constraints.maxWidth / 150).floor().clamp(
                    1,
                    5,
                  );
                  childAspectRatio = 1 / 1.414;
                }
              }

              return _buildGridView(
                crossAxisCount,
                childAspectRatio,
                visibleNotes,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildGridView(
    int crossAxisCount,
    double childAspectRatio,
    List<Note> notes,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        if (_isWindows) {
          return FluentNoteCard(
            note: notes[index],
            onSave: _updateNote,
            onDelete: _deleteNote,
            onTap: () async {
              await Navigator.of(context).push(
                fluent.FluentPageRoute<void>(
                  builder: (context) => NoteEditorScreen(
                    note: notes[index],
                    onSave: _updateNote,
                  ),
                ),
              );
            },
          );
        } else {
          return NoteCard(
            note: notes[index],
            onSave: _updateNote,
            onDelete: _deleteNote,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => NoteEditorScreen(
                    note: notes[index],
                    onSave: _updateNote,
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Todas as notas';
      case 1:
        return 'Favoritos';
      case 2:
        return 'Notas bloqueadas';
      case 3:
        return 'Notas compartilhadas';
      case 4:
        return 'Lixeira';
      case 5:
        return 'Pastas';
      default:
        return 'Universal Notes';
    }
  }
}
