import 'package:flutter/material.dart';

/// A widget that displays a remote cursor with a user's name.
class RemoteCursor extends StatelessWidget {
  /// Creates a remote cursor.
  const RemoteCursor({
    required this.color,
    required this.name,
    super.key,
  });

  /// The color of the cursor.
  final Color color;

  /// The name of the user associated with the cursor.
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2,
          height: 18, // Adjust height to match font size
          color: color,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
