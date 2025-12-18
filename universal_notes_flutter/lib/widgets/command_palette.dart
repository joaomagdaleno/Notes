import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/graph_view_screen.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';

/// A command palette widget for quick navigation and search.
class CommandPalette extends StatefulWidget {
  /// Creates a new [CommandPalette].
  const CommandPalette({super.key});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _results = [];
  bool _isLoading = false;

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    final results = await NoteRepository.instance.searchNotes(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 480,
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search notes or type ">" for commands...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
              onChanged: _onSearch,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      if (_searchController.text.startsWith('>')) ...[
                        _buildCommandItem(
                          context,
                          'Open Graph View',
                          Icons.auto_graph,
                          () {
                            Navigator.of(context).pop();
                            unawaited(
                              Navigator.of(context).push(
                                fluent.FluentPageRoute<void>(
                                  builder: (context) => const GraphView(),
                                ),
                              ),
                            );
                          },
                        ),
                        // Add more commands here
                      ] else ...[
                        ..._results.map(
                          (result) => ListTile(
                            title: Text(result.note.title),
                            subtitle: Text(
                              result.snippet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              unawaited(
                                Navigator.of(context).push(
                                  fluent.FluentPageRoute<void>(
                                    builder: (context) => NoteEditorScreen(
                                      note: result.note,
                                      onSave: (updatedNote) async {
                                        await NoteRepository.instance
                                            .updateNote(
                                              updatedNote,
                                            );
                                        await SyncService.instance
                                            .refreshLocalData();
                                        return updatedNote;
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}

/// Shows the command palette dialog.
Future<void> showCommandPalette(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) => const Center(
      child: Material(
        color: Colors.transparent,
        child: CommandPalette(),
      ),
    ),
  );
}
