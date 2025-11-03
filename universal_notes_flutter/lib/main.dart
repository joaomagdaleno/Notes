import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/data/sample_notes.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';
import 'screens/settings_screen.dart';
import 'dart:io' show Platform;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

enum ViewMode { gridSmall, gridMedium, gridLarge, list, listSimple }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true,
  );
  FlutterDownloader.registerCallback(downloadCallback);

  if (Platform.isWindows) {
    runApp(const MyFluentApp());
  } else {
    runApp(const MyApp());
  }
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

class MyFluentApp extends StatelessWidget {
  const MyFluentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return fluent.FluentApp(
      title: 'Universal Notes',
      theme: fluent.FluentThemeData(
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.light,
      ),
      darkTheme: fluent.FluentThemeData(
        accentColor: fluent.Colors.blue,
        brightness: fluent.Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const NotesScreen(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
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
      themeMode: ThemeMode.system,
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late List<Note> _notes;
  bool _isNavigationRailExpanded = false;
  int _selectedIndex = 0;
  ViewMode _viewMode = ViewMode.gridMedium;
  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();
    _notes = List.from(sampleNotes);
    _bindBackgroundIsolate();
    // Use a post-frame callback to ensure the Scaffold is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateHelper.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      final status = DownloadTaskStatus.fromInt(data[1]);
      final String taskId = data[0];

      if (status == DownloadTaskStatus.complete) {
        _openDownloadedFile(taskId);
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> _openDownloadedFile(String taskId) async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(query: 'SELECT * FROM task WHERE task_id="$taskId"');
    if (tasks != null && tasks.isNotEmpty) {
      final task = tasks.first;
      OpenFile.open('${task.savedDir}/${task.filename}');
    }
  }

  void _updateNote(Note note) {
    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
      } else {
        _notes.insert(0, note);
      }
    });
  }

  void _deleteNote(Note note) {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
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
    if (Platform.isWindows) {
      return fluent.NavigationView(
        pane: fluent.NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
          displayMode: fluent.PaneDisplayMode.auto,
          items: [
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.document),
              title: const Text('Todas as notas'),
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.favorite_star),
              title: const Text('Favoritos'),
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.lock),
              title: const Text('Notas bloqueadas'),
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.share),
              title: const Text('Notas compartilhadas'),
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.delete),
              title: const Text('Lixeira'),
            ),
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.folder_open),
              title: const Text('Pastas'),
            ),
          ],
          footerItems: [
            fluent.PaneItem(
              icon: const fluent.Icon(fluent.FluentIcons.settings),
              title: const Text('Configurações'),
            ),
          ],
        ),
        content: fluent.NavigationBody(
          index: _selectedIndex,
          children: [
            _buildBody(),
            _buildBody(),
            _buildBody(),
            _buildBody(),
            _buildBody(),
            _buildBody(),
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
                          onTap: () {
                            Navigator.pop(context); // Close the drawer
                            Navigator.of(context).push(
                              MaterialPageRoute(
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
                          icon: Icon(_isNavigationRailExpanded ? Icons.menu_open : Icons.menu),
                          onPressed: () {
                            setState(() {
                              _isNavigationRailExpanded = !_isNavigationRailExpanded;
                            });
                          },
                        ),
                        extended: _isNavigationRailExpanded,
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (int index) {
                          setState(() {
                            _selectedIndex = index;
                          });
                          if (index == 6) { // Index of settings
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          }
                        },
                        destinations: const <NavigationRailDestination>[
                          NavigationRailDestination(
                            icon: Icon(Icons.notes_outlined),
                            selectedIcon: Icon(Icons.notes),
                            label: Text('Todas as notas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.star_outline),
                            selectedIcon: Icon(Icons.star),
                            label: Text('Favoritos'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.lock_outline),
                            selectedIcon: Icon(Icons.lock),
                            label: Text('Notas bloqueadas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.share_outlined),
                            selectedIcon: Icon(Icons.share),
                            label: Text('Notas compartilhadas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.delete_outline),
                            selectedIcon: Icon(Icons.delete),
                            label: Text('Lixeira'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.folder_outlined),
                            selectedIcon: Icon(Icons.folder),
                            label: Text('Pastas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.settings_outlined),
                            selectedIcon: Icon(Icons.settings),
                            label: Text('Configurações'),
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
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
    List<Note> visibleNotes;

    switch (_selectedIndex) {
      case 1: // Favorites
        visibleNotes =
            _notes.where((n) => n.isFavorite && !n.isInTrash).toList();
        break;
      case 4: // Trash
        visibleNotes = _notes.where((n) => n.isInTrash).toList();
        break;
      default: // All notes
        visibleNotes = _notes.where((n) => !n.isInTrash).toList();
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewMode == ViewMode.list) {
          return _buildGridView(
              2, 0.75, visibleNotes); // 2 columns, elongated aspect ratio
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

          if (_viewMode == ViewMode.gridSmall) {
            crossAxisCount = (constraints.maxWidth / 300).floor().clamp(2, 7);
            childAspectRatio = 0.75;
          } else if (_viewMode == ViewMode.gridMedium) {
            crossAxisCount = (constraints.maxWidth / 200).floor().clamp(2, 7);
            childAspectRatio = 1 / 1.414; // A4 aspect ratio
          } else {
            // gridLarge
            crossAxisCount = (constraints.maxWidth / 150).floor().clamp(1, 5);
            childAspectRatio = 1 / 1.414; // A4 aspect ratio
          }

          return _buildGridView(crossAxisCount, childAspectRatio, visibleNotes);
        }
      },
    );
  }

  Widget _buildGridView(
      int crossAxisCount, double childAspectRatio, List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        return NoteCard(
          note: notes[index],
          onSave: _updateNote,
          onDelete: _deleteNote,
        );
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
