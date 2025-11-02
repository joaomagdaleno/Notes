import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/data/sample_notes.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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
  String _activeFilter = 'all'; // 'all' or 'favorites'
  bool _isSelectionMode = false;
  final Set<String> _selectedNotes = {};

  @override
  void initState() {
    super.initState();
    _notes = List.from(sampleNotes);
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

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _isSelectionMode = false;
      _selectedNotes.clear();
    });
  }

  void _toggleSelection(String noteId) {
    setState(() {
      if (_selectedNotes.contains(noteId)) {
        _selectedNotes.remove(noteId);
      } else {
        _selectedNotes.add(noteId);
      }
      if (_selectedNotes.isEmpty) {
        _isSelectionMode = false;
      } else {
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedNotes.length == _notes.where((note) => _activeFilter == 'all' || note.isFavorite).length) {
        _selectedNotes.clear();
      } else {
        _selectedNotes.addAll(_notes.where((note) => _activeFilter == 'all' || note.isFavorite).map((note) => note.id));
      }
    });
  }

  AppBar _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        leading: Checkbox(
          value: _selectedNotes.length == _notes.where((note) => _activeFilter == 'all' || note.isFavorite).length,
          onChanged: (value) => _selectAll(),
        ),
        title: Text('${_selectedNotes.length} selecionado(s)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedNotes.clear();
              });
            },
          ),
        ],
      );
    } else {
      final String appBarTitle = _activeFilter == 'favorites' ? 'Favoritos' : 'Todas as notas';
      return AppBar(
        centerTitle: true,
        title: Text(appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            onPressed: () {},
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
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Note> _visibleNotes = _activeFilter == 'favorites'
        ? _notes.where((note) => note.isFavorite).toList()
        : _notes;

    return Scaffold(
      drawerScrimColor: Colors.transparent,
      appBar: _buildAppBar(),
      drawer: Drawer(
        child: Column(
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text(""),
              accountEmail: Text(""),
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.notes_outlined),
                    title: Row(
                      children: [
                        const Text('Todas as notas'),
                        const Spacer(),
                        Text('240', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    selected: _activeFilter == 'all',
                    onTap: () {
                      _setFilter('all');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: Row(
                      children: [
                        const Text('Favoritos'),
                        const Spacer(),
                        Text('1', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    selected: _activeFilter == 'favorites',
                    onTap: () {
                      _setFilter('favorites');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: Row(
                      children: [
                        const Text('Notas bloqueadas'),
                        const Spacer(),
                        Text('1', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: Row(
                      children: [
                        const Text('Notas compartilhadas BETA'),
                        const Spacer(),
                        Text('1', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Row(
                      children: [
                        const Text('Lixeira'),
                        const Spacer(),
                        Text('0', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    onTap: () {},
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Row(
                      children: [
                        const Text('Pastas'),
                        const Spacer(),
                        Text('56', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_open_outlined),
                    title: const Text('Gerenciar pastas'),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configurações'),
              onTap: () {
                Navigator.pop(context); // Fecha o drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 0.75,
        ),
        itemCount: _visibleNotes.length,
        itemBuilder: (context, index) {
          final note = _visibleNotes[index];
          return NoteCard(
            note: note,
            onSave: _updateNote,
            isSelectionMode: _isSelectionMode,
            isSelected: _selectedNotes.contains(note.id),
            onToggleSelection: _toggleSelection,
          );
        },
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(onSave: _updateNote),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _isSelectionMode
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomActionButton(Icons.drive_file_move_outline, 'Mover', () {}),
                  _buildBottomActionButton(Icons.lock_outline, 'Bloquear', () {}),
                  _buildBottomActionButton(Icons.share_outlined, 'Compart.', () {}),
                  _buildBottomActionButton(Icons.delete_outline, 'Excluir', () {}),
                  _buildBottomActionButton(Icons.more_vert, 'Mais', () {}),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBottomActionButton(IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
