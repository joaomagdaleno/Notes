import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/graph_view_screen.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/services/sync_service.dart';

/// A command action to be displayed in the palette.
class CommandAction {
  /// Creates a new [CommandAction].
  const CommandAction({
    required this.title,
    required this.icon,
    required this.onSelect,
  });

  /// The title of the command.
  final String title;

  /// The icon of the command.
  final IconData icon;

  /// The callback to execute when selected.
  final VoidCallback onSelect;
}

/// A command palette widget for quick navigation and search.
class CommandPalette extends StatefulWidget {
  /// Creates a new [CommandPalette].
  const CommandPalette({
    super.key,
    this.actions = const [],
  });

  /// The list of actions available in the palette.
  final List<CommandAction> actions;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _results = [];
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
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluentPalette(context);
    } else {
      return _buildMaterialPalette(context);
    }
  }

  Widget _buildFluentPalette(BuildContext context) {
    final theme = fluent.FluentTheme.of(context);

    return Container(
      width: 600,
      height: 480,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.resources.dividerStrokeColorDefault),
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
            child: fluent.TextBox(
              controller: _searchController,
              autofocus: true,
              placeholder: 'Search notes or type ">" for commands...',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(fluent.FluentIcons.search, size: 14),
              ),
              onChanged: _onSearch,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: fluent.ProgressRing())
                : ListView(
                    children: [
                      if (_searchController.text.startsWith('>')) ...[
                        _buildFluentCommandItem(
                          context,
                          'Open Graph View',
                          fluent.FluentIcons.chart,
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
                        ...widget.actions
                            .where(
                              (action) => action.title.toLowerCase().contains(
                                    _searchController.text
                                        .substring(1)
                                        .trim()
                                        .toLowerCase(),
                                  ),
                            )
                            .map(
                              (action) => _buildFluentCommandItem(
                                context,
                                action.title,
                                action.icon,
                                () {
                                  Navigator.of(context).pop();
                                  action.onSelect();
                                },
                              ),
                            ),
                      ] else ...[
                        ..._results.map(
                          (result) {
                            final snippet = result.content.length > 50
                                ? result.content.substring(0, 50)
                                : result.content;
                            return fluent.ListTile.selectable(
                              title: Text(result.title),
                              subtitle: Text(
                                snippet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                unawaited(
                                  Navigator.of(context).push(
                                    fluent.FluentPageRoute<void>(
                                      builder: (context) => NoteEditorScreen(
                                        note: result,
                                        onSave: (updatedNote) async {
                                          await NoteRepository.instance
                                              .updateNote(updatedNote);
                                          await SyncService.instance
                                              .refreshLocalData();
                                          return updatedNote;
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFluentCommandItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return fluent.ListTile.selectable(
      leading: Icon(icon),
      title: Text(title),
      onPressed: onTap,
    );
  }

  Widget _buildMaterialPalette(BuildContext context) {
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
                        _buildMaterialCommandItem(
                          context,
                          'Open Graph View',
                          Icons.auto_graph,
                          () {
                            Navigator.of(context).pop();
                            unawaited(
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const GraphView(),
                                ),
                              ),
                            );
                          },
                        ),
                        ...widget.actions
                            .where(
                              (action) => action.title.toLowerCase().contains(
                                    _searchController.text
                                        .substring(1)
                                        .trim()
                                        .toLowerCase(),
                                  ),
                            )
                            .map(
                              (action) => _buildMaterialCommandItem(
                                context,
                                action.title,
                                action.icon,
                                () {
                                  Navigator.of(context).pop();
                                  action.onSelect();
                                },
                              ),
                            ),
                      ] else ...[
                        ..._results.map(
                          (result) {
                            final snippet = result.content.length > 50
                                ? result.content.substring(0, 50)
                                : result.content;
                            return ListTile(
                              title: Text(result.title),
                              subtitle: Text(
                                snippet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                unawaited(
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) => NoteEditorScreen(
                                        note: result,
                                        onSave: (updatedNote) async {
                                          await NoteRepository.instance
                                              .updateNote(updatedNote);
                                          await SyncService.instance
                                              .refreshLocalData();
                                          return updatedNote;
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCommandItem(
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
Future<void> showCommandPalette(
  BuildContext context, {
  List<CommandAction> actions = const [],
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => Center(
      child: Material(
        color: Colors.transparent,
        child: CommandPalette(actions: actions),
      ),
    ),
  );
}
