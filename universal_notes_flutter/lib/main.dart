import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package.flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/services/theme_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/styles/app_themes.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(800, 600),
      center: true,
      minimumSize: Size(400, 300),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Universal Notes',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeService.themeMode,
          home: const NotesScreen(),
        );
      },
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with WindowListener {
  List<Note> _notes = [];
  SidebarSelection _selection = const SidebarSelection(SidebarItemType.all);
  final NoteRepository _noteRepository = NoteRepository.instance;
  final UpdateService _updateService = UpdateService();
  final BackupService _backupService = BackupService();

  String _viewMode = 'grid_medium';

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadNotes();
    _runAutoBackupIfNeeded();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _loadNotes() async {
    List<Note> notes;
    switch (_selection.type) {
      case SidebarItemType.all:
        notes = await _noteRepository.getAllNotes();
        break;
      case SidebarItemType.favorites:
        notes = await _noteRepository.getAllNotes(isFavorite: true);
        break;
      case SidebarItemType.trash:
        notes = await _noteRepository.getAllNotes(isInTrash: true);
        break;
      case SidebarItemType.folder:
        notes = await _noteRepository.getAllNotes(folderId: _selection.folder!.id);
        break;
    }
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
    final folderId = _selection.type == SidebarItemType.folder ? _selection.folder?.id : null;
     final newNote = Note(
      id: const Uuid().v4(),
      title: '',
      content: '',
      date: DateTime.now(),
      folderId: folderId,
    );
    _openNoteEditor(newNote);
  }

  void _openNoteEditor(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          onSave: (updatedNote) async {
            await _noteRepository.insertNote(updatedNote);
            _loadNotes();
            return updatedNote;
          },
        ),
      ),
    );
  }

  Future<void> _runAutoBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackupMillis = prefs.getInt('last_backup_date') ?? 0;
    final lastBackupDate = DateTime.fromMillisecondsSinceEpoch(lastBackupMillis);

    if (DateTime.now().difference(lastBackupDate).inHours >= 24) {
      try {
        await _backupService.exportDatabaseToJson();
        await prefs.setInt('last_backup_date', DateTime.now().millisecondsSinceEpoch);
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
  void onWindowClose() {
    final isPreventClose = windowManager.isPreventClose();
    if (isPreventClose) {
      windowManager.hide();
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    await _noteRepository.updateNote(note.copyWith(isFavorite: !note.isFavorite));
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
    final bool isTrashView = _selection.type == SidebarItemType.trash;
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
            onPressed: () => _updateService.checkForUpdates(context),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeService>(context, listen: false).toggleTheme();
            }
          ),
        ],
      ),
      drawer: Sidebar(onSelectionChanged: _onSelectionChanged),
      body: GridView.builder(
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
              child: Icon(isTrashView ? Icons.restore_from_trash : Icons.favorite, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Icon(isTrashView ? Icons.delete_forever : Icons.delete, color: Colors.white),
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
            ),
          );
        },
      ),
      floatingActionButton: isTrashView ? null : FloatingActionButton(
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  SliverGridDelegate _getGridDelegate() {
    switch (_viewMode) {
      case 'grid_large':
        return const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300, childAspectRatio: 3/2, crossAxisSpacing: 8, mainAxisSpacing: 8);
      case 'list':
         return const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, childAspectRatio: 5/1);
      default: // grid_medium
        return const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200, childAspectRatio: 3/2, crossAxisSpacing: 8, mainAxisSpacing: 8);
    }
  }

  Widget _buildFluentUI() {
    // This UI does not support Dismissible well. We'll stick to Material for now.
    return _buildMaterialUI();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return _buildMaterialUI();
    } else {
      return _buildMaterialUI();
    }
  }
}
