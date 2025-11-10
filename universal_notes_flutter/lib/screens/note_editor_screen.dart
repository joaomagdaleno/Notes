import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:appflowy_editor/appflowy_editor.dart' hide ColorPicker;
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io' show Platform;
import '../models/note.dart';
import '../models/paper_config.dart';
import '../utils/drawing_deserializer.dart';
import '../utils/pdf_exporter.dart';
import '../widgets/custom_editor_toolbar.dart';
import '../widgets/paper_canvas.dart';

enum CanvasMode { paper, infinite }

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final Future<Note> Function(Note) onSave;

  const NoteEditorScreen({super.key, this.note, required this.onSave});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late EditorState _editorState;
  late DrawingController _drawController;
  Timer? _debounce;
  Note? _currentNote;

  late CanvasMode _canvasMode;
  late PaperFormat _paperFormat;
  late PaperMargin _paperMargin;

  final ValueNotifier<bool> _isToolbarVisible = ValueNotifier<bool>(true);

  late Color _drawingColor;
  late double _drawingStrokeWidth;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote?.title ?? '');

    final prefs =
        _currentNote?.prefsJson != null ? jsonDecode(_currentNote!.prefsJson!) : {};
    _canvasMode = CanvasMode.values.firstWhere(
      (e) => e.name == prefs['mode'],
      orElse: () => CanvasMode.paper,
    );
    _paperFormat = PaperFormat.values.firstWhere(
      (e) => e.name == prefs['format'],
      orElse: () => PaperFormat.a4,
    );
    _paperMargin = PaperMargin.values.firstWhere(
      (e) => e.name == prefs['margin'],
      orElse: () => PaperMargin.normal,
    );

    _drawingColor = Colors.black;
    _drawingStrokeWidth = 2.0;

    _initEditor();
    _initDrawing();

    _debounce = Timer.periodic(const Duration(seconds: 5), (_) => _saveNote());
  }

  void _initEditor() {
    final content = _currentNote?.content;
    if (content != null && content.isNotEmpty) {
      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        final doc = Document.fromJson(json);
        _editorState = EditorState(document: doc);
        return;
      } catch (e) {
        debugPrint('Erro ao carregar documento: $e');
      }
    }
    _editorState = EditorState.blank(withInitialText: true);
  }

  void _initDrawing() {
    _drawController = DrawingController();
    if (_currentNote?.drawingJson != null && _currentNote!.drawingJson!.isNotEmpty) {
      try {
        final list = (jsonDecode(_currentNote!.drawingJson!) as List)
            .cast<Map<String, dynamic>>()
            .map(paintContentFromJson)
            .whereType<PaintContent>()
            .toList();
        _drawController.addContents(list);
      } catch (e) {
        debugPrint('Erro ao carregar desenho: $e');
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveNote();
    _titleController.dispose();
    _editorState.dispose();
    _drawController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final title = _titleController.text;
    final contentJson = jsonEncode(_editorState.document.toJson());

    final strokesJson = jsonEncode(_drawController.getJsonList());

    final prefs = {
      'mode': _canvasMode.name,
      'format': _paperFormat.name,
      'margin': _paperMargin.name,
    };

    final note = Note(
      id: _currentNote?.id,
      title: title,
      content: contentJson,
      drawingJson: strokesJson,
      prefsJson: jsonEncode(prefs),
      date: _currentNote?.date ?? DateTime.now(),
    );

    final saved = await widget.onSave(note);
    if (mounted) setState(() => _currentNote = saved);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) return _buildFluentUI(context);
    return _buildMaterialUI(context);
  }

  Widget _buildFluentUI(BuildContext context) {
    final isDesktop = true;
    return fluent.ScaffoldPage(
      header: fluent.CommandBar(
        primaryItems: [
          fluent.CommandBarButton(
            icon: const fluent.Icon(fluent.FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
          fluent.CommandBarButton(
            icon: const fluent.Icon(fluent.FluentIcons.page),
            onPressed: _showPaperDialog,
            tooltip: 'Formato do papel',
          ),
          fluent.CommandBarButton(
            icon: fluent.Icon(_isToolbarVisible.value ? fluent.FluentIcons.edit : fluent.FluentIcons.edit),
            onPressed: () => setState(() => _isToolbarVisible.value = !_isToolbarVisible.value),
            tooltip: _isToolbarVisible.value ? 'Modo Desenho' : 'Modo Texto',
          ),
        ],
      ),
      content: Column(children: [
        _buildTitleBar(context),
        if (isDesktop) _topBar(),
        Expanded(child: _body()),
      ]),
    );
  }

  Widget _buildMaterialUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nova Nota' : 'Editar Nota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.article),
            tooltip: 'Formato do papel',
            onPressed: _showPaperDialog,
          ),
        ],
      ),
      body: Column(children: [
        _buildTitleBar(context),
        Expanded(child: _body()),
      ]),
      bottomNavigationBar: _buildMobileToolbar(),
    );
  }

  Widget _buildMobileToolbar() {
    return ValueListenableBuilder<bool>(
        valueListenable: _isToolbarVisible,
        builder: (context, isTextMode, _) {
          return BottomAppBar(
            child: Row(
              children: [
                Expanded(
                  child: isTextMode
                      ? CustomEditorToolbar(editorState: _editorState)
                      : _miniDrawToolbar(),
                ),
                IconButton(
                  icon: Icon(isTextMode ? Icons.draw_outlined : Icons.notes_outlined),
                  tooltip: isTextMode ? 'Modo Desenho' : 'Modo Texto',
                  onPressed: () => _isToolbarVisible.value = !isTextMode,
                ),
              ],
            ),
          );
        });
  }

  Widget _buildTitleBar(BuildContext context) {
    final isDesktop = Platform.isWindows;

    final titleWidget = isDesktop
        ? fluent.TextBox(
            controller: _titleController,
            placeholder: 'Título da Nota',
            decoration: fluent.WidgetStateProperty.all(
              const fluent.BoxDecoration(
                border: null,
              ),
            ),
            style: fluent.FluentTheme.of(context).typography.title,
          )
        : TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Título da Nota',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: titleWidget),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(isDesktop ? fluent.FluentIcons.view : Icons.visibility_off_outlined),
            tooltip: 'Modo Leitura (somente visualização)',
            onPressed: null, // Placeholder
          ),
          IconButton(
            icon: Icon(isDesktop ? fluent.FluentIcons.add : Icons.add_circle_outline),
            tooltip: 'Adicionar anexo',
            onPressed: null, // Placeholder
          ),
          _buildSaveAsMenu(context),
        ],
      ),
    );
  }

  Widget _buildSaveAsMenu(BuildContext context) {
    final isDesktop = Platform.isWindows;

    final onSelected = (String value) {
      if (value == 'pdf') {
        if (_currentNote != null) {
          exportNoteToPdf(_currentNote!, share: true);
        }
      }
    };

    if (isDesktop) {
      return fluent.DropDownButton(
        title: const Text('Salvar Como'),
        items: [
          fluent.MenuFlyoutItem(text: const Text('PDF'), onPressed: () => onSelected('pdf')),
          const fluent.MenuFlyoutSeparator(),
          fluent.MenuFlyoutItem(text: const Text('Word (em breve)'), onPressed: null),
          fluent.MenuFlyoutItem(text: const Text('Imagem (em breve)'), onPressed: null),
        ],
      );
    } else {
      return PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(value: 'pdf', child: Text('Salvar como PDF')),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(value: 'word', enabled: false, child: Text('Word (em breve)')),
          const PopupMenuItem<String>(value: 'image', enabled: false, child: Text('Imagem (em breve)')),
        ],
        icon: const Icon(Icons.more_vert),
      );
    }
  }

  Widget _topBar() {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    if (!isDesktop) return const SizedBox.shrink(); // Only for desktop

    return ValueListenableBuilder<bool>(
      valueListenable: _isToolbarVisible,
      builder: (_, isTextMode, __) {
        if (isTextMode) {
          return CustomEditorToolbar(editorState: _editorState);
        } else {
          return _miniDrawToolbar();
        }
      },
    );
  }

  Widget _body() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isToolbarVisible,
      builder: (_, visible, __) {
        if (visible) return _textPane();
        return _drawPane();
      },
    );
  }

  Widget _textPane() {
    final editor = AppFlowyEditor(
      editorState: _editorState,
      shrinkWrap: _canvasMode == CanvasMode.paper,
      characterShortcutEvents: standardCharacterShortcutEvents,
      commandShortcutEvents: standardCommandShortcutEvents,
    );
    if (_canvasMode == CanvasMode.infinite) return editor;
    return PaperCanvas(
      paperSize: _paperFormat.size,
      margins: _paperMargin.value,
      child: editor,
    );
  }

  Widget _drawPane() {
    final canvas = Column(children: [
      _miniDrawToolbar(),
      Expanded(
        child: DrawingBoard(
          controller: _drawController,
          background: Container(color: Colors.transparent),
          showDefaultActions: false,
          showDefaultTools: false,
        ),
      ),
    ]);
    if (_canvasMode == CanvasMode.infinite) return canvas;
    return PaperCanvas(
      paperSize: _paperFormat.size,
      margins: EdgeInsets.zero, // permite desenhar na margem
      child: canvas,
    );
  }

  Widget _miniDrawToolbar() {
    return Container(
      height: 56,
      color: Colors.grey.shade200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          IconButton(
            icon: const Icon(Icons.brush),
            tooltip: 'Pincel',
            onPressed: () {
              _drawController.setPaintContent(SimpleLine());
              _drawController.setStyle(color: Colors.black, strokeWidth: 2.0);
            },
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            tooltip: 'Mudar cor',
            onPressed: () async {
              Color newColor = _drawingColor;
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Selecione a cor'),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: _drawingColor,
                      onColorChanged: (v) => newColor = v,
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          setState(() {
                            _drawingColor = newColor;
                            _drawController.setStyle(color: newColor);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('OK'))
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: 'Borracha',
            onPressed: () => _drawController.setPaintContent(Eraser()),
          ),
          const VerticalDivider(width: 1),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Concluir desenho',
            onPressed: () {
              final strokes = _drawController.getJsonList();
              _currentNote =
                  _currentNote!.copyWith(drawingJson: jsonEncode(strokes));
              _isToolbarVisible.value = true;
            },
          ),
        ],
      ),
    );
  }

  void _showPaperDialog() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Configurações do papel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Modo'),
              trailing: DropdownButton<CanvasMode>(
                value: _canvasMode,
                items: CanvasMode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (v) => setState(() => _canvasMode = v!),
              ),
            ),
            ListTile(
              title: const Text('Formato'),
              trailing: DropdownButton<PaperFormat>(
                value: _paperFormat,
                items: PaperFormat.values.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                onChanged: (v) => setState(() => _paperFormat = v!),
              ),
            ),
            ListTile(
              title: const Text('Margem'),
              trailing: DropdownButton<PaperMargin>(
                value: _paperMargin,
                items: PaperMargin.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (v) => setState(() => _paperMargin = v!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('OK'))
        ],
      ),
    );
  }
}
