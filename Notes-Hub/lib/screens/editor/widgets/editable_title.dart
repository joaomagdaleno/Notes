import 'package:flutter/material.dart';

/// A widget that allows editing a title in-place.
class EditableTitle extends StatefulWidget {
  /// Creates an [EditableTitle].
  const EditableTitle({
    required this.initialTitle,
    required this.onChanged,
    super.key,
  });

  /// The initial title to display.
  final String initialTitle;

  /// Callback when the title is changed and submitted.
  final ValueChanged<String> onChanged;

  @override
  State<EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends State<EditableTitle> {
  late TextEditingController _controller;
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditableTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTitle != oldWidget.initialTitle && !_isEditing) {
      _controller.text = widget.initialTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: 'Edit Note',
        ),
        onSubmitted: (value) {
          setState(() => _isEditing = false);
          widget.onChanged(value);
        },
        onTapOutside: (_) {
          setState(() => _isEditing = false);
          widget.onChanged(_controller.text);
        },
      );
    }
    return GestureDetector(
      onTap: () => setState(() {
        _isEditing = true;
        _focusNode.requestFocus();
      }),
      child: Text(
        _controller.text.isEmpty ? 'Edit Note' : _controller.text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _controller.text.isEmpty ? Colors.grey : null,
        ),
      ),
    );
  }
}
