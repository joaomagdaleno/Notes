import 'package:flutter/material.dart';

/// A floating search bar for reading mode.
class ReadingSearchBar extends StatefulWidget {
  /// Creates a new [ReadingSearchBar].
  const ReadingSearchBar({
    required this.onFindChanged,
    required this.onFindNext,
    required this.onFindPrevious,
    required this.onClose,
    required this.resultsCount,
    required this.currentIndex,
    super.key,
  });

  /// Called when the search query changes.
  final ValueChanged<String> onFindChanged;

  /// Called to find the next match.
  final VoidCallback onFindNext;

  /// Called to find the previous match.
  final VoidCallback onFindPrevious;

  /// Called to close the search bar.
  final VoidCallback onClose;

  /// Total number of search results.
  final int resultsCount;

  /// Current result index (0-indexed).
  final int currentIndex;

  @override
  State<ReadingSearchBar> createState() => _ReadingSearchBarState();
}

class _ReadingSearchBarState extends State<ReadingSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in note...',
                  border: InputBorder.none,
                ),
                onChanged: widget.onFindChanged,
              ),
            ),
            if (widget.resultsCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${widget.currentIndex + 1} of ${widget.resultsCount}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              onPressed: widget.resultsCount > 0 ? widget.onFindPrevious : null,
              tooltip: 'Previous result',
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              onPressed: widget.resultsCount > 0 ? widget.onFindNext : null,
              tooltip: 'Next result',
            ),
            const VerticalDivider(width: 1, indent: 10, endIndent: 10),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onClose,
              tooltip: 'Close search',
            ),
          ],
        ),
      ),
    );
  }
}
