import 'package:flutter/material.dart';

/// A widget that displays avatars for active collaborators in a row.
class CollaboratorAvatars extends StatelessWidget {
  /// Creates a [CollaboratorAvatars].
  const CollaboratorAvatars({
    required this.remoteCursors,
    super.key,
  });

  /// A map of remote cursors containing collaborator information (name, color).
  final Map<String, Map<String, dynamic>> remoteCursors;

  @override
  Widget build(BuildContext context) {
    final collaborators = remoteCursors.values.toList();
    return Row(
      children: [
        for (int i = 0; i < collaborators.length; i++)
          Align(
            widthFactor: 0.7,
            child: CircleAvatar(
              backgroundColor: Color(collaborators[i]['color'] as int),
              child: Text(
                (collaborators[i]['name'] as String).substring(0, 2),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
