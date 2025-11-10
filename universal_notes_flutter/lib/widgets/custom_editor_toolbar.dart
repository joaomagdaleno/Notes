import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ColorPicker;
import 'package:collection/collection.dart';

class CustomEditorToolbar extends StatelessWidget {
  final EditorState editorState;
  final bool isVisible;

  const CustomEditorToolbar({
    super.key,
    required this.editorState,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      height: 48,
      color: Colors.grey[200],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toggleIcon(context, Icons.format_bold, AppFlowyRichTextKeys.bold),
            _toggleIcon(context, Icons.format_italic, AppFlowyRichTextKeys.italic),
            _toggleIcon(context, Icons.format_underline, AppFlowyRichTextKeys.underline),
            _toggleIcon(
                context, Icons.format_strikethrough, AppFlowyRichTextKeys.strikethrough),
            const VerticalDivider(width: 1),
            _headingPopup(context),
            const VerticalDivider(width: 1),
            _listIcon(context, Icons.format_list_bulleted, 'bulleted-list'),
            _listIcon(context, Icons.format_list_numbered, 'numbered-list'),
            const VerticalDivider(width: 1),
            _linkButton(context),
            _quoteButton(context),
            _codeButton(context),
            const VerticalDivider(width: 1),
            _colorButton(context, isBackground: false),
            _colorButton(context, isBackground: true),
          ],
        ),
      ),
    );
  }

  Widget _toggleIcon(BuildContext context, IconData icon, String key) {
    return StreamBuilder<Object>(
      stream: selectionStream,
      builder: (context, snapshot) {
        final nodes = editorState.selectionService.currentSelectedNodes;
        final attrs = nodes.firstOrNull?.delta?.first.attributes ?? {};
        final isActive = attrs[key] != null;

        return IconButton(
          icon: Icon(icon,
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.black),
          onPressed: () => _transactionFormat(key),
        );
      }
    );
  }

  Widget _headingPopup(BuildContext context) {
    return PopupMenuButton<int?>(
      icon: const Icon(Icons.title),
      onSelected: _toggleHeading,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('Normal')),
        const PopupMenuItem(value: 1, child: Text('Heading 1')),
        const PopupMenuItem(value: 2, child: Text('Heading 2')),
        const PopupMenuItem(value: 3, child: Text('Heading 3')),
      ],
    );
  }

  Widget _listIcon(BuildContext context, IconData icon, String listType) {
    final selection = editorState.selection;
    if (selection == null) return IconButton(icon: Icon(icon), onPressed: null);
    final node = editorState.document.nodeAtPath(selection.start.path);
    final isActive = node?.attributes[ParagraphBlockKeys.type] == listType;

    return IconButton(
      icon: Icon(icon,
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.black),
      onPressed: () => _toggleList(listType),
    );
  }

  Widget _linkButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.link),
      onPressed: () async {
        final url = await _askUrl(context);
        if (url != null && url.isNotEmpty) {
          _insertLink(url);
        }
      },
    );
  }

  Widget _quoteButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.format_quote),
      onPressed: () => _toggleList('quote'),
    );
  }

  Widget _codeButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.code),
      onPressed: () => _transactionFormat(AppFlowyRichTextKeys.code),
    );
  }

  Widget _colorButton(BuildContext context, {required bool isBackground}) {
    return IconButton(
      icon: Icon(
          isBackground ? Icons.format_color_fill : Icons.format_color_text),
      onPressed: () => _pickColor(context, isBackground: isBackground),
    );
  }

  void _toggleHeading(int? level) {
    final selection = editorState.selection;
    if (selection == null) return;
    editorState.formatNode(
      selection,
      (node) {
        if (level == null) {
          return node.copyWith(
            type: ParagraphBlockKeys.type,
            attributes: {
              ...node.attributes..remove(HeadingBlockKeys.level)
            },
          );
        } else {
          return node.copyWith(
            type: HeadingBlockKeys.type,
            attributes: {...node.attributes, HeadingBlockKeys.level: level},
          );
        }
      },
    );
  }

  void _toggleList(String listType) {
    final selection = editorState.selection;
    if (selection == null) return;
    editorState.formatNode(
      selection,
      (node) {
        final currentType = node.attributes[ParagraphBlockKeys.type];
        if (currentType == listType) {
          return node.copyWith(
            type: ParagraphBlockKeys.type,
            attributes: {
              ...node.attributes..remove(ParagraphBlockKeys.type)
            },
          );
        } else {
          return node.copyWith(
            attributes: {
              ...node.attributes,
              ParagraphBlockKeys.type: listType
            },
          );
        }
      },
    );
  }

  void _pickColor(BuildContext context, {required bool isBackground}) async {
    Color temp = isBackground ? Colors.yellow : Colors.black;
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Escolha a cor'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, temp),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (color == null) return;
    final key =
        isBackground ? AppFlowyRichTextKeys.backgroundColor : AppFlowyRichTextKeys.textColor;
    _transactionFormat(key, '#${color.value.toRadixString(16).substring(2)}');
  }

  Future<String?> _askUrl(BuildContext context) async {
    final ctrl = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Inserir link'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'URL'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('OK')),
        ],
      ),
    );
  }

  // STUB temporário para selection
  Stream<dynamic> get selectionStream => Stream.value(editorState.selection);

  // STUBS temporários para formatação
  void _transactionFormat(dynamic format) {
    // TODO: Implementar API appflowy_editor correta
    print('Format stub: $format');
  }

  void _insertLink(String url) {
    // TODO: Implementar API appflowy_editor correta
    print('Insert link stub: $url');
  }
}
