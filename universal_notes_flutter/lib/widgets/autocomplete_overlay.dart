import 'package:flutter/material.dart';

/// A floating overlay that displays autocomplete suggestions.
class AutocompleteOverlay extends StatefulWidget {
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
  State<AutocompleteOverlay> createState() => _AutocompleteOverlayState();
}

class _AutocompleteOverlayState extends State<AutocompleteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _animation,
        child: Material(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions[index];
                return ListTile(
                  title: Text(suggestion),
                  selected: index == widget.selectedIndex,
                  onTap: () => widget.onSuggestionSelected(suggestion),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
