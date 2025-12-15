import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/sidebar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:uuid/uuid.dart';

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
  runApp(const MyApp());
}

/// The main application widget.
class MyApp extends StatelessWidget {
  /// Creates a new instance of [MyApp].
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NotesScreen(),
    );
  }
}

/// The main screen of the application, displaying a list of notes.
class NotesScreen extends StatefulWidget {
  /// Creates a new instance of [NotesScreen].
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with WindowListener {
  List<Note> _notes = [];
  Folder? _selectedFolder;
  final NoteRepository _noteRepository = NoteRepository.instance;
  final UpdateService _updateService = UpdateService();
  final BackupService _backupService = BackupService();
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _loadNotes();
    _runAutoBackupIfNeeded();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _initSystemTray();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final notes = await _noteRepository.getAllNotes(folderId: _selectedFolder?.id);
    setState(() {
      _notes = notes;
    });
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
        // Handle backup error silently or log it
        if (kDebugMode) {
          print('Auto backup failed: $e');
        }
      }
    }
  }

  Future<void> _initSystemTray() async {
    await _systemTray.initSystemTray(
      iconPath: Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );
    final menu = Menu()
      ..buildFrom([
        MenuItemLabel(label: 'Show', onClicked: (menuItem) => _appWindow.show()),
        MenuItemLabel(label: 'Hide', onClicked: (menuItem) => _appWindow.hide()),
        MenuItemLabel(label: 'Exit', onClicked: (menuItem) => _appWindow.close()),
      ]);
    await _systemTray.setContextMenu(menu);
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        _appWindow.show();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }

  @override
  void onWindowClose() {
    final isPreventClose = windowManager.isPreventClose();
    if (isPreventClose) {
      _appWindow.hide();
    }
  }

  void _onFolderSelected(Folder? folder) {
    setState(() {
      _selectedFolder = folder;
    });
    _loadNotes();
  }

  void _createNewNote() {
     final newNote = Note(
      id: const Uuid().v4(),
      title: '',
      content: '',
      date: DateTime.now(),
      folderId: _selectedFolder?.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedFolder?.name ?? 'All Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () => _updateService.checkForUpdates(context),
          ),
        ],
      ),
      body: Row(
        children: [
          Sidebar(onFolderSelected: _onFolderSelected),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 3 / 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return NoteCard(
                  note: note,
                  onTap: () => _openNoteEditor(note),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
