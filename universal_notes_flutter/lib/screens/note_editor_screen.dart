import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:io' show Platform;
import '../models/note.dart';
import '../widgets/custom_editor_toolbar.dart';

enum CanvasMode { paper, infinite }
enum PaperFormat { a4, a3, a5, letter, legal, oficio }
enum PaperMargin { normal, narrow, none }

extension PaperFormatSize on PaperFormat {
  Size get size {
    switch (this) {
      case PaperFormat.a4:
        return const Size(794, 1123);
      case PaperFormat.a3:
        return const Size(1123, 1587);
      case PaperFormat.a5:
        return const Size(559, 794);
      case PaperFormat.letter:
        return const Size(816, 1056);
      case PaperFormat.legal:
        return const Size(816, 1344);
      case PaperFormat.oficio:
        return const Size(816, 1240);
    }
  }
}

extension PaperMarginValue on PaperMargin {
  EdgeInsets get value {
    switch (this) {
      case PaperMargin.normal:
        return const EdgeInsets.fromLTRB(72, 72, 72, 96);
      case PaperMargin.narrow:
        return const EdgeInsets.all(36);
      case PaperMargin.none:
        return EdgeInsets.zero;
    }
  }
}

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

  // Estado de papel / infinito
  late CanvasMode _canvasMode;
  late PaperFormat _paperFormat;
  late PaperMargin _paperMargin;

  // Toolbar visível? (text-mode)  true=texto  false=desenho
  final ValueNotifier<bool> _isToolbarVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote?.title ?? '');

    // lê preferências salvas na nota (ou default)
    _canvasMode = _readPrefs('mode', CanvasMode.paper);
    _paperFormat = _readPrefs('format', PaperFormat.a4);
    _paperMargin = _readPrefs('margin', PaperMargin.normal);

    _initEditor();
    _initDrawing();

    // auto-save a cada 5 s
    _debounce = Timer.periodic(const Duration(seconds: 5), (_) => _saveNote());
  }

  T _readPrefs<T>(String key, T defaultValue) {
    final raw = _currentNote?.prefsJson;
    if (raw == null) return defaultValue;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      switch (T) {
        case CanvasMode:
          return CanvasMode.values.firstWhere((e) => e.name == map[key],
              orElse: () => defaultValue as T);
        case PaperFormat:
          return PaperFormat.values.firstWhere((e) => e.name == map[key],
              orElse: () => defaultValue as T);
        case PaperMargin:
          return PaperMargin.values.firstWhere((e) => e.name == map[key],
              orElse: () => defaultValue as T);
        default:
          return defaultValue;
      }
    } catch (_) {
      return defaultValue;
    }
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
    if (_currentNote?.drawingJson != null) {
      try {
        final list = (jsonDecode(_currentNote!.drawingJson!) as List)
            .map((e) => DrawingContent.fromJson(e))
            .toList();
        _drawController.addContents(list);
      } catch (_) {}
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

    // serializa strokes
    final strokesJson = jsonEncode(_drawController.getJsonList());

    // prefs do papel
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

  /* ----------  BUILD  ---------- */

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) return _buildFluentUI(context);
    return _buildMaterialUI(context);
  }

  /* ----------  FLUENT (Windows)  ---------- */
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
        ],
      ),
      content: Column(children: [
        if (isDesktop) _topBar(),
        Expanded(child: _body()),
      ]),
    );
  }

  /* ----------  MATERIAL (Android/iOS)  ---------- */
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
        if (Platform.isAndroid || Platform.isIOS) _topBar(),
        Expanded(child: _body()),
      ]),
      floatingActionButton: FloatingActionButton(
        tooltip: _isToolbarVisible.value ? 'Modo desenho' : 'Modo texto',
        child: Icon(_isToolbarVisible.value ? Icons.edit : Icons.edit_off),
        onPressed: () => _isToolbarVisible.value = !_isToolbarVisible.value,
      ),
    );
  }

  /* ----------  TOP / BOTTOM BAR  ---------- */
  Widget _topBar() {
    final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    return ValueListenableBuilder<bool>(
      valueListenable: _isToolbarVisible,
      builder: (_, visible, __) {
        if (!visible) return const SizedBox.shrink(); // escondido no desenho
        return isDesktop
            ? CustomEditorToolbar(editorState: _editorState)
            : Container(); // mobile usa bottom
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
    Color currentColor = Colors.black;
    double currentWidth = 3;
    return Container(
      height: 56,
      color: Colors.grey[200],
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          IconButton(
            icon: const Icon(Icons.brush),
            onPressed: () => _drawController.setPaint(Paint()
              ..color = currentColor
              ..strokeWidth = currentWidth
              ..style = PaintingStyle.stroke),
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: () async {
              Color? c = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  content: SingleChildScrollView(
                    child: ColorPicker(pickerColor: currentColor, onColorChanged: (v) => currentColor = v),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(_, currentColor), child: const Text('OK'))
                  ],
                ),
              );
              if (c != null) currentColor = c;
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => _drawController.setPaint(Paint()
              ..color = Colors.white
              ..strokeWidth = 20
              ..style = PaintingStyle.stroke
              ..blendMode = BlendMode.clear),
          ),
          const VerticalDivider(width: 1),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Concluir desenho',
            onPressed: () {
              final strokes = _drawController.getJsonList();
              _currentNote = _currentNote!.copyWith(drawingJson: jsonEncode(strokes));
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
