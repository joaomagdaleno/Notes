import 'package:flutter/material.dart';

class CollaboratorAvatars extends StatelessWidget {
  const CollaboratorAvatars({
    required this.remoteCursors,
    super.key,
  });

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
