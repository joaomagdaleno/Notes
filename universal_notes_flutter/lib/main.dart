import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/folder.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Notes',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const NotesScreen(),
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
  Folder? _selectedFolder;
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
    final notes = await _noteRepository.getAllNotes(folderId: _selectedFolder?.id);
    setState(() {
      _notes = notes;
    });
  }

  void _onFolderSelected(Folder? folder) {
    setState(() {
      _selectedFolder = folder;
    });
    _loadNotes();
    Navigator.of(context).pop(); // Close the drawer
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

  Widget _buildMaterialUI() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedFolder?.name ?? 'All Notes'),
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
        ],
      ),
      drawer: Sidebar(onFolderSelected: _onFolderSelected),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: _getGridDelegate(),
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          final note = _notes[index];
          return NoteCard(
            note: note,
            onTap: () => _openNoteEditor(note),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
    return fluent.FluentApp(
      home: fluent.ScaffoldPage(
        header: fluent.PageHeader(
          title: Text(_selectedFolder?.name ?? 'All Notes'),
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
            );
          },
        ),
      ),
    );
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
