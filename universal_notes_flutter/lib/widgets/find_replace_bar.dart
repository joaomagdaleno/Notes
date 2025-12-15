import 'package:flutter/material.dart';

/// A bar for finding and replacing text.
class FindReplaceBar extends StatefulWidget {
  /// Creates a new instance of [FindReplaceBar].
  const FindReplaceBar({
    required this.onFindChanged,
    required this.onFindNext,
    required this.onFindPrevious,
    required this.onReplace,
    required this.onReplaceAll,
    required this.onClose,
    super.key,
  });

  /// Callback for when the find text changes.
  final ValueChanged<String> onFindChanged;
  /// Callback for the find next action.
  final VoidCallback onFindNext;
  /// Callback for the find previous action.
  final VoidCallback onFindPrevious;
  /// Callback for the replace action.
  final ValueChanged<String> onReplace;
  /// Callback for the replace all action.
  final ValueChanged<String> onReplaceAll;
  /// Callback to close the bar.
  final VoidCallback onClose;

  @override
  State<FindReplaceBar> createState() => _FindReplaceBarState();
}

class _FindReplaceBarState extends State<FindReplaceBar> {
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _findController.addListener(() {
      widget.onFindChanged(_findController.text);
    });
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[300],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _findController,
                  decoration: const InputDecoration(hintText: 'Find'),
                ),
              ),
              IconButton(icon: const Icon(Icons.arrow_upward), onPressed: widget.onFindPrevious),
              IconButton(icon: const Icon(Icons.arrow_downward), onPressed: widget.onFindNext),
              IconButton(icon: const Icon(Icons.close), onPressed: widget.onClose),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replaceController,
                  decoration: const InputDecoration(hintText: 'Replace with'),
                ),
              ),
              TextButton(
                onPressed: () => widget.onReplace(_replaceController.text),
                child: const Text('Replace'),
              ),
              TextButton(
                onPressed: () => widget.onReplaceAll(_replaceController.text),
                child: const Text('Replace All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
