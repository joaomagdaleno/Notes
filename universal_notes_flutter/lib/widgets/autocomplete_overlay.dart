import 'package:flutter/material.dart';

/// A floating overlay that displays autocomplete suggestions.
class AutocompleteOverlay extends StatelessWidget {
  /// Creates a new instance of [AutocompleteOverlay].
  const AutocompleteOverlay({
    required this.suggestions,
    required this.position,
    required this.onSuggestionSelected,
    this.selectedIndex = 0,
    super.key,
  });

  /// The list of suggestion strings to display.
  final List<String> suggestions;
  /// The position on the screen where the overlay should be anchored.
  final Offset position;
  /// Callback for when a suggestion is tapped.
  final ValueChanged<String> onSuggestionSelected;
  /// The index of the currently selected suggestion.
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                title: Text(suggestion),
                selected: index == selectedIndex,
                onTap: () => onSuggestionSelected(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }
}
