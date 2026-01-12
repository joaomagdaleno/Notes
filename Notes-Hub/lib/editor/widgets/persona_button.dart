import 'package:flutter/material.dart';
import 'package:notes_hub/models/persona_model.dart';

/// A button widget for switching between editor personas.
class PersonaButton extends StatelessWidget {
  /// Creates a new [PersonaButton].
  const PersonaButton({
    required this.persona,
    required this.activePersona,
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  /// The persona represented by this button.
  final EditorPersona persona;

  /// The currently active persona in the editor.
  final EditorPersona activePersona;

  /// The icon to display.
  final IconData icon;

  /// The label to display.
  final String label;

  /// Callback when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = persona == activePersona;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
